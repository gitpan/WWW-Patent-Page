# -*- perl -*-

# t/001_load.t - test documented interface

use Test::More tests => 21;
BEGIN { use_ok('WWW::Patent::Page'); }

my $patent_document = WWW::Patent::Page->new();    # new object
isa_ok( $patent_document, 'WWW::Patent::Page' );

my $document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'USPTO',
	'country' => 'US',
	'format'  => 'htm',
	'page'    => '1',                              # typically htm IS "1" page
);                                                 
like( $document1->content, qr/Anon/, 'utility patent by Ramon L. Anon' );

#my %attributes = $patent_document->get_patent('all');  # hash of all
#warn "\nAttributes:\n" , join ("\n" , %attributes) ;
is( $document1->get_parameter('number'), 4299215, 'the patent document number' );
is( $document1->get_parameter('doc_id'), '4,299,215',
	'the patent document identifier supplied' );

my $document_id = $document1->get_parameter('doc_id');

# US6,654,321(B2)issued_2_Okada
is( $document_id, '4,299,215', 'doc_id = 4,299,215' );

my $office_used = $document1->get_parameter('office');
is( $office_used, 'USPTO', 'Office is us' );

my $country_used = $document1->get_parameter('country');
is( $country_used, 'US', 'country US' );

my $format_used = $document1->get_parameter('format');
is( $format_used, 'htm', 'format is htm/html' );

like($patent_document->terms , qr/general public/ , 'terms of service reflected') ; 

$terms_and_conditions = $patent_document->terms;             # and conditions

#print "hello! \n\n\n\n", $terms_and_conditions;
like( $terms_and_conditions, qr/www.USPTO.gov/,
	'terms at http://www.USPTO.gov' );

my $document = $patent_document->get_page();                 # the loot
like( $document->content, qr/Anon/, 'utility patent by Ramon L. Anon' );

my $document2 = $patent_document->get_page(
	'US_6_123_456',
	'office' => 'USPTO',
	'format' => 'tif',
	'page'   => 2,
);

$pages_known = $document2->get_parameter('pages');

is( $pages_known, 8, 'US 6,123,456, 8 pages long' );

$document2 = $patent_document->get_page(
	'US_6_123_456',
	'office' => 'USPTO',
	'format' => 'htm'
);

like( $document2->content, qr/Catalytic hydrogenation to remove gas/, 'US_6_123_456' );

$document1 = $patent_document->get_page('USD339,456');
like(
	$document1->content, 
	qr/ornamental design for a shoe sole/,
	'D339,456: retrieve the sole of Kayano of Asics'
);
$document1 = $patent_document->get_page('USPP8,901');
like(
	$document1->content, 
	qr/Parentage: Unknown; selected from among several/,
	'PP8,901: Enkianthus perulatus'
);
$document1 = $patent_document->get_page('USRE35,312');
like( $document1->content , qr/endospongestick probe/, 'RE35,312' );
$document1 = $patent_document->get_page('USH1,523');
like( $document1->content ,
	qr/olymer film having a conductivity gradient across its thickness/,
	'H1,523' );
$document1 = $patent_document->get_page('UST109,201');
like($document1->content , qr/optical alignment tool and method is described for setting a datum line/,
	'T109,201');
$document1 = $patent_document->get_page('20010000044');
like(
	$document1->content,
	qr/Methods For Transacting Business/,
	'retrieve 20010000044 by Wayne W. Lin'
);
$document1 = $patent_document->get_page('USD339,456');
like(
	$document1->content,
	qr/ornamental design for a shoe sole/,
	'D339,456: retrieve the sole of Kayano of Asics'
);
