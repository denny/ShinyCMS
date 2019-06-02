package ShinyCMS::Controller::Admin::FileManager;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::FileManager

=head1 DESCRIPTION

Controller for CKEditor-compatible file manager.

=cut



=head1 METHODS

=head2 base

Base method, sets up path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/filemanager' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'administrate CMS-uploaded files',
		role     => 'File Admin',
		redirect => '/admin'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'FileManager';
}


=head2 index

Forward to the view method.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'view' );
}


=head2 view

View files in a directory.

=cut

sub view : Chained( 'base' ) : PathPart( 'view' ) : Args {
	my ( $self, $c, @path ) = @_;

	# Get the list of files
	$c->stash->{ files } = $self->get_file_details( $c, @path );
}


=head2 get_file_details

Get details of the files in a specified directory.

=cut

sub get_file_details {
	my ( $self, $c, @path ) = @_;

	# Set default uploads directory if no dir passed in
	my $dir = $c->path_to( 'root', 'static', $c->stash->{ upload_dir } );

	if ( @path ) {
		$dir .= '/'. join '/', @path;
		$c->stash->{ webpath } = [ @path ];
		$c->stash->{ path    } = [ $c->stash->{ upload_dir }, @path ];
		$c->stash->{ subdir  } = $path[-1];
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
		$c->response->redirect( $c->uri_for( 'view') ) unless $dir;
		$c->response->redirect( $c->uri_for( 'view', $dir ) ) if $dir;
	}
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
