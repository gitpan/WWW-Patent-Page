# -*- perl -*-

# t/001_load.t - test documented interface

use Test::More tests => 20;
use WWW::Patent::Page;

#BEGIN { use_ok( 'WWW::Patent::Page' ); }

my $patent_document = WWW::Patent::Page->new();  # new object
isa_ok ($patent_document, 'WWW::Patent::Page');

my $document1 = $patent_document->provide_doc('4,299,215');#4,299,215 
  	# defaults:  	office 	=> 'USPTO',
	# 		country => 'US',
	#		format 	=> 'htm',
	#		page   	=> '1',      # typically htm IS "1" page
	#		modules => qw/ us ep / ,
	
like($document1, qr/Anon/ , 'utility patent by Ramon L. Anon');

  
my %attributes = $patent_document->get_patent('all');  # hash of all
#warn "\nAttributes:\n" , join ("\n" , %attributes) ; 
is ( $attributes{'number'},4299215, 'all tells the patent document number' ) ;
is ( $attributes{'doc_id'},'4,299,215', 'all tells the patent document identifier supplied' ) ;

my $document_id = $patent_document->get_patent('doc_id'); 
  	# US6,654,321(B2)issued_2_Okada
is ($document_id , '4,299,215' , 'doc_id = 4,299,215' );

my $office_used = $patent_document->get_patent('office'); 
is ($office_used, 'USPTO' , 'Office is us') ;

my $country_used = $patent_document->get_patent('country'); 
is ($country_used, 'US', 'country US'); 

my $format_used = $patent_document->get_patent('format'); 
is ($format_used, 'htm', 'format is htm/html');

$terms_and_conditions = $patent_document->terms('USPTO'); # and conditions
#print "hello! \n\n\n\n", $terms_and_conditions;
like($terms_and_conditions, qr/www.USPTO.gov/ , 'terms at http://www.USPTO.gov');

$terms_and_conditions = $patent_document->terms; # and conditions
#print "hello! \n\n\n\n", $terms_and_conditions;
like($terms_and_conditions, qr/www.USPTO.gov/ , 'terms at http://www.USPTO.gov');



my $document = $patent_document->get_patent('as_string'); # the loot
like($document, qr/Anon/ , 'utility patent by Ramon L. Anon');

my $document2 = $patent_document->provide_doc('US_6_123_456', 
  			office 	=> 'USPTO' ,
			format 	=> 'tif',
			page   	=> 2 ,
			);



$pages_known = $patent_document->pages_available(  # e.g. TIFF
  			
			);
			
is($pages_known , 8 , 'US 6,123,456, 8 pages long');

$document2 = $patent_document->provide_doc('US_6_123_456', 
  			office 	=> 'USPTO' ,
			format 	=> 'htm');

like($document2, qr/Catalytic hydrogenation to remove gas/ , 'US_6_123_456');

$document1 = $patent_document->provide_doc('D339,456');
like($document1, qr/ornamental design for a shoe sole/ , 'D339,456: retrieve the sole of Kayano of Asics');
$document1 = $patent_document->provide_doc('PP8,901');
like($document1, qr/Parentage: Unknown; selected from among several/ , 'PP8,901: Enkianthus perulatus');
$document1 = $patent_document->provide_doc('RE35,312');
like($document1, qr/endospongestick probe/ , 'RE35,312');
$document1 = $patent_document->provide_doc('H1,523');
like($document1, qr/olymer film having a conductivity gradient across its thickness/ , 'H1,523');
$document1 = $patent_document->provide_doc('T109,201');
like($document1, qr/optical alignment tool and method is described for setting a datum line/ , 'T109,201');
$document1 = $patent_document->provide_doc('20010000044');
like($document1, qr/Methods For Transacting Business/ , 'retrieve 20010000044 by Wayne W. Lin');
$document1 = $patent_document->provide_doc('D339,456');
like($document1, qr/ornamental design for a shoe sole/ , 'D339,456: retrieve the sole of Kayano of Asics');
