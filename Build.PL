use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
	module_name => 'WWW::Patent::Page',
	license     => 'perl',
	dist_author => 'Wanda B. Anon <Wanda_B_Anon@yahoo.com>',
	requires    => {
        'Test::More' => 0,
        'version'    => 0,
        'strict'  => 0, 
        'Carp' => 0, 
        'diagnostics' => 0, 
        'Data::Dumper' => 0, 
        'English'          => 0,
        'LWP::UserAgent'   => '2.003',
        'warnings'         => 0,
        'PDF::API2'        => '2.00',
        'File::Temp'       => '0.17',
        'HTTP::Request'    => 0,
        'HTTP::Request::Common'    => 0,
        'HTML::Form'    => 0,
        'HTML::HeadParser' => 0,
        'HTML::TokeParser' => 0,
        'HTTP::Response'   => 0,
        'URI' => 0,
	},
)->create_build_script;
