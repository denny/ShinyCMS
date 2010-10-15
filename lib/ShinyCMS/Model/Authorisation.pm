package ShinyCMS::Model::Authorisation;
use strict;
use warnings;

=head1 NAME

ShinyCMS::Model::Authorisation - Authorisation for ShinyCMS

=head1 SYNOPSIS

$c->model('Authorisation')->user_exists_and_can({action => 'edit a CMS Page', role=>'CMS Page Admin', redirect => '/some/path');

=head1 DESCRIPTION

Authorisation model class for ShinyCMS

=cut

use base qw(ShinyCMS::Model::Base);

=head1 METHODS

=head2 user_exists_and_can

=cut

my $valid_roles;
sub user_exists_and_can {
    my ($self,$args) = @_;
    my $c = $self->config->{context};

    my $action = $args->{action} or die 'check user rights requires an action';
    # Bounce if user isn't logged in
    unless ( $c->user_exists ) {
	$c->stash->{ error_msg } = "You must be logged in to $action.";
	$c->go( '/user/login' );
	return 0;
    }

    # get role and check is valid
    my $role = $args->{role};
    if ($role) {
	$self->_get_valid_roles();
	die "role $role not found, must be invalid!\n" unless ($valid_roles->{$role});
	# Bounce if user doesn't have appropriate role
	unless ( $c->user->has_role( 'CMS Page Editor' ) ) {
	    $c->stash->{ error_msg } = 'You do not have the ability to edit CMS pages.';
	    my $redirect = $args->{redirect} || '/';
	    $c->response->redirect( $redirect );
	    return 0;
	}
    }
    return 1;

}

sub _get_valid_roles {
    my $self = shift;
    unless ( $valid_roles ) {
	my $schema = $self->config->{schema};
	my @roles = $schema->resultset( 'Roles' )->all;
	$valid_roles = { map { $_->role } @roles };
    }
}



=head1 AUTHOR

Aaron Trevena

=head1 SEE ALSO

ShinyCMS::Model::Base

=cut

1;

