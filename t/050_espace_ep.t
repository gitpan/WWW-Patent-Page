# -*- perl -*-

# t/001_load.t - test documented interface

use Test::More tests => 14;    

BEGIN { use_ok('WWW::Patent::Page'); }

my $patent_document = WWW::Patent::Page->new();    # new object

isa_ok( $patent_document, 'WWW::Patent::Page' );

like($patent_document->terms , qr/automated/ , 'terms of service reflected') ; 

my $document2 = $patent_document->get_page(
	'US6123456',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 1,
);

like( $document2->content , qr/58135/,   # get_parameter is a private method, may go away later
	'US 6,123,456 page 1, CCITTFaxDecode 58,135 bytes ' );

$document2 = $patent_document->get_page(
	'US6123456',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 2,
);

#/Length 23679

like( $document2->content, qr/23679/,
	'US 6,123,456 page 2, CCITTFaxDecode 23,679 bytes ' );


#    'Windows IE 6'      => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
#    'Windows Mozilla'   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
#    'Mac Safari'        => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
#    'Mac Mozilla'       => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
#    'Linux Mozilla'     => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
#    'Linux Konqueror'   => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',

my $office_used = $document2->get_parameter('office');    # ep

is( $office_used, 'ESPACE_EP', 'Office is espace_ep' );

my $country_used = $document2->get_parameter('country');    #US
is( $country_used, 'US', 'country US' );

my $number = $document2->get_parameter('number');           # 6654321
is( $number, 6123456, 'patent number is 6123456' );

my $page_used = $document2->get_parameter('page');          # 2
is( $page_used, 2, 'page retrieved is 2' );

my $format_used = $document2->get_parameter('format');      #tif
is( $format_used, 'pdf', 'format is correct' );

my $pages_total = $document2->get_parameter('pages');       # 101
is( $pages_total, 8, 'pages (total) is correct' );

$document2 = $patent_document->get_page(page  => 3);

# 28272
like( $document2->content, qr/28272/,
	'US 6,123,456 page 3, CCITTFaxDecode 28,272 bytes ' );
	
my $document3 = $patent_document->get_page(page  => undef);

like( $document3->content, qr/Description/,
	'US 6,123,456 all pages, has bookmark/outline reference to Description' );
	
$document2 = $patent_document->get_page(
	'EP1234567',
	'office' => 'ESPACE_EP',
	'format' => 'pdf',
	'page'   => 1,
);

like( $document2->content, qr/40274/,
	'EP 1 234 567 page 1, CCITTFaxDecode 40,274 bytes ' );

