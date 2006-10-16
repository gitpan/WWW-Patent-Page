
package WWW::Patent::Page::MICROPATENT;
use strict;
use warnings;
use diagnostics;
use Carp;
use subs
	qw( methods MICROPATENT_login MICROPATENT_country_known MICROPATENT_pdf  MICROPATENT_html  MICROPATENT_xml    MICROPATENT_terms  ); # MICROPATENT_xml_tree
use LWP::UserAgent 2.003;
require HTTP::Request;
use HTTP::Request::Common;
use URI;
use HTML::Form;
use URI;

#use PDF::API2 2.000;
use WWW::Patent::Page::Response;
our ( $VERSION, @ISA, %_country_known );
$VERSION = "0.01";

sub methods {
	return (
		'MICROPATENT_login'         => \&MICROPATENT_login,
		'MICROPATENT_pdf'           => \&MICROPATENT_pdf,
		'MICROPATENT_html'          => \&MICROPATENT_html,
		'MICROPATENT_xml'           => \&MICROPATENT_xml,
#		'MICROPATENT_xml_tree'      => \&MICROPATENT_xml_tree,
		'MICROPATENT_country_known' => \&MICROPATENT_country_known,

		#		'MICROPATENT_parse_doc_id'        => \&MICROPATENT_parse_doc_id,
		'MICROPATENT_terms' => \&MICROPATENT_terms,
	);
}

sub MICROPATENT_login {
	my $self = shift;
	my ($username) = shift
		|| $self->{patent}->{office_username}
		|| warn 'no MicroPatent username';
	my ($password) = shift
		|| $self->{patent}->{office_password}
		|| warn 'no MicroPatent password';

	#	print " HI! username = $username \n";
	our ( $url, $request, $http_response );
	$url = HTTP::Request->new(
		POST => "http://www.micropat.com/cgi-bin/login" );
	$url->content(
		"password=$password&patservices=PatentWeb%20Services&loginname=$username&"
	);
	$http_response = $self->request($url);
	unless ( $http_response->is_success ) {
		carp
			"Login Post Request 'http://www.micropat.com/cgi-bin/login' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($self);
	}
	my $last_request = $http_response->base;

	#	print $last_request ;
	if ( $last_request =~ m/(\d\d\d\d\d\d\d\d\d\d+)/ ) {
		$self->{'patent'}{'session_token'} = $1;
	} else {
		carp
			"Login response '$last_request' from Request 'http://www.micropat.com/cgi-bin/login' has no session id  with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($self);
	}
}

sub MICROPATENT_country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if ( exists $_country_known{$country_in_question} ) {
		return ( $_country_known{$country_in_question} );
	} else {
		return (undef);
	}
}

sub MICROPATENT_xml {
	my ($self) = @_;
	my ($url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$match
	);
	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = undef;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = undef;
		return ($self);
	}
#	print "\n3.1\n";
	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = undef;
		return ($self);
	}
#	print "\n3.2\n";
	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = undef;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	} else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[
		'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'textonly.x'    => "60",
		'textonly.y'    => "9",
		];
#		print "\n2\n";
	$http_response = $self->request($request);
# print "\n3\n";
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		print $http_response->content;
		return (undef);
	}
# print "\n3.4\n";	
	# find new parameters, match and screenseq
	$html = $http_response->content;  
# print "\n$html\n";
	if ($html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	} else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
# print "\n3.5\n";
	if ($html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	} else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
# print "\n4\n";
	
	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[
		'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "$id",
		'bundle_format'     => "as_ordered",
		'screenseq'         => "$screenseq",
		'del_CAPS_standard' => "DOWNLOADXML",
		'match-1-0'         => "$match",
		];
	$http_response = $self->request($request);
# print "\n5\n";
	
	unless ( $http_response->is_success ) {
		carp "Request 'POST http://www.micropat.com/perl/sunduk/order-submit.pl' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}
		
#	print $http_response->content;

$html = $http_response->content;	
	if ($html =~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.xml)  }xms
		)
	{
		$url = $1;
	} else {
		$self->{'message'}
			= "no url to xml found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
	$request = GET "$url" ;
	$http_response = $self->request($request);	
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}	
	return ($http_response);	
 }
sub MICROPATENT_pdf {
	my ($self) = @_;
	my ($url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$match
	);
	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = undef;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = undef;
		return ($self);
	}
#	print "\n3.1\n";
	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = undef;
		return ($self);
	}
#	print "\n3.2\n";
	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = undef;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	} else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[
		'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'images.x'    => "60",
		'images.y'    => "9",
		];
#		print "\n2\n";
	$http_response = $self->request($request);
# print "\n3\n";
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		print $http_response->content;
		return (undef);
	}
# print "\n3.4\n";	
	# find new parameters, match and screenseq
	$html = $http_response->content;  
# print "\n$html\n";
	if ($html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	} else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
# print "\n3.5\n";
	if ($html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	} else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
# print "\n4\n";
	
	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[
		'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "id",
		'bundle_format'     => "normalized",
		'screenseq'         => "$screenseq",
		'del_CAPS_standard' => "DOWNLOADCONCATPDF",
		'match-1-0'         => "$match",
		];
	$http_response = $self->request($request);
print "\n5\n";
	
	unless ( $http_response->is_success ) {
		carp "Request 'POST http://www.micropat.com/perl/sunduk/order-submit.pl' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}
		
#	print $http_response->content;

$html = $http_response->content;	
print "\n5- here it is:\n$html\n";
	if ($html =~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.pdf)  }xms
		)
	{
		$url = $1;
	} else {
		$self->{'message'}
			= "no url to PDF found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
	$request = GET "$url" ;
	$http_response = $self->request($request);	
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}	
	return ($http_response);	
 }
sub MICROPATENT_html {
	my ($self) = @_;
	my ($url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last,          $screenseq,
		$match
	);
	# sanity checks
	$self->{'message'} = '';
	if ( !$self->{'patent'}{'country'} ) {
		$self->{'message'}
			= "country not specified (or doc_id has unrecognized country)";
		$self->{'is_success'} = undef;
		return ($self);
	}
	if ( !&MICROPATENT_country_known( $self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$self->{'message'}
			= "country '" . $self->{'patent'}{'country'} . "' unrecognized";
		$self->{'is_success'} = undef;
		return ($self);
	}
#	print "\n3.1\n";
	if ( !$self->{'patent'}{'session_token'} ) {
		$self->{'message'}    = "login token not available";
		$self->{'is_success'} = undef;
		return ($self);
	}
	# print "\n3.2\n";
	if ( !$self->{'patent'}{'number'} ) {
		$self->{'message'}    = "number '$self->{'patent'}{'number'}' bad";
		$self->{'is_success'} = undef;
		return ($self);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;
	my $id;
	if ( defined $self->{'patent'}{'kind'} ) {
		$id = $short_id . $self->{'patent'}{'kind'};
	} else {
		$id = $short_id;
	}
	$request = POST "http://www.micropat.com/perl/sunduk/avail-check.pl",
		[
		'ticket'        => "$self->{'patent'}{'session_token'}",
		'familylist'    => "",
		'patnumtaglist' => "$id",
		'textonly.x'    => "60",
		'textonly.y'    => "9",
		];
		# print "\n2\n";
	$http_response = $self->request($request);
# print "\n3\n";
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		# print $http_response->content;
		return (undef);
	}
 # print "\n3.4\n";	
	# find new parameters, match and screenseq
	$html = $http_response->content;  
 # print "\n$html\n";
	if ($html =~ m{  value \s* = \s* "	(\d\d\d\d\d\d\d+\-0) "   #   			
		}xms
		)
	{
		$match = $1;
	} else {
		$self->{'message'}
			= "no match found e.g. match-1-0 value 12345678-0 , do not know how to continue \n$html\n no match found e.g. match-1-0 value 12345678-0 , do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
 # print "\n3.5\n";
	if ($html =~ m{ name \s* = \s* "screenseq" \s* # 
					   value \s* = \s* "(\d+)"   #   			
		}xms
		)
	{
		$screenseq = $1;
	} else {
		$self->{'message'}
			= "no screenseq found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($self);
	}
 # print "\n4\n";
	
	$request = POST "http://www.micropat.com/perl/sunduk/order-submit.pl",
		[
		'ticket'            => "$self->{'patent'}{'session_token'}",
		'userref'           => "$id",
		'bundle_format'     => "normalized",
		'screenseq'         => "$screenseq",
		'del_CAPS_standard' => "DOWNLOADHTML",
		'match-1-0'         => "$match",
		];
	$http_response = $self->request($request);
 # print "\n5\n";
	
	unless ( $http_response->is_success ) {
		carp "Request 'POST http://www.micropat.com/perl/sunduk/order-submit.pl' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}
		
#	print $http_response->content;

$html = $http_response->content;	

 # print "\n$html\n";

	if ($html =~ m{ (http://www.micropat.com:80/get-file/\d+/[^\.]+\.html)  }xms
		)
	{
		$url = $1;
	} else {
		$self->{'message'}
			= "no url to html found, do not know how to continue \n$html\nno screenseq found, do not know how to continue";
		$self->{'is_success'} = undef;
		return ($http_response);
	}
	$request = GET "$url" ;
	$http_response = $self->request($request);	
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line "
			. $http_response->status_line
			. ".  Bummer.\n";
		return ($http_response);
	}	
	return ($http_response);	
 }

sub MICROPATENT_terms {
	my ($self) = @_;
	return (
		"Pay to play. Consult your contract.  Your mileage may vary. "
	);
}
%_country_known = (    # 20060922
	'OA' => 'from 1966',   # African Intellectual Property Organisation (OAPI)
	'AP' => 'from 1985'
	,    # African Regional Industrial Property Organisation (ARIPO)
	'AT' => 'from 1920',                                # Austria
	'BE' => 'from 1920',                                # Belgium
	'CA' => 'from 2000',                                # Canada--grants
	'CA' => 'from July 1999',                           # Canada--applications
	'CA' => 'from Uniques (no other family filing)',    # Canada--other
	'DK' => 'from 1920',                                # Denmark
	'EP' => 'from 19800109 to 20060913',    # European Patent Office--grants
	'EP' =>
		'from 19781220 to 20060913',    # European Patent Office--applications
	'FR' => 'from 1920',                    # France
	'DD' => 'from YES',                     # German Democratic Republic
	'DE' => 'from 1920 to 20060914',        # Germany
	'GB' => 'from 19160608 to 20060913',    # Great Britain
	'IE' => 'from 1996',                    # Ireland
	'IT' => 'from 1978',                    # Italy
	'JP' => 'from 19800109 to 20060906',    # Japan--B
	'JP' => 'from 19830527 to 20060824',    # Japan--A
	'JP' => 'from 1980 (partial coverage)', # Japan--other
	'LU' => 'from 1945',                    # Luxembourg
	'MC' => 'from 1957',                    # Monaco
	'NL' => 'from 1913',                    # The Netherlands
	'PT' => 'from 1980',                    # Portugal
	'ES' => 'from 1969',                    # Spain
	'SE' => 'from 1918',                    # Sweden
	'CH' => 'from 1920',                    # Switzerland
	'US' => 'from 1790',                    # United States of America--grants
	'USB' => 'from 19640114  ',    # United States of America--grants
	'USA' => 'from 20010315 ',     # United States of America--applications
	'WO'  => 'from 19781019 ',     # WIPO
	'AR'  => 'limited',            # Argentina
	'AU'  => 'limited',            # Australia
	'BR'  => 'limited',            # Brazil
	'BG'  => 'limited',            # Bulgaria
	'CN'  => 'limited',            # China
	'CZ'  => 'limited',            # Czech Republic
	'CS'  => 'limited',            # Czechoslovakia
	'FI'  => 'limited',            # Finland
	'GR'  => 'limited',            # Greece
	'HU'  => 'limited',            # Hungary
	'LV'  => 'limited',            # Latvia
	'LT'  => 'limited',            # Lithuania
	'MX'  => 'limited',            # Mexico
	'MN'  => 'limited',            # Mongolia
	'NO'  => 'limited',            # Norway
	'PH'  => 'limited',            # Philippines
	'PL'  => 'limited',            # Poland
	'RO'  => 'limited',            # Romania
	'RU'  => 'limited',            # Russian Federation/former Soviet Union
	'SU'  => 'limited',            # Russian Federation/former Soviet Union
	'SK'  => 'limited',            # Slovakia
	'SI'  => 'limited',            # Slovenia
);
1;

=head1 WWW::Patent::Page::MICROPATENT

support MicroPatent (TM) commercial service of Thomson (TM)
	
=cut

=head2 methods

set up the methods available for each document type 

=cut

=head2 MICROPATENT_login

You need a username and password.

=cut

=head2 MICROPATENT_xml

xml download

=cut

=head2 MICROPATENT_html

html download

=cut

=head2 MICROPATENT_pdf

pdf download, presently full document only

=cut

=head2 MICROPATENT_terms

You get what you pay for.

=cut

=head2 MICROPATENT_country_known

hash with keys of two letter acronyms, values of the dates covered

=cut

