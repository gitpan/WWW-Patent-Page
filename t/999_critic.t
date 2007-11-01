use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not exists( $ENV{TEST_AUTHOR} )
	or ( not( $ENV{TEST_AUTHOR} eq 'Wanda_B_Anon' ) ) )
{
	my $msg
		= 'Author test only.  Set $ENV{TEST_AUTHOR} to "Wanda_B_Anon" to run.';
	plan( skip_all => $msg );
}

eval { require Test::Perl::Critic };
if ($EVAL_ERROR) {
	my $msg = "Test::Perl::Critic required to criticise code: $EVAL_ERROR $@". join "\n" , ' ', @INC ;
	plan( skip_all => $msg );
	exit;
}

plan( tests => 1 );

#$Perl::Critic::Violation::FORMAT = 1; 
#$Perl::Critic::Violation::FORMAT = "%m at line %l. %e. \n%d\n";

Test::Perl::Critic->import(
	-severity  => '2',
	-verbosity => '10',
	-exclude   => [
		'RequireRcsKeywords', 'RequireFilenameMatchesPackage',
		'RequireTidyCode',    'ProhibitExcessComplexity',
		'ProhibitStringyEval', 'RequireArgUnpacking' ,
	]
);


#critic_ok('P:/workspace/WWW-Patent-Page/lib/WWW/Patent/Page.pm');
#critic_ok('lib/WWW/Patent/Page/MICROPATENT.pm');
critic_ok('lib/WWW/Patent/Page.pm');
