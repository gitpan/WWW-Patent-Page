use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Patent::Page',
    VERSION_FROM => 'lib/WWW/Patent/Page.pm', # finds $VERSION
    AUTHOR       => 'Wanda B. Anon (Wanda_B_Anon@yahoo.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
