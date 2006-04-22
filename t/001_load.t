# -*- perl -*-
use strict;

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 34;    # perlobj

BEGIN { use_ok('WWW::Patent::Page'); }

my $browser = WWW::Patent::Page->new();    # new object
isa_ok( $browser, 'WWW::Patent::Page', 'WWW::Patent::Page->new() works, ' );

cmp_ok( $WWW::Patent::Page::VERSION, '>=', 0.02, "VERSION is 0.02 or above" );

like( $browser->agent, qr/^WWW::Patent::Page/,
	'WWW::Patent::Page is agent default prefix' );

$browser->agent('Weed_Whacker');

unlike( $browser->agent, qr/^WWW::Patent::Page/, 'Agent can be set' );

is( $browser->country_known('US'),
	'United States of America',
	'US maps to "United States of America"'
);

is( $browser->country_known('YY'), undef, 'YY should not map' );

cmp_ok( $WWW::Patent::Page::ESPACE_EP::VERSION,
	'>=', 0.1, "ESPACE_EP loaded, VERSION is 0.1 or above" );
cmp_ok( $WWW::Patent::Page::USPTO::VERSION,
	'>=', 0.1, "USPTO loaded, VERSION is 0.1 or above" );

my $parsemessage = $browser->parse_doc_id('US6,123,456');

like( $parsemessage, qr/country:US/,     'country is US' );
like( $parsemessage, qr/number:6123456/, 'id is 6123456 from 6,123,456' );
is( $browser->{'patent'}->{'country'}, 'US', 'object records country as US' );

$parsemessage = $browser->parse_doc_id('US6_123_456');

like( $parsemessage, qr/country:US/,     'country is US' );
like( $parsemessage, qr/number:6123456/, 'id is 6123456 from 6_123_456' );

$parsemessage = $browser->parse_doc_id('YY99999');
is( $parsemessage, undef, 'YY is not a recognized country' );

$browser = WWW::Patent::Page->new('US6123456');    

is( $browser->{'patent'}->{'doc_id'}, 'US6123456', 'object records doc_ID as US when passed as value not parameter' );

is( $browser->{'patent'}->{'number'}, 6123456 , 'number from doc_id becomes the number parameter value');

$browser = WWW::Patent::Page->new('EP6123456');    

is( $browser->{'patent'}->{'country'}, 'EP', 'object records doc_ID as EP when passed as value not parameter, overriding default' );

my $patent_document = WWW::Patent::Page->new();    # new object

my $document2 = $patent_document->get_page(
	'doc_id' => '',
	'country'=> '',
	'number' => '1234567',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no country');
like( $document2->message, qr/country/ , 'correct failure message about country');   #20

$document2 = $patent_document->get_page(
	'YY9999999',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 1,
);


ok( !$document2->is_success, 'correctly failed due to no malformed request, no method');
like( $document2->message, qr/country/ , "Message: '".$document2->message."'" ); #22



 $document2 = $patent_document->get_page(
 	'doc_id' => '',
	'country'=> 'EP',
	'number' => '',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no number');
like( $document2->message, qr/number/ , 'correct failure message about number.'." Message: '".$document2->message."'" ); 


 $document2 = $patent_document->get_page(
	'doc_id' => 'EP1234567',
	'office' => '',
	'format' => 'pdf',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no office');
like( $document2->message, qr/office/ , 'correct failure message about office.'." Message: '".$document2->message."'" ); 



 $document2 = $patent_document->get_page(
	'doc_id' => 'EP1234567',
	'country'=> 'EP',
	'number' => '1234567',
	'office' => 'ESPACE_EP',
	'format' => '',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no format');
like( $document2->message, qr/format/ , 'correct failure message about format.'." Message: '".$document2->message."'" ); 

$document2 = $patent_document->get_page(
	'doc_id' => 'EP1234567',
	'office' => 'ESPACE_EP',
	'format' => '',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no format');
like( $document2->message, qr/format/ , 'correct failure message about format.'." Message: '".$document2->message."'" ); 


 $document2 = $patent_document->get_page(
	'country'=> 'EP',
	'number' => '1234567',
	'office' => 'ESPACE_EP',
	'format' => '',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no format');
like( $document2->message, qr/format/ , 'correct failure message about format.'." Message: '".$document2->message."'" ); 



 $document2 = $patent_document->get_page(
	'country'=> 'EP',
	'number' => '1234567',
	'office' => 'ESPACE_EP',
	'format' => 'pdfpdf',
	'page'   => 1,
);

ok( !$document2->is_success, 'correctly failed due to no malformed request, no method');
like( $document2->message, qr/method/ , 'correct failure message about method.'." Message: '".$document2->message."'" ); 


