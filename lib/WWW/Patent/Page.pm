
package WWW::Patent::Page;
use strict;
use warnings;
use diagnostics;
use Carp;
use subs qw( new  get provide_doc pages_available _countries_known _load_modules );
use LWP::UserAgent 2.003;

use vars qw ($VERSION @ISA %MODULES %METHODS );

$VERSION = 0.01;
@ISA     = qw( LWP::UserAgent );

########################################### main pod documentation begin ##

=head1 NAME

WWW::Patent::Page - retrieve a patent page
	(e.g. from United States Patent and Trademark Office (USPTO) website or the European Patent Office (ESPACE_EP). )

=head1 SYNOPSIS

Please see the test suite for working examples.  The following is not guaranteed to be working or up-to-date.

  use WWW::Patent::Page;

  my $patent_document = WWW::Patent::Page->new(); # new object
  
  my $document1 = $patent_document->provide_doc('6,123,456');
  	# defaults:  	office 	=> 'USPTO',
	# 		country => 'US',
	#		format 	=> 'htm',
	#		page   	=> '1',      # typically htm IS "1" page
	#		modules => qw/ us ep / ,

  my $document2 = $patent_document->provide_doc('US_6_123_456', 
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'tif',
			page   	=> 2 ,
			);

  my $pages_known = $patent_document->pages_available(  # e.g. TIFF
  			document=> '6 123 456',
			);
			
			
			
=head1 DESCRIPTION

  Intent:  Use public sources to retrieve patent documents such as
  TIFF images of patent pages, html of patents, pdf, etc.
  Expandable for your office of interest by writing new submodules..
  Alpha release by newbie to find if there is any interest

=head1 USAGE

  See also SYNOPSIS above
  
     Standard process for building & installing modules:

          perl Makefile.PL
          make
          make test
          make install

Examples of use:

  $patent_document = WWW::Patent::Page->new(
  			doc_id	=> 'US6,654,321(B2)issued_2_Okada',
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'tif',
			page   	=> 2 ,
			agent   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
			);
			
#    'Windows IE 6'      => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',

#    'Windows Mozilla'   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',

#    'Mac Safari'        => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',

#    'Mac Mozilla'       => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',

#    'Linux Mozilla'     => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',

#    'Linux Konqueror'   => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',

  
  my %attributes = $patent_document->get_patent('all');  # hash of all

  my $document_id = $patent_document->get_patent('doc_id'); 
  	# US6,654,321(B2)issued_2_Okada

  my $office_used = $patent_document->get_patent('office'); # ep 

  my $country_used = $patent_document->get_patent('country'); #US

  my $doc_id_used = $patent_document->get_patent('doc_id');  # 6654321

  my $page_used = $patent_document->get_patent('page');  # 2

  my $kind_used = $patent_document->get_patent('kind');  # B2 

  my $comment_used = $patent_document->get_patent('comment');  # issued_2_Okada 

  my $format_used = $patent_document->get_patent('format'); #tif

  my $pages_total = $patent_document->get_patent('pages_available');   # 101  

  my $terms_and_conditions = $patent_document->terms('us'); # and conditions
  
  my $document = $patent_document->get_patent('document'); # the loot

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

Andy Lester for WWW::Mechanize, that got me thinking,

The authors of Finance::Quote, which served as an example of providing submodules,

Erik Oliver for patentmailer, serving as an example of getting patent documents,

Howard P. Katseff of AT&T Laboratories for wsp.pl, version 2, a proxy that speaks LWP and understands proxies,

and of course Larry and Randal and the gang.

=head1 SEE ALSO

perl(1).

=cut

sub new {
    my ($class) = shift @_;

    my %parent_parms = (
        agent      => "WWW::Patent::Page/$VERSION",
#        cookie_jar => {},
    );

    my %default_parameter = (
        office          => 'USPTO',
        country         => 'US',
	doc_id		=> '',
        format          => 'htm',
        page            => 1,
        pages_available => 0,
#	terms		=> "'Be Nice' (tm), or lose your priviledges.",
	as_string	=> '',
	version		=> '',
	comment		=> '',
	kind		=> '',
	number		=> '',
    );
    if ( @_ % 2 ) { $default_parameter{'doc_id'} = shift @_ }

    my %passed_parms = @_;

    # Keep the patent-specific parms before creating the object.
    while ( my ( $key, $value ) = each %passed_parms ) {
        if ( exists $default_parameter{$key} ) {
            $default_parameter{$key} = $value;
        }
        else {
            $parent_parms{$key} = $value;
        }
    }

    my $self = $class->SUPER::new(%parent_parms);

    bless( $self , ref($class) || $class );  # or is it: bless $self, $class;

    # Use the patent parms now that we have a patent object.
    for my $parm ( keys %default_parameter ) {
	    $self->{'patent'}->{$parm} = $default_parameter{$parm};
    }
    $self->env_proxy()
      ;    # get the proxy stuff set up from the environment via LWP::UserAgent
    push( @{ $self->requests_redirectable }, 'POST' );    # LWP::UserAgent
    
    $self->_load_modules( qw( USPTO ESPACE_EP) );  # list your custom modules here, and put them into the folder that holds the others, e.g. USPTO.pm 

#    %{$self->{'patent'}->{'country'}->{'_countries_known'}} = &_countries_known(); 
    if ($self->{'patent'}->{'doc_id'}) {&provide_doc($self);}  # if called to provide a doc, do so
    if ($self->{'patent'}->{'office'}) { &terms($self,$self->{'patent'}->{'office'}) }  # if called with an office in mind, get its terms of service
    
    return $self;
}

sub terms {
	my $self = shift;  # pass $self, then optionally the office whose terms you need, or use that office set in $self
	my $office;
	if ( @_ % 2 ) { $office = shift @_ } else {$office = $self->{'patent'}->{'office'}}
	my %passed_parms = @_;
	while ( my ( $key, $value ) = each %passed_parms ) {
        if ( exists $self->{'patent'}->{$key} ) {
            $self->{'patent'}->{$key} = $value;
        }
        else {
            warn "Passed unrecognized patent attribute => value: '$key' => '$value'.";
        }
	}
	unless (exists $METHODS{$office.'_terms'}) {
		carp "Undefined method $office"."_terms in Patent:Document::Retrieve";
		return;
	}
	my $terms = $office.'_terms';
	my $function_reference = $METHODS{$terms};
	return &$function_reference($self) or warn "crap";	
}

sub provide_doc{
	my $self = shift;
	if ( @_ % 2 ) { $self->{'patent'}->{'doc_id'} = shift @_ }
	my %passed_parms = @_;
	while ( my ( $key, $value ) = each %passed_parms ) {
        if ( exists $self->{'patent'}->{$key} ) {
            $self->{'patent'}->{$key} = $value;
        }
        else {
            warn "Passed unrecognized patent attribute => value: '$key' => '$value'.";
        }
	}
#	print "alls well.\n";
	{
		#no strict 'refs';
		unless (exists $METHODS{$self->{'patent'}->{'office'}.'_parse_doc_id'}) {
			carp "Undefined parse method '$self->{'patent'}->{'office'}_parse_doc_id' in Patent:Document::Fetch\n %METHODS";
			return;
		}
		my $parse_doc_id = "$self->{'patent'}->{'office'}".'_parse_doc_id';
		my $function_reference = $METHODS{$parse_doc_id};
		&$function_reference($self) or warn "could not interpret doc_id '$self->{'patent'}->{'doc_id'}' with method $self->{'patent'}->{'office'}_interpret_id from module $self->{'patent'}->{'office'}.pm";
		my $provide_doc = "$self->{'patent'}->{'office'}".'_'."$self->{'patent'}->{'format'}";
		$function_reference = $METHODS{$provide_doc}; 
		&$function_reference($self) or carp "crap for '$provide_doc'\n";		
	}
	return ($self->{'patent'}->{'as_string'});
	}

sub interpret_document_id{
	
}

sub pages_available{
	my $self = shift @_ ;
	return $self->{'patent'}->{'pages_available'};
}

sub get_patent{
	my $self = shift @_ ;
	my %return;
	if (! @_ ) { warn 'Nothing to get!'; return (undef);}
	elsif ( @_ == 1) {
		if ( defined($self->{'patent'}->{$_[0]}) ) {
			return $self->{'patent'}->{$_[0]}
		}
	}
	while (my $what = shift @_ ) {
		if ($what eq 'all'){return (%{$self->{'patent'}}) }
		elsif ( defined($self->{'patent'}->{$what}) ) {
			$return{$what} = $self->{'patent'}->{$what};
		}
		else {warn "Unrecognized parameter '$what' in call to 'get_patent'."}
	}
	return (%return);
}


# _load_module (private class method)
# _load_module loads a module(s) and registers its various methods for
# use.

sub _load_modules {
	my $class = shift;
	my $baseclass = ref $class || $class;

	my @modules = @_;  # pass a list of the modules that will be available; add more to your call fo this for custom modules for other patent offices

	# Go to each module and use them.  Also record what methods
	# they support and enter them into the %METHODS hash.

	foreach my $module (@modules) {
		my $modpath = "${baseclass}::${module}";
		unless (defined($MODULES{$modpath})) {

			# Have to use an eval here because perl doesn't
			# like to use strings.
			eval "use $modpath;";
			carp $@ if $@;
			$MODULES{$modpath} = 1;

			# Methodhash will continue method-name, function ref
			# pairs.
			my %methodhash = $modpath->methods;
			my ($method,$value);
			while ( ($method,$value) = each %methodhash) {
				$METHODS{$method}=$value ;  
			}
		}
	}
	return ;
}




############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 Subroutine _countries_known() 

 Usage     : internal method only
 Purpose   : list all entities that could give a patent
 Returns   : ref to a hash with keys of abbreviations and values of entities (usually a country)  ...

=cut

sub _countries_known {
    return (
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
}

1;    #this line is important and will help the module return a true value


__END__

