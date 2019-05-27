package ShinyCMS::Controller;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


use Captcha::reCAPTCHA;


our $valid_roles;


=head1 METHODS

=head2 user_exists_and_can

Check if a user is logged-in and has permission to take the specified action

=cut

sub user_exists_and_can {
	my ( $self, $c, $args ) = @_;

	my $action = $args->{ action };
	die 'Attempted authorisation check without action.' unless $action;

	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->flash( error_msg  => "You must be logged in to $action.");
		$c->go( '/admin/user/login' );
	}

	# Get role and check it is valid
	my $role = $args->{ role };
	die 'Attempted authorisation check without role.' unless $role;
	if ( $role ) {
		$self->_get_valid_roles( $c );
		die "Attempted authorisation check with invalid role ($role)." 
			unless $valid_roles->{ $role };
		# Bounce if user doesn't have appropriate role
		unless ( $c->user->has_role( $role ) ) {
			$c->flash( error_msg => "You do not have the ability to $action.");
			my $redirect = $args->{ redirect } || '/';
			$c->response->redirect( $c->uri_for( $redirect ) );
			return 0;
		}
	}
	return 1;
}


=head2 _get_valid_roles

Get a list of valid role names

=cut

sub _get_valid_roles {
	my $self = shift;
	my $c = shift;
	unless ( $valid_roles ) {
		my @roles    = $c->model('DB::Role')->all;
		$valid_roles = { map { $_->role => 1 } @roles };
	}
	return $valid_roles;
}


=head2 _recaptcha_result

Checks to see if a recaptcha submission is good.

=cut

sub _recaptcha_result {
	my( $self, $c ) = @_;
	
	my $rc = Captcha::reCAPTCHA->new;
	
	my $result = $rc->check_answer_v2(
		$c->config->{ 'recaptcha_private_key' },
		$c->request->param( 'g-recaptcha-response' ),
		$c->request->address,
	);
	
	return $result;
}



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
