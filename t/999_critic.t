use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not ($ENV{TEST_AUTHOR} eq 'Wanda_B_Anon' )) {
	my $msg = 'Author test only.  Set $ENV{TEST_AUTHOR} to "Wanda_B_Anon" to run.';
	plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ($EVAL_ERROR) {
	my $msg = 'Test::Perl::Critic required to criticise code';
	plan( skip_all => $msg );
}

plan (tests => 1 );
use Test::Perl::Critic (-severity => 2, -verbosity => 11 ,
    -exclude => ['RequireRcsKeywords', 'RequireFilenameMatchesPackage', 'RequireTidyCode','ProhibitExcessComplexity', 'ProhibitStringyEval']);
critic_ok('lib/WWW/Patent/Page.pm');  # critic_ok($file);  # try to eliminate the exceptions, but not bad, not bad

# http://search.cpan.org/~thaljef/Perl-Critic-1.01/lib/Perl/Critic/Policy/Subroutines/ProhibitExcessComplexity.pm
#
#
#