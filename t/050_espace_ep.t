# -*- perl -*-

# t/001_load.t - test documented interface

use Test::More tests => 10;
use WWW::Patent::Page;

#BEGIN { use_ok( 'WWW::Patent::Page' ); }

my $patent_document = WWW::Patent::Page->new();  # new object

# $patent_document->proxy('http','http://127.0.0.1:5364/'); 

isa_ok ($patent_document, 'WWW::Patent::Page');

my $document2 = $patent_document->provide_doc('US6123456', 
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> 1 ,
			);
			
#open PDF, ">US6123456.pdf" or die "could not open >US6123456.pdf";
#print PDF $patent_document->{'patent'}->{'as_string'};
#close PDF;
#print "done\n";

#/Subtype /Image
#/Filter /CCITTFaxDecode
#/Length 58135


like($document2, qr/58135/ , 'US 6,123,456 page 1, CCITTFaxDecode 58,135 bytes ');

$document2 = $patent_document->provide_doc('US6123456', 
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> 2 ,
			);

#/Length 23679
			
like($document2, qr/23679/ , 'US 6,123,456 page 2, CCITTFaxDecode 23,679 bytes ');


#open PDF, ">US6123456.pdf" or die "could not open >US6123456.pdf";
#print PDF $document2;
#close PDF;
#print "done\n";
			
#    'Windows IE 6'      => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
#    'Windows Mozilla'   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
#    'Mac Safari'        => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
#    'Mac Mozilla'       => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
#    'Linux Mozilla'     => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
#    'Linux Konqueror'   => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',


my $office_used = $patent_document->get_patent('office'); # ep 

is ($office_used, 'ESPACE_EP' , 'Office is espace_ep') ;

my $country_used = $patent_document->get_patent('country'); #US
is ($country_used, 'US', 'country US'); 

my $number = $patent_document->get_patent('number');  # 6654321
is($number, 6123456, 'patent number is 6123456');

my $page_used = $patent_document->get_patent('page');  # 2
is($page_used, 2, 'page retrieved is 2'); 


my $format_used = $patent_document->get_patent('format'); #tif
is($format_used, 'pdf', 'format is correct');

my $pages_total = $patent_document->get_patent('pages_available');   # 101  
is($pages_total, 8, 'pages (total) is correct');

$document2 = $patent_document->provide_doc(page  => 3);

# 28272
like($document2, qr/28272/ , 'US 6,123,456 page 3, CCITTFaxDecode 28,272 bytes ');


#open PDF, ">US6123456.pdf" or die "could not open >US6123456.pdf";
#print PDF $patent_document->{'patent'}->{'as_string'};
#close PDF;

