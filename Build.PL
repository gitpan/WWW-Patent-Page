use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
	module_name => 'WWW::Patent::Page',
	license     => 'perl',
	requires    => {
		strict           => 0,
		diagnostics      => 0,
		LWP::UserAgent   => '2.003',
		warnings         => 0,
		PDF::API2        => 0,
		HTTP::Request    => 0,
		HTML::HeadParser => 0,
		HTML::TokeParser => 0,
		HTTP::Response   => 0,
	},
)->create_build_script;
