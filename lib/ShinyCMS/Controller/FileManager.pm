package ShinyCMS::Controller::FileManager;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::FileManager

=head1 DESCRIPTION

Controller for CKEditor-compatible file manager.

=head1 METHODS

=cut



=head2 can_browse_files

Returns true if the current user has auth'd to browse files

=cut

sub can_browse_files {
	my ( $self, $c ) = @_;
	
	return 1 if $c->user->has_role( 'CMS Page Editor' ) 
	         or $c->user->has_role( 'Events Admin'    );
}


=head2 can_upload_files

Returns true if the current user has auth'd to upload files

=cut

sub can_upload_files {
	my ( $self, $c ) = @_;
	
	return 1 if $c->user->has_role( 'CMS Page Editor' ) 
	         or $c->user->has_role( 'Events Admin'    );
}


=head2 can_delete_files

Returns true if the current user has auth'd to delete files

=cut

sub can_delete_files {
	my ( $self, $c ) = @_;
	
	return $c->user->has_role( 'File Admin' );
}



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

sub base : Chained( '/' ) : PathPart( 'filemanager' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check user auth
	unless ( $self->can_browse_files( $c ) ) {
		$c->response->redirect( $c->uri_for( '/' ) );
		return;
	}
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
}


=head2 view

View files in a directory.

=cut

sub view : Chained( 'base' ) : PathPart( 'view' ) : Args {
	my ( $self, $c, $dir ) = @_;
	
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

	if ( $dirname ) {
		$dir .= '/'.$dirname;
		$c->stash->{ path   } = [ $c->stash->{ upload_dir }, split( '/', $dirname ) ];
		$c->stash->{ subdir } = $dirname;
	}
	else {
		$c->stash->{ path } = [ $c->stash->{ upload_dir } ];
	}
	
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
		if ( -d $dir .'/'. $filename ) {
			$file->{ directory } = 1;
		}
		
		# Flag images
		if ( $filename =~ m/(\.png|\.jpeg|\.jpg|\.gif)$/i ) {
			$file->{ image } = 1;
		}
		
		# Add the metadata about this file to the files array
		push @files, $file;
	}
	
	return \@files;
}


=head2 upload_file

Display file-upload page.

=cut

sub upload_file : Chained( 'base' ) : PathPart( 'upload-file' ) : Args( 0 ){
	my ( $self, $c ) = @_;
	
	# Check user auth
	unless ( $self->can_upload_files( $c ) ) {
		$c->response->redirect( $c->uri_for( '/admin' ) );
		return;
	}
	
	# Read in sub-directories of uploads folder
	opendir my $dh, $c->path_to( 'root', 'static', $c->stash->{ upload_dir } )
		or die "Failed to open uploads directory for reading: $!";
	my @files = readdir $dh;
	closedir $dh;
	
	# Pull out the useful directories, ignore everything else
	my @subdirs;
	foreach my $file ( @files ) {
		push @subdirs, $file if $file !~ m/^\./ 
			and -d $c->path_to( 'root', 'static', $c->stash->{ upload_dir }, $file );
	}
	
	# Stash the rest
	$c->stash->{ subdirs } = \@subdirs;
}


=head2 upload_do

Process a file upload.

=cut

sub upload_do : Chained( 'base' ) : PathPart( 'upload' ) : Args {
	my ( $self, $c, $dir ) = @_;
	
	# Check user auth
	unless ( $self->can_upload_files( $c ) ) {
		$c->response->redirect( $c->uri_for( '/admin' ) );
		return;
	}
	
	# Extract the upload
	my $upload = $c->request->upload( 'upload' );
	
	# Place file in user-specified subdir, if any
	$dir = $c->request->param( 'subdir' ) if $c->request->param( 'subdir' );
	$c->stash->{ upload_dir } .= '/'. $dir if $dir;
	
	# Save file to appropriate location
	my $save_as = $c->path_to( 'root', 'static', $c->stash->{ upload_dir }, $upload->filename );
	$upload->copy_to( $save_as ) or die "Failed to write file '$save_as' because: $!,";
	
	if ( $c->request->param( 'CKEditorFuncNum' ) ) {
		# Return appropriate javascript snippet
		my $body = '<script type="text/javascript">window.parent.CKEDITOR.tools.callFunction( '.
			$c->request->param('CKEditorFuncNum') .", '/static/". 
			$c->stash->{ upload_dir } .'/'. $upload->filename ."' );</script>";
		$c->response->body( $body );
	}
	else {
		# Redirect to view page
		$c->response->redirect( $c->uri_for( 'view', $dir ) );
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

