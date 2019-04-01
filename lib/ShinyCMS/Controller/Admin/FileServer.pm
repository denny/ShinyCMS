package ShinyCMS::Controller::Admin::FileServer;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::FileServer

=head1 DESCRIPTION

Admin controller for ShinyCMS authenticated fileserving.

=cut


has display => (
	isa     => Int,
	is      => 'ro',
	default => 50,
);


=head1 METHODS

=cut


=head2 base

Set up the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/fileserver' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ controller } = 'Admin::FileServer';
}


=head2 list_files

List all files that have been accessed.

=cut

sub list_files : Chained( 'base' ) : PathPart( 'access-details' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'list all files that have been accessed', 
		role     => 'File Admin',
		redirect => '/admin'
	});
	
	# Stash the list of users
	$c->stash->{ files } = $c->model( 'DB::FileAccess' )->search(
		{},
		{
			columns  => [ 'filepath', 'filename' ],
			distinct => 1,
			order_by => { -desc => [ 'filepath', 'filename' ] },
		}
	);
}


=head2 view_access_details

View when a file has been accessed and by who.

=cut

sub view_access_details : Chained( 'base' ): PathPart( 'access-details' ) : Args() {
	my ( $self, $c, @file ) = @_;

	# Check admin privs
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view file access data', 
		role     => 'File Admin',
		redirect => '/admin',
	});

	my $filename = pop @file;
	my $filepath = join '/', @file;

	# Stash the access data for the specified file
	$c->stash->{ file_access } = $c->model( 'DB::FileAccess' )->search(
		{
			filepath => $filepath,
			filename => $filename,
		},
		{
			order_by => { -desc => 'created' }
		}
	);
	$c->stash->{ display } = $c->request->param( 'display' ) || $self->display;
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

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
