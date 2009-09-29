package ShinyCMS::Controller::Shop;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

ShinyCMS::Controller::Shop

=head1 DESCRIPTION

Main controller for ShinyCMS's online shop functionality.

=head1 METHODS

=cut


=head2 index

For now, forwards to the category list.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: What's the sensible default action to take here - recently 
	# added items?  List of categories?  Special offers?  Some kind of 
	# ''storefront' page, anyway.
	
	$c->go('view_categories');
}


=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained('/') : PathPart('shop') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
}


=head2 view_categories

View all the categories.

=cut

sub view_categories : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @categories = $c->model('DB::ShopCategory')->search;
	$c->stash->{ categories } = \@categories;
}


=head2 no_category_specified

Catch people traversing the URL path by hand and show them something useful.

=cut

sub no_category_specified : Chained('base') : PathPart('category') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->go('view_categories');
}


=head2 get_category

Stash details and items relating to the specified category.

=cut

sub get_category : Chained('base') : PathPart('category') : CaptureArgs(1) {
	my ( $self, $c, $category_id ) = @_;
	
	if ( $category_id =~ /\D/ ) {
		# non-numeric identifier (category url_name)
		$c->stash->{ category } = $c->model('DB::ShopCategory')->find( { url_name => $category_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ category } = $c->model('DB::ShopCategory')->find( { id => $category_id } );
	}
	
	# TODO: better 404 handler here?
	unless ( $c->stash->{ category } ) {
		$c->stash->{ status_msg } = 
			'Specified category not found - please select from the options below';
		$c->go('view_categories');
	}
}


=head2 view_category

View all items in the specified category.

=cut

sub view_category : Chained('get_category') : PathPart('') : Args(0) {
	my ( $self, $c, $category ) = @_;
}


=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained('base') : PathPart('item') : CaptureArgs(1) {
	my ( $self, $c, $item_id ) = @_;
	
	if ( $item_id =~ /\D/ ) {
		# non-numeric identifier (product code)
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { code => $item_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { id => $item_id } );
	}
	
	# TODO: 404 handler - should include a search feature and helpful guidance
	die "Item not found: $item_id" unless $c->stash->{ item };
}


=head2 view_item

View an item.

=cut

sub view_item : Chained('get_item') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
}


=head2 add_item

TODO: Add an item. TODO

=cut

sub add_item : Chained('base') : PathPart('add_item') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit items.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a shop admin
	unless ( $c->user->has_role('Shop Admin') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit items in the shop.';
		$c->response->redirect( $c->uri_for( '/shop' ) );
	}
	
	$c->stash->{template} = 'shop/edit_item.tt';
}


=head2 add_item_do

Process an item add.

=cut

sub add_item_do : Chained('base') : PathPart('add_item_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add items
	die unless $c->user->has_role('Shop Admin');
	
	# Extract item details from form
	my $details = {
		code			=> $c->request->params->{ code          },
		name			=> $c->request->params->{ name	        },
		description		=> $c->request->params->{ description   },
		price			=> $c->request->params->{ price         },
		paypal_button	=> $c->request->params->{ paypal_button },
	};
	
	# Create item
	my $item = $c->model('DB::ShopItem')->create( $details );
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Item added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/shop/item/'. $item->code .'/edit' );
}


=head2 edit_item

Edit an item.

=cut

sub edit_item : Chained('get_item') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit items.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a shop admin
	unless ( $c->user->has_role('Shop Admin') ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit items in the shop.';
		my $item_id = $c->stash->{ item }->code || $c->stash->{ item }->id;
		$c->response->redirect( $c->uri_for( '/shop/item/'. $item_id ) );
	}
}


=head2 edit_item_do

Process an item update.

=cut

sub edit_item_do : Chained('get_item') : PathPart('edit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit items
	die unless $c->user->has_role('Shop Admin');
	
	# Check for price updates, warn if using external checkout
	if ( $c->request->params->{ paypal_button } ) {
		my $old_price = $c->model('DB::ShopItem')->find({
							id => $c->stash->{ item }->id
						})->price;
		if ( $c->request->params->{ price } != $old_price ) {
			$c->flash->{warning_msg} = 'Remember to also update price in PayPal checkout.';
		}
	}
	
	# Extract item details from form
	my $details = {
		code			=> $c->request->params->{ code          },
		name			=> $c->request->params->{ name	        },
		description		=> $c->request->params->{ description   },
		price			=> $c->request->params->{ price         },
		paypal_button	=> $c->request->params->{ paypal_button },
	};
	
	# Update item
	my $item = $c->model('DB::ShopItem')->find({
					id => $c->stash->{ item }->id,
				})->update( $details );
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Item updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/shop/item/'. $c->stash->{ item }->code .'/edit' );
}



=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

