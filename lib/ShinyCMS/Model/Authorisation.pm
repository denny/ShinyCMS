package ShinyCMS::Model::Authorisation;

use Moose;
use namespace::clean -except => 'meta';

extends qw/ ShinyCMS::Model::Base /;


=head1 NAME

ShinyCMS::Model::Authorisation

=head1 SYNOPSIS

$c->model( 'Authorisation' )->user_exists_and_can({
	action   => 'edit a page', 
	role     => 'CMS Page Editor',
	redirect => '/some/path',
});

=head1 DESCRIPTION

Authorisation model class for ShinyCMS

=cut


=head1 METHODS

=head2 user_exists_and_can

=cut

my $valid_roles;
sub user_exists_and_can {
	my ( $self, $args ) = @_;
	my $c = $self->config->{ context };
	
	my $action = $args->{ action } or die 'Attempted authorisation check without action.';
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = "You must be logged in to $action.";
		$c->go( '/user/login' );
		return 0;
	}
	
	# Get role and check it is valid
	my $role = $args->{ role } or die 'Attempted authorisation check without role.';
	if ( $role ) {
		$self->_get_valid_roles;
		die "Attempted authorisation check with invalid role ($role)." unless $valid_roles->{ $role };
		# Bounce if user doesn't have appropriate role
		unless ( $c->user->has_role( $role ) ) {
			$c->stash->{ error_msg } = "You do not have the ability to $action.";
			my $redirect = $args->{ redirect } || '/';
			$c->response->redirect( $redirect );
			return 0;
		}
	}
	return 1;
}


sub _get_valid_roles {
	my $self = shift;
	unless ( $valid_roles ) {
		my $schema   = $self->config->{ schema };
		my @roles    = $schema->resultset( 'Role' )->all;
		$valid_roles = { map { $_->role => 1 } @roles };
	}
	return $valid_roles;
}



=head1 AUTHOR

Aaron Trevena

=head1 SEE ALSO

ShinyCMS::Model::Base

=cut

__PACKAGE__->meta->make_immutable;

1;

