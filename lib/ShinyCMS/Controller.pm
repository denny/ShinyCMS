package ShinyCMS::Controller;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub user_exists_and_can {
    my ( $self, $ctx, $args ) = @_;

    my $action = $args->{ action } or die 'Attempted authorisation check without action.';

    # Bounce if user isn't logged in
    unless ( $ctx->user_exists ) {
        $ctx->stash( error_msg  => "You must be logged in to $action.");
        $ctx->go( '/admin', 'user', 'login' );
        return 0;
    }

    # Get role and check it is valid
    my $role = $args->{ role } or die 'Attempted authorisation check without role.';
    if ( $role ) {
        $self->_get_valid_roles($ctx);
        die "Attempted authorisation check with invalid role ($role)." unless $valid_roles->{ $role };
        # Bounce if user doesn't have appropriate role
        unless ( $ctx->user->has_role( $role ) ) {
            # FIXME - How does this work through redirect?!?
            $c->stash( error_msg  =>  "You do not have the ability to $action.");
            my $redirect = $args->{ redirect } || '/';
            $c->response->redirect( $redirect );
            return 0;
        }
    }
    return 1;
}
sub _get_valid_roles {
    my $self = shift;
    my $ctx = shift;
    unless ( $valid_roles ) {
        my @roles    = $ctx->model('DB::Role')->all;
        $valid_roles = { map { $_->role => 1 } @roles };
    }
    return $valid_roles;
}

__PACKAGE__->meta->make_immutable;
1;

