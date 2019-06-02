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


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);


=head1 METHODS

=head2 base

Set up the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/fileserver' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'view file access logs',
		role     => 'Fileserver Admin',
		redirect => '/admin'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'FileServer';
}


=head2 index

Display list of all access-controlled files

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_files' );
}


=head2 list_files_in_path

List all restricted files with the specified path that have access log data.

=cut

sub list_files_in_path : Chained( 'base' ) : PathPart( 'access-logs' ) : Args( 1 ) {
	my ( $self, $c, $filepath ) = @_;

	# Stash the path and the list of files
	$c->stash->{ filepath } = $filepath;
	$c->stash->{ files    } = $c->model( 'DB::FileAccess' )->search(
		{
			filepath => $filepath,
		},
		{
			columns  => [ 'filepath', 'filename' ],
			distinct => 1,
			order_by => [ 'filepath', 'filename' ],
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
	$c->stash->{ template } = 'admin/fileserver/list_files.tt';
}


=head2 list_files

List all restricted access files that have access log data.

=cut

sub list_files : Chained( 'base' ) : PathPart( 'access-logs' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of files
	$c->stash->{ files } = $c->model( 'DB::FileAccess' )->search(
		{},
		{
			columns  => [ 'filepath', 'filename' ],
			distinct => 1,
			order_by => [ 'filepath', 'filename' ],
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
}


=head2 view_access_logs

View when a file has been accessed and by who.

=cut

sub view_access_logs : Chained( 'base' ): PathPart( 'access-logs' ) : Args( 2 ) {
	my ( $self, $c, $filepath, $filename ) = @_;

	# Stash the access data for the specified file
	$c->stash->{ access_logs } = $c->model( 'DB::FileAccess' )->search(
		{
			filepath => $filepath,
			filename => $filename,
		},
		{
			order_by => { -desc => 'created' },
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
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
