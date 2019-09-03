package ShinyCMS;

use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

extends 'Catalyst';


=head1 NAME

ShinyCMS

=head1 SYNOPSIS

    script/shinycms_server.pl

=head1 DESCRIPTION

ShinyCMS is an open source CMS built in Perl using the Catalyst framework.

https://shinycms.org  /  https://www.perl.org  /  http://catalystframework.org

=cut


use Catalyst qw/
	ConfigLoader
	Static::Simple

	Authentication

	Session
	Session::Store::DBIC
	Session::State::Cookie
/;
use CatalystX::RoleApplicator;
use Method::Signatures::Simple;


our $VERSION = '19.9';
$VERSION = eval { $VERSION };


# Default config (anything set here can be overridden in config/shinycms.conf)
__PACKAGE__->config(
	name => 'ShinyCMS',
	# Load config file
	'Plugin::ConfigLoader' => {
		file   => 'config/shinycms.conf',
		driver => {
			'General' => { -InterPolateVars => 1 },
		},
	},
	# Configure DB sessions
	'Plugin::Session' => {
		dbic_class => 'DB::Session',
		expires    => 3600,
		# Stick the flash in the stash
		flash_to_stash => 1,
	},
    # Configure SimpleDB Authentication
    'Plugin::Authentication' => {
			default => {
			class           => 'SimpleDB',
			user_model      => 'DB::User',
			password_type   => 'self_check',
			use_userdata_from_session => 1,
		},
    },
	# Disable deprecated behaviour needed by old Catalyst applications
	disable_component_resolution_regex_fallback => 1,
);

# Pick up test config overrides if SHINYCMS_TEST env var is set
__PACKAGE__->config->{ 'Plugin::ConfigLoader' }
	->{ config_local_suffix } = 'test' if $ENV{ SHINYCMS_TEST };


# Set cookie domain to be wildcard (so it works on sub-domains too)
method finalize_config {
	__PACKAGE__->config(
		session => { cookie_domain => '.'.$self->config->{ domain } }
	);
	$self->next::method( @_ );
};

# Load browser detection trait (for detecting mobiles)
__PACKAGE__->apply_request_class_roles(
	'Catalyst::TraitFor::Request::BrowserDetect'
);


# Start the application
__PACKAGE__->setup;



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
