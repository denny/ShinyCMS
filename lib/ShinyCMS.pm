package ShinyCMS;

use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

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

extends 'Catalyst';


our $VERSION = '0.007';
$VERSION = eval $VERSION;


# Configure the application.
#
# Note that settings in shinycms.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
	name => 'ShinyCMS',
	# Configure DB sessions
	'Plugin::Session' => {
		dbic_class => 'DB::Session',
		expires    => 3600,
		# Stick the flash in the stash
		flash_to_stash => 1,
	},
	# Disable deprecated behaviour needed by old Catalyst applications
	disable_component_resolution_regex_fallback => 1,
);


# Configure SimpleDB Authentication
__PACKAGE__->config->{ 'Plugin::Authentication' } = {
	default => {
		class           => 'SimpleDB',
		user_model      => 'DB::User',
		password_type   => 'self_check',
		use_userdata_from_session => 1,
	},
};


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



=head1 NAME

ShinyCMS

=head1 SYNOPSIS

    script/shinycms_server.pl

=head1 DESCRIPTION

ShinyCMS is an open source CMS built in Perl using the Catalyst framework.

http://shinycms.org

http://catalystframework.org


=head1 SEE ALSO

L<ShinyCMS::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

1;

