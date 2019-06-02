package ShinyCMS::Controller::Shop::Basket;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


# TODO: Extend this to allow multiple named baskets for logged-in users


=head1 NAME

ShinyCMS::Controller::Shop::Basket

=head1 DESCRIPTION

Controller for ShinyCMS shop basket.

=cut


has currency => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);


=head1 METHODS

=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained('/base') : PathPart('shop/basket') : CaptureArgs(0) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash( controller => 'Shop::Basket' );

	# Stash the currency symbol
	$c->stash->{ currency } = $self->currency;

	# Stash the basket
	my $basket = $self->get_basket( $c );
	$c->stash( basket => $basket );
}


=head2 create_basket

Create a new basket

=cut

sub create_basket : Private {
	my ( $self, $c ) = @_;

	# If the user is logged-in, link basket to user account
	if ( $c->user_exists ) {
		return $c->user->baskets->create({});
	}

	# If not a logged-in user, link basket to session
	$c->session;
	return $c->model('DB::Basket')->create({
		session => 'session:' . $c->sessionid,
	});
}


=head2 get_basket

Get the basket

=cut

sub get_basket : Private {
	my ( $self, $c ) = @_;

	# If the user is logged-in, find their basket by user ID
	if ( $c->user_exists ) {
		return $c->model('DB::Basket')->search(
			{
				user => $c->user->id,
			},
			{
				join     => 'basket_items',
				prefetch => 'basket_items',
			}
		)->first;
	}

	# If not a logged-in user, find by session ID
	my $session_id = $c->sessionid || '';
	return $c->model('DB::Basket')->search(
		{
			session => 'session:' . $session_id,
			user    => undef,
		},
		{
			join     => 'basket_items',
			prefetch => 'basket_items',
		}
	)->first;
}


=head2 view_basket

Display the basket contents

=cut

sub view_basket : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
}


=head2 add_item

Add an item to the basket

=cut

sub add_item : Chained('base') : PathPart('add-item') : Args(0) {
	my ( $self, $c ) = @_;

	# Create basket if we don't already have one
	$c->stash->{ basket } = $self->create_basket( $c )
		unless $c->stash->{ basket };

	# Fetch the item details (for unit price)
	my $item = $c->model('DB::ShopItem')->find({
		id => $c->request->param('item_id'),
	});

	# Check to see if we already have one/some of these in the basket
	my @basket_items = $c->stash->{ basket }->basket_items->all;
	my $existing_item;
	foreach my $basket_item ( @basket_items ) {
		if ( $item->id == $basket_item->item->id ) {
			# Found matching item type; now check attributes, if any
			my $match = 1;
			my @attributes = $basket_item->basket_item_attributes->all;
			foreach my $attribute ( @attributes ) {
				my $name  = lc $attribute->name;
				my $value = $attribute->value;
				$match = 0 unless defined
					$c->request->params->{ "shop_item_attribute_$name" } and
					$c->request->params->{ "shop_item_attribute_$name" } eq $value;
			}
			if ( $match ) {
				# Found matching item - update the quantity
				$basket_item->update({
					quantity => $basket_item->quantity + $c->request->param('quantity'),
				});
				$existing_item = 1;
				last;
			}
		}
	}

	unless ( $existing_item ) {
		# No matching item found in the basket - add it
		my $basket_item = $c->stash->{ basket }->basket_items->create({
			item       => $item->id,
			quantity   => $c->request->param('quantity'),
			unit_price => $item->price,
		});

		# Pick up any optional attributes
		my $params = $c->request->params;
		foreach my $key ( keys %$params ) {
			next unless $key =~ m/^shop_item_attribute_(\w+)/;
			my $attr_name = ucfirst $1;
			my $attr_val  = $params->{ $key };
			$basket_item->basket_item_attributes->create({
				name  => $attr_name,
				value => $attr_val,
			});
		}
	}

	# Set a status message
	$c->flash->{ status_msg } = 'Item added.';

	# Redirect to a return URL if specified, or to the basket otherwise
	if ( $c->request->param('return_url') ) {
		$c->response->redirect( $c->request->param('return_url') );
	}
	else {
		$c->response->redirect( $c->uri_for( 'view_basket' ) );
	}
}


=head2 update

Update items in the basket

=cut

sub update : Chained('base') : PathPart('update') : Args(0) {
	my ( $self, $c ) = @_;

	my $params = $c->request->params;

	foreach my $key ( keys %$params ) {
		next unless $key =~ m/^quantity_(\d+)$/;
		my $item_id = $1;

		if ( $params->{ $key } == 0 ) {
			# Remove the item
			my $item = $c->stash->{ basket }->basket_items->find({
				id => $item_id,
			});
			my $attributes = $item->basket_item_attributes;
			$attributes->delete if $attributes;
			$item->delete;

			# Set a status message
			$c->flash->{ status_msg } = 'Item removed.';
		}
		else {
			# Update the item
			$c->stash->{ basket }->basket_items->find({
				id => $item_id,
			})->update({
				quantity => $params->{ $key },
			});

			# Set a status message
			$c->flash->{ status_msg } = 'Item updated.';
		}
	}

	# Redirect back to the basket
	$c->response->redirect( $c->uri_for( '' ) );
}


=head2 remove_item

Remove an item from the basket

=cut

sub remove_item : Chained('base') : PathPart('remove-item') : Args(0) {
	my ( $self, $c ) = @_;

	# Delete this item from the basket
	my $item = $c->stash->{ basket }->basket_items->find({
		item => $c->request->param('item_id'),
	});
	my $attributes = $item->basket_item_attributes;
	$attributes->delete if $attributes;
	$item->delete;

	# Set a status message and redirect back to the basket
	$c->flash->{ status_msg } = 'Item removed.';
	$c->response->redirect( $c->uri_for( '' ) );
}


=head2 empty

Remove all items from the basket

=cut

sub empty : Chained('base') : PathPart('empty') : Args(0) {
	my ( $self, $c ) = @_;

	# Remove all items from the basket
	foreach my $item ( $c->stash->{ basket }->basket_items->all ) {
		my $attributes = $item->basket_item_attributes;
		$attributes->delete if $attributes;
		$item->delete;
	}
	# Delete the basket
	$c->stash->{ basket }->delete;

	# Set a status message and redirect back to the shop
	$c->flash->{ status_msg } = 'Basket emptied.';
	$c->response->redirect( $c->uri_for( '' ) );
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
