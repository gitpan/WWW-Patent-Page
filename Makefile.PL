use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Patent::Page',
    AUTHOR              => 'Wanda B. Anon <Wanda_B_Anon@yahoo.com>',
    VERSION_FROM        => 'lib/WWW/Patent/Page.pm',
    ABSTRACT_FROM       => 'lib/WWW/Patent/Page.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0, 
        'Data::Dumper' => 0, 
        'diagnostics'  => 0, 
        'English'          => 0,
        'File::Temp'       => '0.17',
        'HTML::Form'    => 0,
        'HTML::HeadParser' => 0,
        'HTML::TokeParser' => 0,
        'HTTP::Request'    => 0,
        'HTTP::Request::Common'    => 0,
        'HTTP::Response'   => 0,
        'LWP::UserAgent'   => '2.003',
        'PDF::API2'        => '2.00',
        'strict'  => 0, 
        'Test::More' => 0,
        'URI' => 0,
        'version'    => 0,
        'warnings'         => 0,
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
 #   clean               => { FILES => 'WWW-Patent-Page-*' },
);