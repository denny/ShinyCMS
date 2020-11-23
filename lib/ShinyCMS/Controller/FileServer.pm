package ShinyCMS::Controller::FileServer;

use Moose;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use MIME::Types;
use MIME::Type;


=head1 NAME

ShinyCMS::Controller::FileServer

=head1 DESCRIPTION

Controller for ShinyCMS authenticated fileserving.

=cut


has download_limit_minutes => (
	isa     => Int,
	is      => 'ro',
	default => 5,
);

has download_limit_files => (
	isa     => Int,
	is      => 'ro',
	default => 0,
);

has log_thumbnails => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);



=head1 METHODS

=head2 base

Set up the base path

=cut

sub base : Chained( '/base' ) : PathPart( 'fileserver' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ controller } = 'FileServer';
}


=head2 index

Catch people munging paths by hand and redirect them to site homepage

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->response->redirect( $c->uri_for( '/' ) );
}


=head2 serve_file

Serve a file, after checking user has rights to view it

=cut

sub serve_file : Chained( 'base' ) : PathPart( 'auth' ) : Args {
	my ( $self, $c, $access, @pathparts ) = @_;

	# Serve nothing if the user doesn't have the required access
	unless ( $c->user_exists and $c->user->has_access( $access ) ) {
		$c->response->code( '403' );
		$c->response->body( 'You do not have permission to access this file.' );
		$c->detach;
	}

	# Check if a simultaneous download limit is set, enforce it if it is
	if ( $self->download_limit_files ) {
		my $dtf = $c->model( 'DB' )->schema->storage->datetime_parser;
		my $check_from = DateTime->now->subtract( minutes => $self->download_limit_minutes );
		my $formatted = $dtf->format_datetime( $check_from );
		my $recent_downloads = $c->user->file_accesses->search({
			created => { '>=' => $formatted }
		})->count;

		if ( $recent_downloads >= $self->download_limit_files ) {
			$c->response->code( '429' );
			$c->response->body( 'Too many simultaneous downloads - please wait before trying again.' );
			$c->detach;
		}
	}

	# Check they have the required access, stop here if they don't
	my $file = $c->path_to( 'root', 'restricted-files', $access, @pathparts );
	unless ( -e $file ) {
		$c->response->code( '404' );
		$c->response->body( 'File not found.' );
		$c->detach;
	}

	# Log the file access in the database
	# (unless it's a thumbnail and we're skipping them)
	my $filename = pop @pathparts;
	if ( $self->log_thumbnails eq 'Yes' or $filename !~ m/_thumb\.\w{3,4}$/i ) {
		my $filepath = join '/', @pathparts;
		$c->user->file_accesses->create({
			access_group => $access,
			filepath     => $filepath,
			filename     => $filename,
			ip_address   => $c->request->address,
		});
	}

	# Serve the file ...
	if ( $c->debug ) {
		# ... using ::Static::Simple from the dev server
		$c->serve_static_file( $file );
	}
	else {
		# ... using X-Sendfile in production
		my $mt = MIME::Types->new( only_complete => 'true' );
		my $type = $mt->mimeTypeOf( $file );

		$c->response->code( '200' );
		$c->response->header( 'Content-Type' => $type->simplified );
		$c->response->header( 'X-Sendfile'   => $file             );
		$c->response->body( '' );
	}
	$c->detach;
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
