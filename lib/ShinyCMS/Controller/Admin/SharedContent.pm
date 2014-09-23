package ShinyCMS::Controller::Admin::SharedContent;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::SharedContent

=head1 DESCRIPTION

Controller for ShinyCMS shared content admin features.

=head1 METHODS

=cut


=head2 index

=cut

sub index : Path : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	# No reason to be here at present - load the 'edit' page
	$c->go( 'edit_shared_content' );
}


=head2 base

Set up the base part of the URL path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/shared' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash->{ controller } = 'Admin::SharedContent';
}


=head2 get_element_types

Return a list of element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this
	
	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
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
	
	# Check to make sure user has the right to edit CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit shared content', 
		role     => 'Shared Content Editor', 
	});
	
	$c->stash->{ types  } = get_element_types();
	
	# Stash a list of images present in the images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'images' );
}


=head2 edit_shared_content_do

Process shared content update.

=cut

sub edit_shared_content_do : Chained( 'get_shared_content' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action => 'edit shared content', 
		role   => 'Shared Content Editor',
	});
	
	# Extract elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'CMS Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'name'    } = $c->request->param( $input );
		}
		if ( $input =~ m/^type_(\d+)$/ ) {
			# skip unless user is a template admin
			next unless $c->user->has_role( 'CMS Template Admin' );
			my $id = $1;
			$elements->{ $id }{ 'type'    } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
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
	$c->response->redirect( $c->uri_for( '/admin', 'shared', 'edit' ) );
}


=head2 add_element_do

Add a new element to the shared content.

=cut

sub add_element_do : Chained( 'base' ) : PathPart( 'add-element-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to change CMS templates
	return 0 unless $self->user_exists_and_can($c, {
		action => 'add an element to the shared content', 
		role   => 'CMS Template Admin',
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
	
	# Bounce back to the edit page
	$c->response->redirect( $c->uri_for( '/admin', 'shared', 'edit' ) );
}



=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2014 Shiny Ideas (www.shinyideas.co.uk).

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

