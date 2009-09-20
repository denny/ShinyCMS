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

This doesn't do much at present.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: What's the sensible default action to take here - recently 
	# added items?  List of categories?  Bit of both maybe?  Some kind 
	# of 'storefront' page, anyway.
	
	# ...
}


=head2 base

This doesn't do much at present.

=cut

sub base : Chained('/') : PathPart('shop') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
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
	
	# TODO: 404 handler
	die "Category not found: $category_id" unless $c->stash->{ category };
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
	
	# TODO: 404 handler
	die "Item not found: $item_id" unless $c->stash->{ item };
}


=head2 view_item

View an item.

=cut

sub view_item : Chained('get_item') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
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
	$c->flash->{status_msg} = 'Details updated';
	
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

