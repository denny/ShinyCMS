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

Not used at present.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: What's the sensible default action to take here - recently added 
	# items?  List of categories?  Bit of both maybe.
}


=head2 base

Currently this just provides the base part of the path.

=cut

sub base : Chained('/') : PathPart('shop') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# ...
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
	die "Item $category_id not found" unless $c->stash->{ category };
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
	die "Item $item_id not found" unless $c->stash->{ item };
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
}


=head2 edit_item_do

Process an item update.

=cut

sub edit_item_do : Chained('get_item') : PathPart('edit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: Check to see if user is allowed to edit items
	# ...
	
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

