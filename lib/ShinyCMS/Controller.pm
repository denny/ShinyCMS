package ShinyCMS::Controller;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


use Captcha::reCAPTCHA;


our $valid_roles;


=head2 user_exists_and_can

Check if a user is logged-in and has permission to take the specified action

=cut

sub user_exists_and_can {
    my ( $self, $c, $args ) = @_;

    my $action = $args->{ action } or die 'Attempted authorisation check without action.';

    # Bounce if user isn't logged in
    unless ( $c->user_exists ) {
        $c->stash( error_msg  => "You must be logged in to $action.");
        $c->go( '/admin', 'user', 'login' );
        return 0;
    }

    # Get role and check it is valid
    my $role = $args->{ role } or die 'Attempted authorisation check without role.';
    if ( $role ) {
        $self->_get_valid_roles( $c );
        die "Attempted authorisation check with invalid role ($role)." 
        	unless $valid_roles->{ $role };
        # Bounce if user doesn't have appropriate role
        unless ( $c->user->has_role( $role ) ) {
            # FIXME - How does this work through redirect?!?
            $c->stash( error_msg => "You do not have the ability to $action.");
            my $redirect = $args->{ redirect } || '/';
            $c->response->redirect( $redirect );
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
	
	my $result = $rc->check_answer(
#		$c->stash->{ 'recaptcha_private_key' }, # TODO: not working in autoresponder subscription flow! ??
		$c->config->{ 'recaptcha_private_key' },
		$c->request->address,
		$c->request->param( 'recaptcha_challenge_field' ),
		$c->request->param( 'recaptcha_response_field'  ),
	);
	
	return $result;
}



=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2014 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

