
package WWW::Patent::Page::ESPACE_EP;
use strict;
use warnings;
use diagnostics;
use Carp;
use subs
  qw( methods    ESPACE_EP_countries_available         ESPACE_EP_parse_doc_id         ESPACE_EP_pdf       ESPACE_EP_terms  );
use LWP::UserAgent 2.003;
require HTTP::Request;
use URI;

#use HTML::HeadParser;
#use HTML::TokeParser;
use HTML::Form;
use URI;

use vars qw/ $VERSION @ISA/;

$VERSION = "0.1";

sub methods {
    return (
        'ESPACE_EP_pdf'                 => \&ESPACE_EP_pdf,
        'ESPACE_EP_countries_available' => \&ESPACE_EP_countries_available,
        'ESPACE_EP_parse_doc_id'        => \&ESPACE_EP_parse_doc_id,
        'ESPACE_EP_terms'               => \&ESPACE_EP_terms,
    );

}

sub ESPACE_EP_countries_available {
    return (
        'AT' => 'from 1990',
        'BE' => 'from 1990',
        'BG' => 'from 2000',
        'CH' => 'from 1970',
        'CN' => 'from 1990',
        'CZ' => 'from 2000',
        'DE' => 'from 1970',
        'EP' => 'from begin',
        'ES' => 'from 1983',
        'FI' => 'from 1985',
        'FR' => 'from 1970',
        'GB' => 'from 1970',
        'GR' => 'from 1996',
        'IE' => 'from 1990',
        'IT' => 'from 1993',
        'JP' => 'from 1973',
        'KR' => 'from 1979',
        'LT' => 'from 2001',
        'LV' => 'from 1999',
        'MD' => 'from 2000',
        'NL' => 'from 1990',
        'NZ' => 'from 1999',
        'PT' => 'from 1990',
        'RO' => 'from 1999',
        'RU' => 'from 1998',
        'SE' => 'from 1990',
        'SI' => 'from 1998',
        'SK' => 'from 1993',
        'SU' => 'from 1998',
        'TW' => 'from 2000',
        'US' => 'from 1970',
        'WO' => 'from 1978',
    );
}

sub ESPACE_EP_parse_doc_id {
    my $self = shift @_;
    my $id = $self->{'patent'}->{'doc_id'} || carp "No document id to parse";
    if ( $id =~ s/^\s*(\D\D)//i ) {
        $self->{'patent'}->{'country'} = uc($1);
    }    # remove and upper case the country if found

#	if ($id =~ s/^(D|PP|RE|T|H)//i) { $self->{'patent'}->{'type'} = uc($1); } else { $self->{'patent'}->{'type'} = '' }
    if ( $id =~ s/^([,\-\d_]+)//i ) {    #required document identifier number
        $self->{'patent'}->{'number'} =
          $1;    # warn "NUMBER is $self->{'patent'}->{'number'} \n";
        $self->{'patent'}->{'number'} =~
          s/[,\-_]//g;    # warn "NUMBER is $self->{'patent'}->{'number'} \n";
    }
    else { carp "no documunt number in '$id'" }
    if ( $id =~ s/^\((\w+)\)//i ) {    #optional version number
        $self->{'patent'}->{'version'} = $1;
    }
    if ($id) { $self->{'patent'}->{'comment'} = $$id; }
    return $self;
}

sub ESPACE_EP_pdf {
    my ($self) = @_;
    my (
        $url, $request, $base, $zero_fill, $html,
        $response, $p, $referer
    );
    my $number = $self->{'patent'}{'number'};
#    print "patent number of interest is '$number'\n";
# Request: http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN=US6123456&Submit=SEARCH&=&=&=&=&= 
# Referer: http://ep.espacenet.com/search97cgi/s97_cgi.exe?Action=FormGen&Template=ep/en/number.hts

    $referer ="http://ep.espacenet.com/search97cgi/s97_cgi.exe?Action=FormGen&Template=ep/en/number.hts";
    $url = 'http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN='."$self->{'patent'}{'country'}$number".'&Submit=SEARCH&=&=&=&=&=';
    $request  = HTTP::Request->new( 'GET' => $url );
    $request->referer($referer);
    $response = $self->request($request);
    unless ($response->is_success) {carp "Request '$url' failed with status line '$response->status_line'.  Bummer.\n"; return (0)}
    $referer  = $url;
    $base     = $response->base;
    $html     = $response->content;
    if ($html =~ m/="(textdoc[^"]+$number[^"]*)/ ) {
   	$url = $1;
    	}
    else { carp "did not find the textdoc link in the javascript: $html\n"; exit;}
    $url = URI->new_abs($url,$base);
#    print "\nsearch result url of interest (from loop exit?): $url\n";
    $request = new HTTP::Request( 'GET' => "$url" )
      or carp "trouble with request object of '$url'";
    $request->referer($referer);
    $response = $self->request($request);    # go to the page of many choices of views
# send in the first returned hit (absoluted):
# Request for URL:  http://v3.espacenet.com/textdoc?DB=EPODOC&IDX=US6123456&F=0 
# INPUT: Referer: http://v3.espacenet.com/results?sf=n&FIRST=1&F=0&CY=ep&LG=en&DB=EPODOC&PN=US6123456&Submit=SEARCH&=&=&=&=&=
# Find the "origdoc" link
# <A class="bluedark" href="origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456" >Original document</A>
# in h331.html
unless ($response->is_success) {carp "Request '$url' failed with status line '$response->status_line'.  Bummer.\n"; return (0)}
    $referer = $url; # use later on next request
    $html = $response->content;
    $base = $response->base;
    if ($html =~ m/="(origdoc[^"]+$number[^"]+$number[^"]*)/ ) {
   	$url = $1;
    	}
    else { carp "did not find the original document link in the javascript: $html\n"; exit;}
    $url = URI->new_abs($url,$base);
#    print "\nusing origdoc, next url '$url'\n";
    $request = new HTTP::Request( 'GET' => "$url" )
      or carp "trouble with request object of '$url'";
    $request->referer($referer);
    $response = $self->request($request);    # get the page with the rotten PDF on it, "Original Document" link-to
# Request: http://v3.espacenet.com/origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456 
# Referer: http://v3.espacenet.com/textdoc?DB=EPODOC&IDX=US6123456&F=0
# Look for maximise link in h333.html
# <a href="#" onClick="openMax(); return false">Maximise</a>
# (hidden... you bad boys!) function openMax() {  var link ="pdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456".replace('pdfdoc','pdfdocnav');
# Request: http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456 
unless ($response->is_success) {carp "this request '$url' failed with status line '".$response->status_line."'.  Bummer.\n"; return (0)}
    $referer = $url;
    $html    = $response->content;
    $base    = $response->base;      # looking for that Maximize link...

    $url = '';
    if ( $html =~ m/"(pdfdoc[^'"]*$number[^"]*)/ ) {
        $url = $1;
        $url =~ s/pdfdoc\?/pdfdocnav?/;
    }
    else { carp "could not find 'pdfdoc' url in '$referer': \n$html"; exit }
    $url = URI->new_abs($url,$base); # should be the url of the navigation header above the pdf pages, supplies the number of pages
# print "going for the url from the maximise link: \n'$url'\n";
    $request = new HTTP::Request( 'GET' => "$url" )
      or carp "trouble with request object of '$url'";
    unless ($response->is_success) {carp "Request '$url' failed with status line '$response->status_line'.  Bummer.\n"; return (0)}
    $request->referer($referer);
    $response = $self->request($request);    # go to the navigation header
# Request: http://v3.espacenet.com/pdfdocnav?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456 
# Referer: http://v3.espacenet.com/origdoc?DB=EPODOC&IDX=US6123456&F=0&QPN=US6123456
# Look for link to PDF, in h336.html:
# 
# Request: http://v3.espacenet.com/simplepdfdoc?DB=EPODOC&IDX=US6123456&F=128&QPN=US6123456&PGN=1 

$referer  = $url;
    $html     = $response->content;
    $base     = $response->base;
#    print " from '$url', note html:\n$html\n";

    if ( $html =~ m|1/(\d+)| ) {
        $self->{'patent'}->{'pages_available'} = $1;
    }
    else {
        carp
"no maximum page number found in $self->{'patent'}{'country'}$number: \n$html";
    }
    if ( $html =~ m/"(simplepdfdoc[^'"]*$number[^"]*)/ ) {
        $url = $1;
    }
    else { carp "no first page PDF framing link to grab in: \n$html"; }

    $url =~ s/&PGN=\d+//i; # remove page number portion 
    $url = $url.'&PGN='.$self->{'patent'}{'page'};
    $url = URI->new_abs($url,$base); # should be the url of the navigation header above the pdf pages, supplies the number of pages
# print "url from navigation that points to pdf: \n'$url'\n";
    $request = new HTTP::Request( 'GET' => "$url" )
      or carp "trouble with request object of '$url'";
    $request->referer($referer);
    $response = $self->request($request);    # go to the navigation header
    unless ($response->is_success) {carp "Request '$url' failed with status line '".$response->status_line."'.  Bummer.\n"; exit}
# Eureka...
    $self->{'patent'}->{'as_string'} = $response->content;
    return $self;
}

sub ESPACE_EP_terms {
    my ($self) = @_;
    return (
        "The ep.espacenet.com web site is utilized.\n
Refer to that site for terms and conditions of use.
"
    );
}

1;
