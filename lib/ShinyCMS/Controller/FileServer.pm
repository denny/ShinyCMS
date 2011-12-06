package ShinyCMS::Controller::FileServer;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::FileServer

=head1 DESCRIPTION

Controller for ShinyCMS authenticated fileserving.

=head1 METHODS

=cut


=head2 base

Set up the base path, fetch the discussion details.

=cut

sub base : Chained( '/' ) : PathPart( 'fileserver' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash->{ controller } = 'FileServer';
}


=head2 index

Catch people munging paths by hand and redirect them to site homepage

=cut

sub index : Path : Args( 0 ) {
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
		return;
	}
	
	# If they do have the required access, serve the file
	my $file = $c->path_to( 'root', 'restricted-files', $access, @pathparts );
	if ( -e $file ) {
		$c->serve_static_file( $file );
	}
	else {
		$c->response->code( '404' );
		$c->response->body( 'File not found.' );
	}
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

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

