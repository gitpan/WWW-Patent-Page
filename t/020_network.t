
use strict;
use warnings;
use Test::More tests => 1 ;
use LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  $ua->agent("$0/0.1 " . $ua->agent);
  # $ua->agent("Mozilla/8.0") # pretend we are very capable browser
 my $host = 'http://www.google.com/';

 $ua->env_proxy();

# print $ua->proxy();

  my $req = HTTP::Request->new(GET => $host);
  $req->header('Accept' => 'text/html');

  # send request
  my $res = $ua->request($req);

  # check the outcome
  #if ($res->is_success) {
 #  	$success = $res->is_success ;
 #    print $res->content, "\n \$res->is_success is '$success'\n";
 # } else {
 #    print "Error: " . $res->status_line . "\n";
 # }

if (exists($ENV{'http_proxy'})){
  ok ( $res->is_success , "network access. \$ENV{'http_proxy'} = '$ENV{'http_proxy'}'" );
}
else {ok ( $res->is_success , 'network access.' );}