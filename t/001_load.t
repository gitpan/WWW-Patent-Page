# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WWW::Patent::Page' ); }

my $object = WWW::Patent::Page->new ();
isa_ok ($object, 'WWW::Patent::Page');


