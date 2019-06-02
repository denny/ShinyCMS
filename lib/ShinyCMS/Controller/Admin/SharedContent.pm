package ShinyCMS::Controller::Admin::SharedContent;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::SharedContent

=head1 DESCRIPTION

Controller for ShinyCMS shared content admin features.

=cut


=head1 METHODS

=head2 base

Set up the base part of the URL path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/shared' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to edit CMS pages
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'edit shared content',
		role     => 'Shared Content Editor',
		redirect => '/admin'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'SharedContent';
}


=head2 index

Pass /admin/shared through to the edit page.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# No reason to be here at present - load the 'edit' page
	$c->go( 'edit_shared_content' );
}


=head2 get_shared_content

Fetch the shared content elements and stash them.

=cut

sub get_shared_content : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	my @elements = $c->model( 'DB::SharedContent' )->all;
	foreach my $element ( @elements ) {
		$c->stash->{ shared_content }->{ $element->name } = $element->content;
	}
	$c->stash->{ shared_content_elements } = \@elements;
}


=head2 edit_shared_content

Edit the shared content.

=cut

sub edit_shared_content : Chained( 'get_shared_content') : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ types  } = get_element_types();

	# Stash a list of images present in the images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'images' );
}


=head2 edit_shared_content_do

Process shared content update.

=cut

sub edit_shared_content_do : Chained( 'get_shared_content' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Extract elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			# Skip unless user is a Template Admin
			next unless $c->user->has_role( 'Shared Content Admin' );
			my $id = $1;
			$elements->{ $id }{ 'name' } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^type_(\d+)$/ ) {
			# Skip unless user is a Template Admin
			next unless $c->user->has_role( 'Shared Content Admin' );
			my $id = $1;
			$elements->{ $id }{ 'type' } = $c->request->param( $input );
		}
		else {
			# If it's not the name or the type, it must be the actual content
			$input =~ m/^content_(\d+)$/;
			my $id = $1;
			my $content = $c->request->param( $input );
			if ( length $content > 65_000 ) {
				$content = substr $content, 0, 65_000;
				$c->flash->{ error_msg } = 'Long field truncated (over 65,000 characters!)';
			}
			$elements->{ $id }{ 'content' } = $content;
		}
	}

	# Update elements
	foreach my $element ( keys %$elements ) {
		$c->model( 'DB::SharedContent' )->find({
			id => $element,
		})->update( $elements->{ $element } );
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( '/admin/shared' ) );
}


=head2 add_element_do

Add a new element to the shared content.

=cut

sub add_element_do : Chained( 'base' ) : PathPart( 'add-element-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to add new shared content items
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add new shared content',
		role     => 'Shared Content Admin',
		redirect => '/admin/shared'
	});

	# Extract page element from form
	my $element = $c->request->param('new_element');
	my $type    = $c->request->param('new_type'   );

	# Update the database
	$c->model( 'DB::SharedContent' )->create({
		name => $element,
		type => $type,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';

	# Bounce back to the shared content area
	$c->response->redirect( $c->uri_for( '/admin/shared' ) );
}


=head2 delete

Delete a shared content item

=cut

sub delete : Chained( 'base' ) : PathPart( 'delete' ) : Args( 1 ) {
	my ( $self, $c, $item_id ) = @_;

	# Update the database
	$c->model( 'DB::SharedContent' )->find({
		id => $item_id,
	})->delete;

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Shared content deleted';

	# Bounce back to the edit page
	$c->response->redirect( $c->uri_for( '/admin/shared' ) );
}


# ========== ( utility methods ) ==========

=head2 get_element_types

Return a list of element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this

	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
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
