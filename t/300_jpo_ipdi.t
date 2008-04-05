# -*- perl -*-

# t/300_JPO_IPDI.t

use Test::More tests => 7;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use IO::Scalar; 
my $SH; 
my $zip = Archive::Zip->new();

BEGIN {use_ok('WWW::Patent::Page');}    #1

diag "Version $WWW::Patent::Page::VERSION \n";
my $patent_document = WWW::Patent::Page->new();    # new object

isa_ok($patent_document, 'WWW::Patent::Page');

diag('It can take a long time to retrieve the translations- please be patient.');
my $name;
my $zipContents;

$name = 'JP2006-004050A1';
$zip  = $patent_document->get_page(
	$name,
	'office' => 'JPO_IPDI',
	'format' => 'translation',
);

unless ($patent_document->{is_success}) {print "no success in 300_jpo_ipdi.t\n";}
#$SH = IO::Scalar->new(\$zipContents);
#$zip->readFromFileHandle( $SH );
ok($zip->numberOfMembers() == 18, 'finding 18 files in the zipped archive for ' . $name . ', found ' . $zip->numberOfMembers());


$name = 'JPH09-123456A';
&test1();

sub test1 {
	$zip = $patent_document->get_page(
		$name,
		'office' => 'JPO_IPDI',
		'format' => 'translation',
	);
	unless ($patent_document->{is_success}) {
		print "no success in 300_jpo_ipdi.t\n";
	}
}
#$SH = IO::Scalar->new(\$zipContents);
#zip->readFromFileHandle( $SH );
ok($zip->numberOfMembers() == 16, 'finding 16 files in the zipped archive for ' . $name . ', found ' . $zip->numberOfMembers());



$name = 'JP2004012345A';
$zip  = $patent_document->get_page(
	$name,
	'office' => 'JPO_IPDI',
	'format' => 'translation',
);

unless ($patent_document->{is_success}) {print "no success in 300_jpo_ipdi.t\n";}

#$SH = IO::Scalar->new(\$zipContents);
#$zip->readFromFileHandle( $SH );
#unless ($zip->writeToFileNamed("P:\\workspace\\WWW-Patent-Page\\new_$name" . '.zip') == AZ_OK) {
#	warn 'zip write error';
ok($zip->numberOfMembers() == 18, 'finding 18 files in the zipped archive for ' . $name . ', found ' . $zip->numberOfMembers());

$name = 'JPH09-043097A';
$zip  = $patent_document->get_page(
	$name,
	'office' => 'JPO_IPDI',
	'format' => 'translation',
);

unless ($patent_document->{is_success}) {print "no success in 300_jpo_ipdi.t\n";}

#$SH = IO::Scalar->new(\$zipContents);
#$zip->readFromFileHandle( $SH );
ok($zip->numberOfMembers() == 10, 'finding 10 files in the zipped archive for ' . $name . ', found ' . $zip->numberOfMembers());

$name = 'JP2500002B';
$zip  = $patent_document->get_page(
	$name,
	'office' => 'JPO_IPDI',
	'format' => 'translation',
);

unless ($patent_document->{is_success}) {print "no success in 300_jpo_ipdi.t\n";}
#$SH = IO::Scalar->new(\$zipContents);
#$zip->readFromFileHandle( $SH );
ok($zip->numberOfMembers() == 15, 'finding 15 files in the zipped archive for ' . $name . ', found ' . $zip->numberOfMembers());
