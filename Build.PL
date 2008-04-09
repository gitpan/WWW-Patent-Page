use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
	module_name => 'WWW::Patent::Page',
	license     => 'perl',
	dist_author => 'Wanda B. Anon <Wanda_B_Anon@yahoo.com>',
	requires    => {
        'Carp' => 0, 
        'Data::Dumper' => 0, 
        'diagnostics'  => 0,
	'Archive::Zip' => 0,
	'base'=> 0,
	'subs'=> 0,
        'English'          => 0,
        'File::Temp'       => '0.17',
        'HTML::Form'    => 0,
        'HTML::HeadParser' => 0,
        'HTTP::Headers' => 0,
	'IO::Scalar'=> 0,	
        'HTML::TokeParser' => 0,
        'HTTP::Request'    => 0,
        'HTTP::Request::Common'    => 0,
        'HTTP::Response'   => 0,
        'LWP::UserAgent'   => '2.003',
        'PDF::API2'        => '0.52',
        'strict'  => 0, 
        'Test::More' => 0,
        'URI' => 0,
        'version'    => 0,
        'warnings'         => 0,
	},
)->create_build_script;
