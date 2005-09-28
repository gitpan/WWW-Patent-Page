
package WWW::Patent::Page;    #modeled on LWP::UserAgent
use strict;
use warnings;
use diagnostics;
use Carp;
require LWP::UserAgent;

use subs qw( new country_known get_page _load_modules _agent );
our ( $VERSION, @ISA, %MODULES, %METHODS, %_country_known, $default_country );

$VERSION = 0.02; @ISA = qw( LWP::UserAgent );

$default_country = 'US';

sub new {
	my ($class) = shift @_;

	my %parent_parms = (
		agent => "WWW::Patent::Page/$VERSION",

		#        cookie_jar => {},
	);

	my %default_parameter = (
		'office'  => 'ESPACE_EP',    # USPTO
		'country' => 'US',
		'doc_id'  => undef,          # US6,123,456
		'format'  => 'pdf',
		'page'    => undef,
		'version' => undef,
		'comment' => undef,
		'kind'    => undef,
		'number'  => undef,
	);
	if ( @_ % 2 ) { $default_parameter{'doc_id'} = shift @_ }

	# if an odd number of parameters is passed, the first is the doc_id
	# the other pairs are the hash of values, including UserAgent settings

	my %passed_parms = @_;

 # Keep the patent-specific parms before creating the object.
 # (the parameters defined above are the only user exposed parameters allowed)
	while ( my ( $key, $value ) = each %passed_parms ) {
		if ( exists $default_parameter{$key} ) {
			$default_parameter{$key} = $value;
		}
		else {
			$parent_parms{$key} = $value;
		}
	}

	my $self = $class->SUPER::new(%parent_parms);

	bless( $self, ref($class) || $class );    # or is it: bless $self, $class;

	# Use the patent parms now that we have a patent object.
	for my $parm ( keys %default_parameter ) {
		$self->{'patent'}->{$parm} = $default_parameter{$parm};
	}
	$self->env_proxy()
		; # get the proxy stuff set up from the environment via LWP::UserAgent
	push( @{ $self->requests_redirectable }, 'POST' );    # LWP::UserAgent
	$self->agent = $class->_agent unless defined $self->agent;

	$self->_load_modules(qw( USPTO ESPACE_EP))
		;  # list your custom modules here,
	       # and put them into the folder that holds the others, e.g. USPTO.pm

	if ( $self->{'patent'}->{'doc_id'} ) {   # if called with doc ID, parse it
		$self->parse_doc_id();
	}
	return $self;
}

sub country_known {
	my $self = shift;
	my ($country_in_question) = shift;
	if ( exists $_country_known{$country_in_question} ) {
		return ( $_country_known{$country_in_question} );
	}
	else { return (undef) }
}

sub parse_doc_id {
	my $self  = shift @_;
	my $found = '';
	my $id    = shift
		|| $self->{'patent'}->{'doc_id'}
		|| ( carp "No document id to parse" and return (undef) );
	if ( $id =~ s/^\s*(\D\D)/$1/i ) {    #spaces and country ID ?
		if ( $1 !~ m/RE|PP]/i )
		{    # not a US plant patent or reissue (US default...)
			$id =~ s/^\s*(\D\D)//i;
			$self->{'patent'}->{'country'} =
				uc($1);    # remove and upper case the country if found
			if ( !$_country_known{ $self->{'patent'}->{'country'} } ) {
				carp "unrecognized country: $self->{'patent'}->{'country'}";
				$self->{'patent'}->{'country'} = '';
				return (undef);
			}
			$found .= " country:$self->{'patent'}->{'country'} ";
		}
	}
	else { $self->{'patent'}->{'country'} = $default_country; }

	if ( $id =~ s/^(D|PP|RE|T|H)//i ) {
		$self->{'patent'}->{'type'} = uc($1);
		$found .= " type:$self->{'patent'}->{'type'} ";
	}
	else { $self->{'patent'}->{'type'} = '' }
	if ( $id =~ s/^([,_\-\d]+)//i ) {    #required document identifier number
		$self->{'patent'}->{'number'} =
			$1;    # warn "NUMBER is $self->{'patent'}->{'number'} \n";
		$self->{'patent'}->{'number'} =~
			s/[,\-_]//g;  # warn "NUMBER is $self->{'patent'}->{'number'} \n";
		$found .= " number:$self->{'patent'}->{'number'} ";
	}
	else { carp "no documunt number in '$id'" }
	if ( $id =~ s/^\((\w+)\)//i ) {    #optional version number
		$self->{'patent'}->{'version'} = $1;
		$found .= " version:$self->{'patent'}->{'version'} ";
	}
	else { $self->{'patent'}->{'version'} = ''; }
	if ($id) {
		$self->{'patent'}->{'comment'} = $$id;
		$found .= " version:$self->{'patent'}->{'comment'} ";
	}
			if ( exists( $self->{'patent'}->{'type'} )
			&& $self->{'patent'}->{'type'} eq 'T' )
		{
			my $text = reverse $self->{'patent'}->{'number'};
			$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
			$self->{'patent'}->{'number'} = scalar reverse $text;
		}
	
	return $found;
}

sub get_page {
	my $self = shift;
	if ( @_ % 2 ) {
		$self->{'patent'}->{'doc_id'} = shift @_;

		#	&parse_doc_id($self);
		# if an odd number of parameters is passed, the first is the doc_id
		# the other pairs are the hash of values, including UserAgent settings
	}

	my %passed_parms = @_;

 # Keep the patent-specific parms before USING the object.
 # (the parameters defined above are the only user exposed parameters allowed)
	while ( my ( $key, $value ) = each %passed_parms ) {
		if ( exists $self->{$key} ) {
			$self->{$key} = $value;
		}
		elsif ( exists $self->{'patent'}->{$key} ) {
			$self->{'patent'}->{$key} = $value;
		}
	}

	$self->parse_doc_id();    # in case of change

	my $provide_doc =
		  "$self->{'patent'}->{'office'}" . '_'
		. "$self->{'patent'}->{'format'}";
	my $function_reference = $METHODS{$provide_doc}
		or carp "No method '$provide_doc'";
	my $response = &$function_reference($self)
		or carp "No response for method '$provide_doc'";

	if ($response) { return ($response); }
	else { carp "no response to return" }

}

sub terms {
	my $self = shift;  # pass $self, then optionally the office whose terms you need, or use that office set in $self
	my $office;
	if ( @_ % 2 ) { $office = shift @_ } else {$office = $self->{'patent'}->{'office'}}
	if (!exists $METHODS{$office.'_terms'}) {
		carp "Undefined method $office"."_terms in Patent:Document::Retrieve";
		return ('WWW::Patent::Page uses publicly available information that may be subject to copyright.  
		The user is responsible for observing intellectual property rights. ');
	}
	my $terms = $office.'_terms';
	my $function_reference = $METHODS{$terms};
	return &$function_reference($self);	
}

sub _agent {"WWW::Patent::Page/$WWW::Patent::Page::VERSION"}

sub _load_modules {
	my $class     = shift;
	my $baseclass = ref $class || $class;

	my @modules = @_;    # pass a list of the modules that will be available;
	  # add more to your call for this, for custom modules for other patent offices

	# Go to each module and use them.  Also record what methods
	# they support and enter them into the %METHODS hash.

	foreach my $module (@modules) {
		my $modpath = "${baseclass}::${module}";
		unless ( defined( $MODULES{$modpath} ) ) {

			# Have to use an eval here because perl doesn't
			# like to use strings.
			eval "use $modpath;";
			carp $@ if $@;
			$MODULES{$modpath} = 1;

			# Methodhash will continue method-name, function ref
			# pairs.
			my %methodhash = $modpath->methods;
			my ( $method, $value );
			while ( ( $method, $value ) = each %methodhash ) {
				$METHODS{$method} = $value;
			}
		}
	}
	return;
}

%_country_known = (
	'OA' => 'African Independent Union',
	'AL' => 'Albania',
	'DZ' => 'Algeria',
	'AG' => 'Antigua',
	'AR' => 'Argentina',
	'AP' => 'Aripo',
	'AM' => 'Armenia',
	'AU' => 'Australia',
	'AT' => 'Austria',
	'AZ' => 'Azerbaijan',
	'BS' => 'Bahamas',
	'BH' => 'Bahrain',
	'BD' => 'Bangladesh',
	'BB' => 'Barbados',
	'BY' => 'Belarus',
	'BE' => 'Belgium',
	'BZ' => 'Belize',
	'BX' => 'Benelux',
	'BM' => 'Bermuda',
	'BO' => 'Bolivia',
	'BP' => 'Bophuthatswana',
	'BA' => 'Bosnia-Herzegov',
	'BW' => 'Botswana',
	'BR' => 'Brazil',
	'BN' => 'Brunei',
	'BG' => 'Bulgaria',
	'CA' => 'Canada',
	'CL' => 'Chile',
	'CN' => 'China People\'s Republic',
	'CO' => 'Colombia',
	'CR' => 'Costa Rica',
	'HR' => 'Croatia',
	'CU' => 'Cuba',
	'CY' => 'Cyprus',
	'CZ' => 'Czech Republic',
	'CD' => 'Democratic Republic of the Congo',
	'DK' => 'Denmark',
	'DM' => 'Dominica',
	'DO' => 'Dominican Republic',
	'DD' => 'East Germany',
	'EC' => 'Ecuador',
	'EG' => 'Egypt',
	'SV' => 'El Salvador',
	'EE' => 'Estonia',
	'ET' => 'Ethiopia',
	'EP' => 'European Patent',
	'EA' => 'Eurasian Patent',
	'FI' => 'Finland',
	'FR' => 'France',
	'GM' => 'Gambia',
	'GE' => 'Georgia',
	'DE' => 'Germany',
	'GH' => 'Ghana',
	'GI' => 'Gibraltar',
	'GB' => 'Great Britain',
	'GR' => 'Greece',
	'GD' => 'Grenada',
	'GT' => 'Guatemala',
	'GC' => 'Gulf Cooperation Council',
	'GY' => 'Guyana',
	'HT' => 'Haiti',
	'HN' => 'Honduras',
	'HK' => 'Hong Kong',
	'HU' => 'Hungary',
	'IS' => 'Iceland',
	'IN' => 'India',
	'ID' => 'Indonesia',
	'IR' => 'Iran',
	'IE' => 'Ireland',
	'IL' => 'Israel',
	'IT' => 'Italy',
	'JM' => 'Jamaica',
	'JP' => 'Japan',
	'JO' => 'Jordan',
	'KZ' => 'Kazakstan',
	'KE' => 'Kenya',
	'KP' => 'Korea North',
	'KR' => 'Korea South',
	'KW' => 'Kuwait',
	'KG' => 'Kyrgyzstan',
	'LV' => 'Latvia',
	'LB' => 'Lebanon',
	'LS' => 'Lesotho',
	'LR' => 'Liberia',
	'LI' => 'Liechtenstein',
	'LT' => 'Lithuania',
	'LU' => 'Luxembourg',
	'MK' => 'Macedonia',
	'MG' => 'Madagascar',
	'MW' => 'Malawi',
	'M1' => 'Malaya',
	'MY' => 'Malaysia',
	'MT' => 'Malta',
	'MU' => 'Mauritius',
	'MX' => 'Mexico',
	'MD' => 'Moldova',
	'MC' => 'Monaco',
	'MN' => 'Mongolia',
	'MA' => 'Morocco',
	'NA' => 'Namibia',
	'NL' => 'Netherlands',
	'NZ' => 'New Zealand',
	'NI' => 'Nicaragua',
	'NG' => 'Nigeria',
	'NO' => 'Norway',
	'OM' => 'Oman',
	'PK' => 'Pakistan',
	'PA' => 'Panama',
	'PY' => 'Paraguay',
	'WO' => 'Patent Cooperation Treaty',
	'PE' => 'Peru',
	'PH' => 'Philippines',
	'PL' => 'Poland',
	'PT' => 'Portugal',
	'QA' => 'Qatar',
	'RO' => 'Romania',
	'RU' => 'Russian Fed',
	'S1' => 'Sabah',
	'S2' => 'Sarawak',
	'SA' => 'Saudi Arabia',
	'SL' => 'Sierra Leone',
	'SG' => 'Singapore',
	'SK' => 'Slovakia',
	'SI' => 'Slovenia',
	'ES' => 'Spain',
	'LK' => 'Sri Lanka',
	'LC' => 'St. Lucia',
	'VC' => 'St. Vincent',
	'SD' => 'Sudan',
	'SZ' => 'Swaziland',
	'SE' => 'Sweden',
	'CH' => 'Switzerland',
	'SY' => 'Syria',
	'TW' => 'Taiwan',
	'TJ' => 'Tajikistan',
	'TY' => 'Tanganyika',
	'TA' => 'Tangier',
	'TZ' => 'Tanzania',
	'TH' => 'Thailand',
	'TK' => 'Transkei',
	'TT' => 'Trinidad',
	'TN' => 'Tunisia',
	'TR' => 'Turkey',
	'TM' => 'Turkmenistan',
	'UK' => 'United Kingdom',
	'US' => 'United States of America',
	'SU' => 'Union of Soviet Socialist Republics',
	'UG' => 'Uganda',
	'UA' => 'Ukraine',
	'AE' => 'United Arab Emirates',
	'UY' => 'Uruguay',
	'UZ' => 'Uzbekistan',
	'VD' => 'Venda',
	'VE' => 'Venezuela',
	'VN' => 'Vietnam',
	'YD' => 'Yemen Arabic Republic',
	'YU' => 'Yugoslavia',
	'ZM' => 'Zambia',
	'ZZ' => 'Zanzibar',
	'ZW' => 'Zimbabwe',
);

1;    #this line is important and will help the module return a true value

__END__

=head1 NAME

WWW::Patent::Page - get a patent page or document (e.g. htm, pdf, tif) 
from selected source (e.g. from United States Patent and Trademark Office 
(USPTO) website or the European Patent Office (ESPACE_EP). and
place into a WWW::Patent::Page::Response object)

=head1 SYNOPSIS

Please see the test suite for working examples.  The following is not guaranteed to be working or up-to-date.

  $ perl -I. -MWWW::Patent::Page -e 'print $WWW::Patent::Page::VERSION,"\n"'
  0.02
  
  $ perl get_patent.pl US6123456 > US6123456.pdf &  
  
  (command line interface is included in examples)
  
  http://www.yourdomain.com/www_get_patent_pdf.pl    
  
  (web fetcher is included in examples)

  use WWW::Patent::Page;
  
  print $WWW::Patent::Page::VERSION,"\n";

  my $patent_browser = WWW::Patent::Page->new(); # new object
  
  my $document1 = $patent_document->get_page('6,123,456');
  	# defaults:  	
  	#       office 	=> 'ESPACE_EP',
	# 	    country => 'US',
	#	    format 	=> 'pdf',
	#		page   	=> undef ,  
	# and usual defaults of LWP::UserAgent (subclassed)

  my $document2 = $patent_document->get_page('US6123456', 
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> 2 ,  #get only the second page
			);

  my $pages_known = $document2->get_parameter('pages');  #how many total pages known?
						
=head1 DESCRIPTION

  Intent:  Use public sources to retrieve patent documents such as
  TIFF images of patent pages, html of patents, pdf, etc.
  Expandable for your office of interest by writing new submodules..
  Alpha release by newbie to find if there is any interest

=head1 USAGE

  See also SYNOPSIS above
  
     Standard process for building & installing modules:

          perl Build.PL
          ./Build
          ./Build test
          ./Build install

Examples of use:

  $patent_browser = WWW::Patent::Page->new(
  			doc_id	=> 'US6,654,321',
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> undef ,  # returns all pages in one pdf 
			agent   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
			);
	
	$patent_response = $patent_browser->get_patent('US6,654,321(B2)issued_2_Okada');
	
	
  
 
=head1 BUGS

Pre-alpha release, to gauge whether the perl community has any interest.

Code contributions, suggestions, and critiques are welcome.

Error handling is undeveloped.

By definition, a non-trivial program contains bugs.

For United States Patents (US) via the USPTO (us), the 'kind' is ignored in method provide_doc


=head1 SUPPORT

Yes, please.  Checks are best.  Or email me at Wanda_B_Anon@yahoo.com to arrange fund transfers.

=head1 AUTHOR

	Wanda B. Anon
	Wanda_B_Anon@yahoo.com
	
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

You, the user (including those already suggesting improvements), Andy Lester, 
the authors of Finance::Quote, Erik Oliver for patentmailer, Howard P. Katseff of AT&T Laboratories for wsp.pl, version 2, 
a proxy that speaks LWP and understands proxies, and of course Larry and Randal and the gang.

=head1 SEE ALSO

perl(1).

=head1 Subroutines

=cut

=head2 new 

NEW instance of the Page class, subclassing LWP::UserAgent

=cut

=head2 country_known

country_known maps the known two letter acronyms to patenting entities, usually countries; country_known returns undef if the two letter acronym is not recognized.

=cut

=head2 parse_doc_id

Takes a human readable patent/publication identifier and parses it into country/entity, kind, number, type, ...

     CC[TY]##,###,###(V#)Comments
     
     CC : Two letter country/entity code; e.g. US, EP, WO
     TY  : Type of document; one or two letters only of these choices:
		e.g. in US, Kind = Utility is default and no "Kind" is used, e.g. US6123456
		D : Design, e.g. USD339,456
		PP: Plant, e.g. USPP8,901
		RE: Reissue, e.g. USRE35,312
		T : Defensive Publication, e.g. UST109,201
		SIR: Statutory Invention Registration, e.g. USH1,523
      V# : the version number, e.g. A1, B2, etc.; placed in parenthesis
      Comments:  retained but not used- single string of word characters \w = A-z0-9_ (no spaces, "-", commas, etc.)
		
=cut

=head2 get_page

method to use the modules specific to Offices like USPTO, with methods for each document/page format, etc., and
LWP::Agent to grab the appropriate URLs and if necessary build the response content or produce error values

=cut 

=head2 terms 

method to provide a summary or pointers to the terms and conditions of use of the publicly available databases

=head2 _load_modules 

internal private method to access helper modules in WWW::Patent::Page

=cut

=head2 _agent

private method to assign default agent

=cut 

