
package WWW::Patent::Page::ESPACE_EP;
use strict;
use warnings;
use diagnostics;
use Carp;
use subs
	qw( methods ESPACE_EP_country_known ESPACE_EP_pdf  ESPACE_EP_terms  );
use LWP::UserAgent 2.003;
require HTTP::Request;
use URI;
use HTML::Form;
use URI;
use PDF::API2;
use WWW::Patent::Page::Response;

our ( $VERSION, @ISA, %_country_known );

$VERSION = "0.21";

sub methods {
	return (
		'ESPACE_EP_pdf'                 => \&ESPACE_EP_pdf,
		'ESPACE_EP_country_known' => \&ESPACE_EP_country_known,

		#		'ESPACE_EP_parse_doc_id'        => \&ESPACE_EP_parse_doc_id,
		'ESPACE_EP_terms' => \&ESPACE_EP_terms,
	);

}

sub ESPACE_EP_country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if ( exists $_country_known{$country_in_question} ) {
		return ( $_country_known{$country_in_question} );
	}
	else { return (undef) }
}

sub ESPACE_EP_pdf {
	my ($self,$response) = @_;
	my (   $url,       $request, $http_response, $base,
		$zero_fill, $html,    $p,             $referer,
		%bookmarks, $first,   $last
	);
	if (!$self->{'patent'}{'country'}) {
		$response->{'message'} =
			"country not specified (or doc_id has unrecognized country)";
		$response->{'is_success'} = undef;
		return ($response);
		}
	if ( !&ESPACE_EP_country_known($self, $self->{'patent'}{'country'} ) )
	{    #unrecognized country
		$response->{'message'} =
			"country '".$self->{'patent'}{'country'}."' unrecognized";
		$response->{'is_success'} = undef;
		return ($response);
	}
	my $number   = $self->{'patent'}{'number'};
	my $short_id = $self->{'patent'}{'country'} . $number;

	if ( !$number ) {
		$response->{'message'} = "number '$self->{'patent'}{'number'}' bad";
		$response->{'is_success'} = undef;
		return ($response);
	}

	# first, try it quick and dirty...

	{ #http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456
		$url =
			  'http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX='
			. $short_id
			. '&F=128&QPN='
			. $short_id;
		$request = new HTTP::Request( 'GET' => "$url" )
			or carp "trouble with request object of '$url'";
		$http_response = $self->request($request);
		unless ( $http_response->is_success ) {
			carp
				"Request '$url' failed with status line '$http_response->status_line'.  Bummer.\n";
			return (undef);
		}

# <a href="#" target="_top" onClick="return changeSel(0)">
# <img name="L1" src="/images/L-1st-GR.gif" ALT="1" border="0">
# </a>&nbsp;<a href="#" target="_top" onClick="return changeSel(-1)">
# <img name="L2" src="/images/L-AR-GR.gif" ALT="previous" border="0">
# </a>&nbsp;<select name="pageSel" onChange="go(this)">
# <option value="1" selected>1/8 - Biblio/Abstract</option>
# <option value="2">2/8 - Drawings</option>
# <option value="3">3/8</option>
# <option value="4">4/8 - Description</option>
# <option value="5">5/8</option>
# <option value="6">6/8</option>
# <option value="7">7/8 - Claims</option>
# <option value="8">8/8</option>
# </select>&nbsp;<a href="/pdfdocnav?DB=EPODOC&IDX=US6123456&QPN=US6123456&PGN=2" target="_top" onClick="return changeSel(1)">

		#	$referer = $url;
		$html =
			$http_response->content
			;    # got to find them page numbers and information/bookmarks

		#	$base    = $http_response->base;

		#    print " from '$url', note html:\n$html\n";

		while (   $html =~
			m{ > \s* # option value closing with >, then optional spaces
			(\d+) [/] \d+   #    1/8 for example			
			\s+ [-] \s+      #   -  (dash)
			([\w\/]+)       # page type description
			}gxms
			)
		{    # find the labels of pages
			$bookmarks{$1} =
				$2;    # store the labels as bookmarks keyed by page number

			#		print "$1 -> $2\n"
		}

		if ( $html =~ m|1/(\d+)| ) {    # find the last page number
			$response->set_parameter( 'pages', $1 );
			$first = 1;
			$last  = $1;
		}
		else {
			carp
				"no maximum page number found in $self->{'patent'}{'country'}$number: \n$html";
		}

		if ( $response->get_parameter('page') )
		{    # a page is requested; otherwise, all are requested...
			$first = $response->get_parameter('page');
			$last  = $first;
		}

# http://v3.espacenet.com/simplepdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456&PGN=1
		my $currenttime = localtime();
		my $pdf         = PDF::API2->new;
		$pdf->preferences(
                   -outlines => 1,
                   );
		
		my %h           = $pdf->info(
			'Author'       => "Programatically Produced from Public Information",
			'CreationDate' => $currenttime,
			'ModDate'      => $currenttime,
			'Creator'      => "WWW::Patent::Page::ESPACE_EP",
			'Producer'     => "European Patent Office and PDF::API2",
			'Title'        => "$short_id",
			'Subject'      => "patent",
			'Keywords'     => "$short_id WWW::Patent::Page"
		);
		# Initialize the root of the outline tree

	my $outline_root = $pdf->outlines();
my $font = $pdf->corefont('Helvetica'); # Use Helvetica throughout

		my $page_now = $first;
		for my $page ( $first .. $last ) {
			$url =
				  'http://v3.espacenet.com/simplepdfdoc?DB=EPODOC&IDX='
				. $short_id
				. '&F=128&QPN='
				. $short_id . '&PGN='
				. $page;
			$request = new HTTP::Request( 'GET' => "$url" )
				or carp "trouble with request object of '$url'";
			$http_response = $self->request($request);
			if ( !$http_response->is_success ) {
				carp
					"Request '$url' failed with status line '$http_response->status_line'.  Bummer.\n";
				return (undef);
			}

			my $inpdf = PDF::API2->openScalar( $http_response->content() );
			my $pages = scalar @{ $inpdf->{pagestack} };
			my $bookmark;
			for my $ppage ( 1 .. $pages ) {    # should only have 1
				                                  # print STDERR "$page.";
				$pdf->importpage( $inpdf, $ppage );
				my $pdfpage = $pdf->openpage(-1);  # returns the last page
				if (defined($bookmarks{$page}) ){
					$bookmark = $outline_root->outline();
					$bookmark->title($bookmarks{$page});
					$bookmark->dest($pdfpage);
				}
			}
			$inpdf->end();

		}

		if ( $response->set_parameter( 'content', $pdf->stringify() ) )
		{                                         
			$response->{'is_success'} = 'pdf successfully built';
			return $response;
		}
	}

	# if quick and dirty did not work, try the hard way

	return (undef);

#    print "patent number of interest is '$number'\n";
# Request: http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN=US6123456&Submit=SEARCH&=&=&=&=&=
# Referer: http://ep.espacenet.com/search97cgi/s97_cgi.exe?Action=FormGen&Template=ep/en/number.hts
# link of interest for bookmarks/outline is http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456
# http://v3.espacenet.com/simplepdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456&PGN=1 is the heart
# simplepdfdoc preferred over pdfdoc due to lack of broken things like absense of ID for doc and broken encryption
	$referer =
		"http://ep.espacenet.com/search97cgi/s97_cgi.exe?Action=FormGen&Template=ep/en/number.hts";
	$url =
		'http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN='
		. "$self->{'patent'}{'country'}$number"
		. '&Submit=SEARCH&=&=&=&=&=';
	$request = HTTP::Request->new( 'GET' => $url );
	$request->referer($referer);
	$http_response = $self->request($request);
	unless ( $http_response->is_success ) {
		$response->{'message'} =
			"request of http://ep.espacenet.com/search97cgi/s97_cgi.exe bad: '$http_response->message'";
		$response->{'is_success'} = undef;
		return ($response);
	}
	$referer = $url;
	$base    = $http_response->base;
	$html    = $http_response->content;
	if ( $html =~ m/="(textdoc[^"]+$number[^"]*)/ ) {
		$url = $1;
	}
	else {
		$response->{'message'} =
			"did not find the textdoc link in the javascript: '$html'";
		$response->{'is_success'} = undef;
		return ($response);
	}
	$url = URI->new_abs( $url, $base );

	#    print "\nsearch result url of interest (from loop exit?): $url\n";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "trouble with request object of '$url'";
	$request->referer($referer);
	$http_response =
		$self->request($request);    # go to the page of many choices of views

# send in the first returned hit (absoluted):
# Request for URL:  http://v3.espacenet.com/textdoc?DB=EPODOC&IDX=US6123456&F=0
# INPUT: Referer: http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN=US6123456&Submit=SEARCH&=&=&=&=&=
# Find the "origdoc" link
# <A class="bluedark" href="origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456" >Original document</A>
# in h331.html
	unless ( $http_response->is_success ) {
		carp
			"Request '$url' failed with status line '$http_response->status_line'.  Bummer.\n";
		return (0);
	}
	$referer = $url;                      # use later on next request
	$html    = $http_response->content;
	$base    = $http_response->base;
	if ( $html =~ m/="(origdoc[^"]+$number[^"]+$number[^"]*)/ ) {
		$url = $1;
	}
	else {
		carp
			"did not find the original document link in the javascript: $html\n";
		exit;
	}
	$url = URI->new_abs( $url, $base );

	#    print "\nusing origdoc, next url '$url'\n";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "trouble with request object of '$url'";
	$request->referer($referer);
	$http_response =
		$self->request($request)
		; # get the page with the rotten PDF on it, "Original Document" link-to

# Request: http://v3.espacenet.com/origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456
# Referer: http://v3.espacenet.com/textdoc?DB=EPODOC&IDX=US6123456&F=0
# Look for maximise link in h333.html
# <a href="#" onClick="openMax(); return false">Maximise</a>
# (hidden... you bad boys!) function openMax() {  var link ="pdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456".replace('pdfdoc','pdfdocnav');
# Request: http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456
	unless ( $http_response->is_success ) {
		carp "this request '$url' failed with status line '"
			. $http_response->status_line
			. "'.  Bummer.\n";
		return (0);
	}
	$referer = $url;
	$html    = $http_response->content;
	$base    = $http_response->base;      # looking for that Maximize link...

	$url = '';
	if ( $html =~ m/"(pdfdoc[^'"]*$number[^"]*)/ ) {
		$url = $1;
		$url =~ s/pdfdoc\?/pdfdocnav?/;
	}
	else { carp "could not find 'pdfdoc' url in '$referer': \n$html"; exit }
	$url =
		URI->new_abs( $url, $base )
		; # should be the url of the navigation header above the pdf pages, supplies the number of pages

	# print "going for the url from the maximise link: \n'$url'\n";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "trouble with request object of '$url'";
	unless ( $http_response->is_success ) {
		carp
			"Request '$url' failed with status line '$http_response->status_line'.  Bummer.\n";
		return (0);
	}
	$request->referer($referer);
	$http_response = $self->request($request);   # go to the navigation header

# Request: http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456
# Referer: http://v3.espacenet.com/origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456
# Look for link to PDF, in h336.html:
#
# Request: http://v3.espacenet.com/simplepdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456&PGN=1

	$referer = $url;
	$html    = $http_response->content;
	$base    = $http_response->base;

	#    print " from '$url', note html:\n$html\n";

	if ( $html =~ m|1/(\d+)| ) {
		$self->{'patent'}->{'pages_available'} = $1;
	}
	else {
		carp
			"no maximum page number found in $self->{'patent'}{'country'}$number: \n$html";
	}
	if ( $html =~ m/"(simplepdfdoc[^'"]*$number[^"]*)/ ) {
		$url = $1;
	}
	else { carp "no first page PDF framing link to grab in: \n$html"; }

	$url =~ s/&PGN=\d+//i;    # remove page number portion
	$url = $url . '&PGN=' . $self->{'patent'}{'page'};
	$url =
		URI->new_abs( $url, $base )
		; # should be the url of the navigation header above the pdf pages, supplies the number of pages

	# print "url from navigation that points to pdf: \n'$url'\n";
	$request = new HTTP::Request( 'GET' => "$url" )
		or carp "trouble with request object of '$url'";
	$request->referer($referer);
	$http_response = $self->request($request);   # go to the navigation header
	unless ( $http_response->is_success ) {
		carp "Request '$url' failed with status line '"
			. $http_response->status_line
			. "'.  Bummer.\n";
		exit;
	}

	# Eureka...
	$self->{'patent'}->{'as_string'} = $http_response->content;
	return $self;
}

sub ESPACE_EP_terms {
	my ($self) = @_;
	return (
		"The ep.espacenet.com web site is utilized.\n
Refer to that site for terms and conditions of use.  For example, 
http://ep.espacenet.com/search97cgi/s97_cgi.exe?Action=FormGen&Template=ep/en/info.hts&INFO=disclaimer
once said:

'A. USER OBLIGATIONS

Users of the esp\@cenet service must comply with all the applicable laws. 
Especially, they must refrain from violating or attempting to violate 
the EPO\'s network security and must make fair use of the services 
provided. Users who deny or decrease access to or use of the 
esp\@cenet service to other users in any way (for example by 
generating unusually high numbers of service 
accesses - searches or retrievals, whether generated 
manually or in an automated fashion), may 
be denied access to these services without notice.

Due to limitations of equipment and bandwidth, the 
esp\@cenet service is not intended to be a source for 
bulk downloads of data. Users who wish to download 
large amounts of data (for example facsimile page images), 
should contact espacenetmarketing\@epo.org.'

"
	);
}

%_country_known = (
	'AT' => 'from 1990',
	'BE' => 'from 1990',
	'BG' => 'from 2000',
	'CH' => 'from 1970',
	'CN' => 'from 1990',
	'CZ' => 'from 2000',
	'DE' => 'from 1970',
	'EP' => 'from begin',
	'ES' => 'from 1983',
	'FI' => 'from 1985',
	'FR' => 'from 1970',
	'GB' => 'from 1970',
	'GR' => 'from 1996',
	'IE' => 'from 1990',
	'IT' => 'from 1993',
	'JP' => 'from 1973',
	'KR' => 'from 1979',
	'LT' => 'from 2001',
	'LV' => 'from 1999',
	'MD' => 'from 2000',
	'NL' => 'from 1990',
	'NZ' => 'from 1999',
	'PT' => 'from 1990',
	'RO' => 'from 1999',
	'RU' => 'from 1998',
	'SE' => 'from 1990',
	'SI' => 'from 1998',
	'SK' => 'from 1993',
	'SU' => 'from 1998',
	'TW' => 'from 2000',
	'US' => 'from 1970',
	'WO' => 'from 1978',
);

1;

=head1 WWW::Patent::Page::ESPACE_EP

support the use of the EPO branch of the ES_PACE WWW
	
=cut

=head2 methods

set up the methods available for each document type 

=cut

=head2 ESPACE_EP_pdf

pdf capture and manipulation

This is where the fun stuff happens.  The pdf that are captured have no encryption, not even broken encryption.  Available html allows bookmarks to be made.

=cut

=head2 ESPACE_EP_terms

terms of use

=cut


=head2 ESPACE_EP_country_known

hash with keys of two letter acronyms, values of the dates covered

=cut

