# -*- perl -*-

# t/200.t - test micropatent
$| = 1;
use Carp qw(cluck confess);
use warnings;
use diagnostics;
use WWW::Patent::Page; 
use Data::Dumper;

use Test::More ;
my $patent_document = WWW::Patent::Page->new();    # new object

#login to Micropatent?

$patent_document->{patent}->{office}= "MICROPATENT";
# Edit these username and password values if you have a login account and want to run the tests.
$patent_document->{patent}->{office_username}= "YourUserName";
$patent_document->{patent}->{office_password}= "YourPassword";
#$patent_document->{patent}->{office_username}= "YourUserName";
#$patent_document->{patent}->{office_password}= "YourPassword";


if ( exists($ENV{TEST_AUTHOR}) and ( $ENV{TEST_AUTHOR} eq 'Wanda_B_Anon' ) ) {
	my $msg = 'Author running these tests, with the username and password set in environmental variables. '; 
	diag($msg);
	plan tests => 12; 
$patent_document->{patent}->{office_username} = $ENV{MICROPATENT_USERNAME};
$patent_document->{patent}->{office_password} = $ENV{MICROPATENT_PASSWORD};
}
elsif ($patent_document->{patent}->{office_username} eq 'YourUserName') {
	plan( skip_all => 'Need to set username and password to run these tests.' );
	exit; 
}
else {plan tests => 12; }

isa_ok( $patent_document, 'WWW::Patent::Page' );

SKIP: {
#	warn $patent_document->{patent}->{office_username} . $patent_document->{patent}->{office_password} . "\n"; 
	skip ("No MicroPatent USERNAME and PASSWORD supplied in this test file; if you have credentials, edit them in and run the tests again.", 7) unless ( ($patent_document->{patent}->{office_username} ne "YourUserName") || ($patent_document->{patent}->{office_password} ne "YourPassword") ) ;
$patent_document->login() ;
like ($patent_document->{'patent'}->{'session_token'}, qr/\d+/, "session id a number: '$patent_document->{'patent'}->{'session_token'}'");  # /
like ($patent_document->{'patent'}{'session_token'}, qr/\d+/, "\$patent_document->{'patent'}{'session_token'} a number: '$patent_document->{'patent'}{'session_token'}");  # /

my $session_id = $patent_document->{'patent'}{'session_token'};

$patent_document->{'patent'}{'session_token'} = '';

my $document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'xml',
	'page'    => '',                              # typically xml IS "1" page
);

like ( $document1->{'message'}, qr/login token not available/ , "no token, no session" ) ;  # /

$patent_document->{'patent'}->{'session_token'} = $session_id; # don't try this at home, kids
# US2329490

$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'xml',
	'page'    => '',                              # typically xml IS "1" page
);

like ( $document1->content, qr/Anti-contamination device for use in operating theatres/, 'xml bears correct title of US4299215'  );

$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'html',
	'page'    => '',                              # typically xml IS "1" page
);

like ( $document1->content, qr/ANTI-CONTAMINATION DEVICE FOR USE IN OPERATING THEATRES/, 'html bears correct title of US4299215'  );

$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'pdf',
	'page'    => '',                              # typically xml IS "1" page
);

unless ($document1->is_success) {cluck $document1->message ; }
#print Data::Dumper->Dump([$document1], ['$document1']); 

#print "hi!\n", $document1->{'patent'}{2}, "\n\n\n\n\n",
# $document1->{'patent'}{3}, "\n\n\n\n\n"
#; 

like ( $document1->content, qr/Description/, 'pdf US4299215 has a bookmark to Description'  );


$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'data',
	'page'    => '',                              # typically xml IS "1" page
);

# print "\$document1 = '$document1'\n";  
#my %hash = %{$document1->content()};
#use Data::Dumper;
# print Dumper($document1), "\n\n" ; 
#print '%hash = ' , Dumper(%hash) ; 

like (${$document1->content()}{'identification'}, qr/4299215/ , 'content has the patent number' );
like (${$document1->{data}}{'identification'}, qr/4299215/ , 'data has the patent number' );
}

$document1 = $patent_document->get_page(
	'US2323935',                                   # US2323935
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'html',
	'page'    => '',                              # typically xml IS "1" page
);

# print "\$document1 = '$document1'\n"; 

# print Data::Dumper->Dump([$document1], ['$document1']); 

#unless ($document1->is_success) {cluck $document1->message ; }

like ( $document1->content, qr/snowshoe sandals/, 'html US2323935 regards snowshoe sandals'  );


$document1 = $patent_document->get_page(
	'US2323935',                                   # US2323935
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'xml',
	'page'    => '',                              # typically xml IS "1" page
);

# print "\$document1 = '$document1'\n"; 

# print Data::Dumper->Dump([$document1], ['$document1']); 

#unless ($document1->is_success) {cluck $document1->message ; }

like ( $document1->content, qr/Snowshoe sandal/, 'xml US2323935 regards Snowshoe sandal'  );



$document1 = $patent_document->get_page(
	'US2323935',                                   # US2323935
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'pdf',
	'page'    => '',                              # typically xml IS "1" page
);

# print "\$document1 = '$document1'\n"; 

# print Data::Dumper->Dump([$document1], ['$document1']); 

#unless ($document1->is_success) {cluck $document1->message ; }

my $pdf;

if ($document1->content =~ m/^\%PDF/ ) {$pdf = '%PDF';}
else {
	open my $FILE , '>US2323935_test.pdf' or die 'no file open' ;
	print $FILE Data::Dumper->Dump([$document1], ['$document1']); 
	close $FILE;
	diag("the file US2323935_test.pdf created for diagnostics");
#	$document1->content(' '); 
#	print Data::Dumper->Dump([$document1], ['$document1']); 
}

like ( $pdf, qr/^\%PDF/, 'pdf US2323935 received'  );
