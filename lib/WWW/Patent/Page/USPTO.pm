
package WWW::Patent::Page::USPTO;
use strict;
use warnings;
use diagnostics;
use Carp;
use subs qw( methods USPTO_countries_available USPTO_parse_doc_id USPTO_htm USPTO_tif USPTO_terms  );
use LWP::UserAgent 2.003;
require HTTP::Request;
use HTML::HeadParser;
use HTML::TokeParser;



use vars qw/ $VERSION @ISA/;

$VERSION = "0.1";

sub methods {
	return ('USPTO_htm'	=> \&USPTO_htm ,
		'USPTO_tif'	=> \&USPTO_tif ,
		'USPTO_countries_available' => \&USPTO_countries_available ,
		'USPTO_parse_doc_id' => \&USPTO_parse_doc_id ,
		'USPTO_terms'	=> \&USPTO_terms ,
	);	

}

sub USPTO_countries_available{ 
	my $self = shift @_;
	return  ('US' => '1790 on' , ) 
} 

sub USPTO_parse_doc_id{ 
#	Utility: 5,146,634
#	Design: D339,456
#	Plant: PP8,901
#	Reissue: RE35,312
#	Def. Pub.: T109,201
#	SIR: H1,523
	my $self = shift @_;
	my $id = $self->{'patent'}->{'doc_id'} || carp "No document id to parse" ;
	$id =~ s/^US//i; # strip leading US- only choice at USPTO!
	if ($id =~ s/^(D|PP|RE|T|H)//i) { $self->{'patent'}->{'type'} = uc($1); } else { $self->{'patent'}->{'type'} = '' }
	if ($id =~ s/^([,\-\d_]+)//i) {  #required document identifier number 
		$self->{'patent'}->{'number'} = $1; # warn "NUMBER is $self->{'patent'}->{'number'} \n";
		$self->{'patent'}->{'number'} =~ s/[,\-_]//g ; # warn "NUMBER is $self->{'patent'}->{'number'} \n";
		# kludge to put commas into T publications...
		if (exists($self->{'patent'}->{'type'}) && $self->{'patent'}->{'type'} eq 'T') {
			my $text = reverse $self->{'patent'}->{'number'};
			$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
			$self->{'patent'}->{'number'} = scalar reverse $text;
		}
			
	} 
	else {carp "no documunt number in '$id'"}
	if ($id =~ s/^\((\w+)\)//i) {  #optional version number
		$self->{'patent'}->{'version'} = $1;
	} 
	if ($id) {$self->{'patent'}->{'comment'} = $$id;}
	return $self; 		  		
}

sub USPTO_htm {
	my ($self) = @_;
	my $request; my $request_text;
	if ( (!$self->{'patent'}->{'type'}) && (length($self->{'patent'}{'number'}) == 11) ) {
		# Application  (11 digits)
		$request_text = 'http://appft1.uspto.gov/netacgi/nph-Parser?TERM1='.$self->{'patent'}{'number'}.'&Sect1=PTO1&Sect2=HITOFF&d=PG01&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.html&r=0&f=S&l=50';
		$request = HTTP::Request->new('GET' => $request_text );
		my $intermediate = $self->request($request);
		my $p = HTML::TokeParser->new(\$intermediate->content);
		while (my $token = $p->get_tag("a")) {
			my $url = $token->[1]{href} || "-";
			my $text = $p->get_trimmed_text("/a");
			if ( ($url =~ m/$self->{'patent'}{'number'}/)  && ($text =~  m/$self->{'patent'}{'number'}/)) {
				#warn "fully qualified? '$url'\n";
				$request_text = 'http://appft1.uspto.gov/'.$url ;
				$request = HTTP::Request->new('GET' =>  $request_text );
			}
		}
	}
#http://appft1.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PG01&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.html&r=1&f=G&l=50&s1=%2220010000044%22.PGNR.&OS=DN/20010000044&RS=DN/20010000044
	elsif ($self->{'patent'}->{'type'}) {
		# Non-Utility Patent
		$request_text =  "http://patft.uspto.gov/netacgi/nph-Parser?patentnumber=$self->{'patent'}->{'type'}$self->{'patent'}{'number'}";
		$request = HTTP::Request->new('GET' => $request_text );
	}
	else {
		#Standard Utility Patent
		$request_text = "http://patft.uspto.gov/netacgi/nph-Parser?patentnumber=$self->{'patent'}{'number'}";
		$request = HTTP::Request->new('GET' => $request_text );
	}	
	# print "\nAlmost $self->{'retrieved_identifier'}->{'number'} \n";
	my $response = $self->request($request); # use the agent to make the request and get the response
	# print "\there\n";
	if ($response->is_success) {
	my $html = $response->content ;
	# print "\n$html\n";
	my $p = HTML::HeadParser->new; 
	$p->parse($response->content);
	my $entry;
	if (  $entry = $p->header('Refresh') ) { # carp "no refresh seen via '$self->{'patent'}{'number'}' in \n'$html' " }
		$entry =~ s/^.*?URL=//;
		$entry = 'http://patft.uspto.gov'.$entry;
		# print "$entry\n";
		$request = new HTTP::Request('GET' => "$entry") or carp "bad refresh";
		$response = $self->request($request);
		$html = $response->content ;
	}
	unless ($html =~ s/.*?<html>.*?<head>/<html>\n<head><!-- Modified by perl module WWW::Patent::Page from information provided by http:\/\/www.uspto.gov ; dedicated to public ; use at own risk -->\n<title>US /is) {carp "header weird A \n"} 
	unless ($html =~ s/<head>.*(<title>)\D+/<head><!-- Modified by perl module WWW::Patent::Page from information provided by http:\/\/www.uspto.gov ; dedicated to public ; use at own risk -->\n<title>US /is) {carp "header weird B \n"} 
	unless ($html =~ s/<title>\D+/<title>US /is) {carp "header weird C \n$html\n"} 
	#warn " type is $self->{'patent'}->{'type'}'\n";
	unless ($html =~ s/<body.*?<hr>/<body><HR>/is) {carp "front weird  \n$html\n"} 
	unless ($html =~ s/(.*)<hr>(.*)body>/$1<\/body>/is) {carp "end weird  \n$html\n"} 
	$html =~ s|"/netacgi/nph-Parser|"http://patft.uspto.gov/netacgi/nph-Parser|gi;
	$self->{'patent'}->{'as_string'} = $html ;
	return $self;
	}
	else {
		carp "Unsucessful response: \n'".$response->status_line."'\n\nfrom request:\n'$request_text'\n";
		return $self;
	}
}

sub USPTO_tif{
	my ($self) = @_;
	my ($request,$base,$zero_fill);
#  Direct access to the full-page image database is now
#  permitted without first conducting a search on the full-text database. Such
#  access is now possible by using a URL of the form:
#  http://patimg1.uspto.gov/.piw?Docid=0nnnnnnn&idkey=NONE
#  or
#  http://patimg2.uspto.gov/.piw?Docid=0nnnnnnn&idkey=NONE
#  where "nnnnnnn" is the seven-digit patent number (right-justified with
#  leading zeroes). The first URL, to patimg1.uspto.gov, is used if the patent
#  number's last two (low-order) digits are in the range 00 to 49; the first
#    URL, to patimg2.uspto.gov, is used if the patent number's last two digits
#  are in the range 50 to 99

# http://patimg2.uspto.gov/.piw?Docid=D0339456&idkey=NONE
# http://patimg2.uspto.gov/.DImg?Docid=US0PP008899&PageNum=1&IDKey=920747D732D2&ImgFormat=tif
# $request = new HTTP::Request('GET' => "http://patft.uspto.gov/netacgi/nph-Parser?TERM1=PP8%2C899&Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2Fsrchnum.htm&r=0&f=S&l=50");
# $request = new HTTP::Request('GET' => "http://patimg1.uspto.gov/.DImg?Docid=US0PP008901&PageNum=2&IDKey=8C4FEBE740CB&ImgFormat=tif");

# Referer: http://patft.uspto.gov/netahtml/srchnum.htm
# Request: http://patft.uspto.gov/netacgi/nph-Parser?TERM1=PP8%2C901&Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2Fsrchnum.htm&r=0&f=S&l=50 
# Request: http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=/netahtml/srchnum.htm&r=1&f=G&l=50&s1=PP8,901.WKU.&OS=PN/PP8,901&RS=PN/PP8,901 
# Request: http://patimg1.uspto.gov/.piw?Docid=PP008901&homeurl=http%3A%2F%2Fpatft.uspto.gov%2Fnetacgi%2Fnph-Parser%3FSect1%3DPTO1%2526Sect2%3DHITOFF%2526d%3DPALL%2526p%3D1%2526u%3D%2Fnetahtml%2Fsrchnum.htm%2526r%3D1%2526f%3DG%2526l%3D50%2526s1%3DPP8,901.WKU.%2526OS%3DPN%2FPP8,901%2526RS%3DPN%2FPP8,901&PageNum=&Rtype=&SectionNum=&idkey=8C4FEBE740CB 
# Request: http://patimg1.uspto.gov/.DImg?Docid=US0PP008901&PageNum=1&IDKey=8C4FEBE740CB&ImgFormat=tif 
# page 2
# Request: http://patimg1.uspto.gov/.piw?docid=US0PP008901&PageNum=2&IDKey=8C4FEBE740CB&HomeUrl=http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1%2526Sect2=HITOFF%2526d=PALL%2526p=1%2526u=/netahtml/srchnum.htm%2526r=1%2526f=G%2526l=50%2526s1=PP8,901.WKU.%2526OS=PN/PP8,901%2526RS=PN/PP8,901 
# Request: http://patimg1.uspto.gov/.DImg?Docid=US0PP008901&PageNum=2&IDKey=8C4FEBE740CB&ImgFormat=tif 
# page 3
# Request: http://patimg1.uspto.gov/.piw?docid=US0PP008901&PageNum=3&IDKey=8C4FEBE740CB&HomeUrl=http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1%2526Sect2=HITOFF%2526d=PALL%2526p=1%2526u=/netahtml/srchnum.htm%2526r=1%2526f=G%2526l=50%2526s1=PP8,901.WKU.%2526OS=PN/PP8,901%2526RS=PN/PP8,901 
# Request: http://patimg1.uspto.gov/.DImg?Docid=US0PP008901&PageNum=3&IDKey=8C4FEBE740CB&ImgFormat=tif 


	if ($self->{'patent'}{'number'} =~ m/(0|1|2|3|4)\d$/) {
		# 0-4 is on one server, 5-9 is on another
		$base = 'patimg1.uspto.gov';
	}
	else {$base = 'patimg2.uspto.gov';}
	my $zerofill = sprintf '%0.8u',$self->{'patent'}{'number'};
	if ($self->{'patent'}->{'type'}) {
		$request = HTTP::Request->new('GET' => "http://$base/.piw?Docid=$self->{'patent'}->{'type'}$zerofill\&idkey=NONE");
	}
	else {
		$request = HTTP::Request->new('GET' => "http://$base/.piw?Docid=$zerofill\&idkey=NONE");
	}	
	# print "\nAlmost $self->{'retrieved_identifier'}->{'number'} \n";
	my $response = $self->request($request);
	# print "\there\n";
	my $html = $response->content ;
	# print "\n$html\n";
	
	{ # page numbers
#		if ($html =~ m/PageNum=(\d+)/) {
#			$self->{'patent'}->{'page'} = $1;
#		}
		if ($html =~ m/NumPages=(\d+)/) {
			$self->{'patent'}->{'pages_available'} = $1;
		}
		elsif ($html =~ m/(\d+)\s+of\s+(\d+)\s+pages/) {
			$self->{'patent'}->{'pages_available'} = $2;		
		}
		else {carp "no maximum page number found in $self->{'patent'}{'country'}$self->{'patent'}{'number'}: \n$html";}
	}
	my $p = HTML::TokeParser->new( \$html );
	my $url;
	FINDPAGE: while (my $token = $p->get_tag("a")) {
             $url = $token->[1]{href} || "-";
             if ($url =~ m/$self->{'patent'}{'number'}/ ) {last FINDPAGE;}
             # print "$url\n";
         }
	 #warn "URL = '$url'\n";
	 $url =~ s/PageNum=(\d+)/PageNum=$self->{'patent'}{'page'}/;
	 $url ="http://$base$url";
	 #warn "URL = '$url'\n";
#	 exit;
	$request = new HTTP::Request('GET' => "$url") or carp "bad numbered page $self->{'patent'}{'page'} fetch $url";
	$response = $self->request($request);
	$self->{'patent'}->{'as_string'} = $response->content ;
	return $self;		
}

sub USPTO_terms{
	my ($self) = @_;
	return ("us.pm utilizes the USPTO web site.\n
Refer to http://www.USPTO.gov for terms and conditions of use of that site.
	
Note that as of September 1, 2004, 
http://www.uspto.gov/patft/help/notices.htm and the like state in part:

These databases are intended for use by the general public. 
Due to limitations of equipment and bandwidth, they are not 
intended to be a source for bulk downloads of USPTO data. 
Bulk data may be purchased from USPTO at cost (see the USPTO 
Products and Services Catalog). Individuals, companies, 
IP addresses, or blocks of IP addresses who, in effect, 
deny service to the general public by generating unusually 
high numbers (1000 or more) of daily database accesses 
(searches, pages, or hits), whether generated manually or 
in an automated fashion, may be denied access to these 
servers without notice.

Note at http://www.uspto.gov/patft/help/accpat.htm :

If you can access the main PTO Web site, but cannot access any 
of the Patent Grant Database Quick Search, Advanced Quick Searching, 
or Patent Number Searching pages, your workstation or organization 
may have been denied access to the Web Patent Databases pursuant 
to the policy stated at the top of this page. To determine if you 
have been denied access, you can check the Denied List for your 
computer's IP address. http://www.uspto.gov/patft/help/denied.htm

(Your IP address is the only means by which you are known to the 
PTO servers -- server logs do not contain your email address or 
any other personal identifying information. If you do not know 
your computer's IP address because you are behind a firewall, do 
not have a fixed IP address, or for any other reason, you can find 
your current IP address by using an 'IP reflector,' such as 
http://www2.simflex.com/ip.shtml or http://www.dslreports.com/ip.)

If you are an individual whose individual IP address has been 
denied access: to seek to have your access restored, please send 
email including your workstation and firewall or gateway IP addresses 
(consult with your network administrators if necessary), and describing 
the steps you have taken or will take to insure that future violations 
of the USPTO access policy will not occur, to the Database Help Desk at 
www\@uspto.gov.

If you are a member or employee of an organization which has been 
denied access: please do not send individual email to PTO. Instead, 
please have your network administrator or a person holding authority 
over your organization\'s network operations send email including your 
firewall, gateway, or workstation IP addresses, and describing the steps 
you have taken or will take to insure that future violations of the USPTO 
access policy will not occur, to the Database Help Desk at www\@uspto.gov.

For all other content-related matters, please send email to the Database 
Help Desk at www\@uspto.gov

Note at http://www.uspto.gov/patft/help/images.htm

Patent images must  be retrieved from the database one page at a time. 
This is necessary since patents can be as long as 5,000 pages, and the 
resources required to allow downloading such 'jumbo' patents are not 
available. Users employing third-party software which downloads multiple 
pages of a patent at once may find this practice subjects them to denial 
of access to the databases if they exceed PTO's maximum allowable 
activity levels.

" );
}


1;