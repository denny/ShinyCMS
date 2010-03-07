package ShinyCMS::Controller::FileManager;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::FileManager

=head1 DESCRIPTION

Controller for CKEditor compatible file manager.

=head1 METHODS

=cut


=head2 index

Forward to the view method.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->response->redirect( $c->uri_for( 'view' ) );
}


=head2 base

Base method, sets up path.

=cut

sub base : Chained('/') : PathPart('filemanager') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
}


=head2 view

View files in a directory.

=cut

sub view : Chained('base') : PathPart('view') : Args {
	my ( $self, $c, $dir ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = ShinyCMS->config->{ upload_dir };
	
	# Get the list of files
	$c->stash->{ files } = $self->get_file_details( $c, $dir );
}


=head2 get_file_details

Get details of the files in a specified directory.

=cut

sub get_file_details {
	my ( $self, $c, $dirname ) = @_;
	
	# Set default uploads directory if no dir passed in
	my $dir = $c->path_to( 'root/static/'. $c->stash->{ upload_dir } );
	$dir .= '/'.$dirname if $dirname;
	
	$c->stash->{ path } = [ $c->stash->{ upload_dir }, split( '/', $dirname ) ];
	
	# Read in the files in the specified directory
	opendir( my $dh, $dir ) or die "Failed to open directory $dir: $!";
	my @files;
	my @filenames = sort( { lc($a) cmp lc($b) } readdir( $dh ) );
	foreach my $filename ( @filenames ) {
		# Skip hidden files
		next if $filename =~ m/^\./;
		
		# Create a hashref to stick all the metadata in
		my $file = {};
		
		# Save the filename
		$file->{ filename  } = $filename;
		
		# Flag directories
		if ( -d $dir.'/'.$filename ) {
			$file->{ directory } = 1;
		}
		
		# Flag images
		if ( $filename =~ m/(.png|.jpg|.jpeg|.gif)$/i ) {
			$file->{ image } = 1;
		}
		
		# Add the metadata about this file to the files array
		push @files, $file;
	}
	
	return \@files;
}


=head2 upload

Upload a file.

=cut

sub upload : Chained('base') : PathPart('upload') : OptionalArgs(1) {
	my ( $self, $c, $type ) = @_;
	
	$c->stash->{ upload_dir } .= '/'.$type if $type;
	
	# ...
}



=head1 AUTHOR

Denny de la Haye <2010@denny.me>

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

