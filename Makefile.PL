# IMPORTANT: if you delete this file your app will not work as expected.
use inc::Module::Install;

name 'ShinyCMS';
all_from 'lib/ShinyCMS.pm';

requires 'Catalyst::Runtime' => '5.80004';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::General';

requires (
	'Catalyst::Plugin::Authentication'           => '0',
	'Catalyst::Plugin::Session'                  => '0',
	'Catalyst::Plugin::Session::Store::DBIC'     => '0',
	'Catalyst::Plugin::Session::State::Cookie'   => '0',
	'Catalyst::Authentication::Realm::SimpleDB'  => '0',
	'Catalyst::View::TT'                         => '0',
	'Catalyst::View::Email'                      => '0',
	'Catalyst::TraitFor::Request::BrowserDetect' => '0',
	'CatalystX::RoleApplicator'                  => '0',
	'DBIx::Class::EncodedColumn'                 => '0',
	'DBIx::Class::Schema::Loader'                => '0',
	'DBIx::Class::TimeStamp'                     => '0',
	'Method::Signatures::Simple'                 => '0',
	'MooseX::NonMoose'                           => '0',
	'MooseX::MarkAsMethods'                      => '0',
	'XML::Feed'                                  => '0',
	'Captcha::reCAPTCHA'                         => '0',
	'HTML::Restrict'                             => '0',
	'Email::Sender'                              => '0.102360', # gets rid of -alias/-excludes warnings
	'Email::Valid'                               => '0',
	'Net::Domain::TLD'                           => '0',
	'Text::CSV::Simple'                          => '0',
	'File::Pid'                                  => '0',
);

recommends (
	'Template::Plugin::Markdown'                 => '0',
);

catalyst;

install_script glob( 'script/*.pl' );
auto_install;
WriteAll;

