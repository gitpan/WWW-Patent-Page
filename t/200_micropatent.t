# -*- perl -*-

# t/200.t - test micropatent
$| = 1;
use Carp;
use warnings;
use diagnostics;

use Test::More tests => 9;
BEGIN { use_ok('WWW::Patent::Page'); }

my $patent_document = WWW::Patent::Page->new();    # new object
isa_ok( $patent_document, 'WWW::Patent::Page' );

#login to Micropatent?

$patent_document->{patent}->{office}= "MICROPATENT";
$patent_document->{patent}->{office_username}= "YourUserName";
$patent_document->{patent}->{office_password}= "YourPassword";
#$patent_document->{patent}->{office_username}= "YourUserName";
#$patent_document->{patent}->{office_password}= "YourPassword";

#print join "\n" , @INC ;

SKIP: {
	skip "No MicroPatent USERNAME and PASSWORD supplied", 7 unless ( ($patent_document->{patent}->{office_username} ne "YourUserName") || ($patent_document->{patent}->{office_password} ne "YourPassword") ) ;
$patent_document->login() ;
like ($patent_document->{'patent'}->{'session_token'}, qr/\d+/, "session id a number: '$patent_document->{'patent'}->{'session_token'}'");  # /
like ($patent_document->{'patent'}{'session_token'}, qr/\d+/, "\$patent_document->{'patent'}{'session_token'} session id a number: '$patent_document->{'patent'}{'session_token'}");  # /
#like ($patent_document{'patent'}{'session_token'}, qr/\d+/, 'session id a number');  # /
#like ($patent_document->'MICROPATENT_session', qr/\d+/, 'session id a number');

my $session_id = $patent_document->{'patent'}{'session_token'};

# print "session_id = '$session_id' $patent_document->{'patent'}->{'session_token'} $patent_document->{'patent'}{'session_token'} " ;

$patent_document->{'patent'}{'session_token'} = '';

my $document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'xml',
	'page'    => '',                              # typically xml IS "1" page
);

# print join "\n" , keys %{$document1} ;


like ( $document1->{'message'}, qr/login token not available/ , "no token, no session" ) ;  # /

# ok ( exists($document1->{'is_success'}) && !defined($document1->{'is_success'})  , 'status blank when login token not available' );

$patent_document->{'patent'}->{'session_token'} = $session_id; # don't try this at home, kids

$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'xml',
	'page'    => '',                              # typically xml IS "1" page
);


# print $patent_document->{'message'};
like ( $document1->content, qr/Anti-contamination device for use in operating theatres/, 'xml bears correct title of US4299215'  );

$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'html',
	'page'    => '',                              # typically xml IS "1" page
);


#print join ("\n" , keys %$document1 ) ;


#for my $r (keys %$document1 ){
#print "$r => $document1->{$r}\n";
#}

like ( $document1->content, qr/ANTI-CONTAMINATION DEVICE FOR USE IN OPERATING THEATRES/, 'html bears correct title of US4299215'  );


$document1 = $patent_document->get_page(
	'4,299,215',                                   #4,299,215
	'office'  => 'MICROPATENT',
	'country' => 'US',
	'format'  => 'pdf',
	'page'    => '',                              # typically xml IS "1" page
);


# print join ("\n" , keys %$document1 ) ;


#for my $r (keys %$document1 ){
#print "$r => $document1->{$r}\n";
#}

like ( $document1->content, qr/Description/, 'pdf US4299215 has a bookmark to Description'  );

}
