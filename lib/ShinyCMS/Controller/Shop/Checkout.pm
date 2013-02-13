package ShinyCMS::Controller::Shop::Checkout;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


use ShinyCMS::Controller::Shop::Basket;


=head1 NAME

ShinyCMS::Controller::Shop::Checkout

=head1 DESCRIPTION

Controller for shop checkout features.

=head1 METHODS

=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained('/base') : PathPart('shop/checkout') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash( controller => 'Shop::Checkout' );
	
	# Stash the basket (if any)
	my $basket = ShinyCMS::Controller::Shop::Basket->get_basket( $c );
	$c->stash( basket => $basket );
	
	# Stash the order (if any)
	my $order = $self->get_order( $c );
	$c->stash( order => $order );
}


=head2 get_order

Get the order

=cut

sub get_order : Private : Args(0) {
	my ( $self, $c ) = @_;
	
	# If the user is logged-in, find their order by user ID
	if ( $c->user_exists ) {
		my $order = $c->model('DB::Order')->search(
			{
				user => $c->user->id,
			},
			{
				join     => 'order_items',
				prefetch => 'order_items',
			}
		)->first;
		return $order;
	}
	
	# If not a logged-in user, find by session ID
	my $order = $c->model('DB::Order')->search(
		{
			session => 'session:' . $c->sessionid,
			user    => undef,
		},
		{
			join     => 'order_items',
			prefetch => 'order_items',
		}
	)->first;
	return $order;
}


=head2 index

No index action (currently?); redirect customer to billing address stage

=cut

sub index : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	my $uri = $c->uri_for( 'billing-address' );
	$c->response->redirect( $uri );
}


=head2 billing_address

Get the customer's billing address

=cut

sub billing_address : Chained('base') : PathPart('billing-address') : Args(0) {
	my ( $self, $c ) = @_;
}


=head2 add_billing_address

Process the customer's billing address submission - create the order

=cut

sub add_billing_address : Chained('base') : PathPart('add-billing-address') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Store the billing address
	my $billing_address  = $c->request->params->{'address' };
	my $billing_town	 = $c->request->params->{'town'	   };
	my $billing_county   = $c->request->params->{'county'  };
	my $billing_country  = $c->request->params->{'country' };
	my $billing_postcode = $c->request->params->{'postcode'};
	
	# Check address for required fields
	unless ( $billing_address and $billing_town and $billing_postcode ) {
		if ( not $billing_address ) {
			$c->flash->{ error_msg } = 'Please fill in your address.';
		}
		elsif ( not $billing_town ) {
			$c->flash->{ error_msg } = 'Please fill in your town.';
		}
		elsif ( not $billing_country ) {
			$c->flash->{ error_msg } = 'Please select your country.';
		}
		elsif ( not $billing_postcode ) {
			$c->flash->{ error_msg } = 'Please fill in your postcode.';
		}
		# Re-populate any fields they did fill in
		$c->flash->{ address  } = $c->request->params->{'address'  };
		$c->flash->{ town     } = $c->request->params->{'town'     };
		$c->flash->{ county   } = $c->request->params->{'county'   };
		$c->flash->{ county   } = $c->request->params->{'country'  };
		$c->flash->{ postcode } = $c->request->params->{'postcode' };
		# Bounce them back to the form
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# TODO: Sanity check postcode?  Would need i18n support
	
	# Create the order
	my $user_id;
	my $session_id;
	if ( $c->user_exists ) {
		$user_id = $c->user->id;
	}
	else {
		$session_id = 'session:' . $c->sessionid;
	}
	my $order = $c->model('DB::Order')->create({
		user             => $user_id,
		session          => $session_id,
		billing_address  => $billing_address,
		billing_town     => $billing_town,
		billing_county   => $billing_county,
		billing_country  => $billing_country,
		billing_postcode => $billing_postcode,
	});
	
	# Store the order items
	my $basket_items = $c->stash->{ basket }->basket_items;
	while ( my $item = $basket_items->next ) {
		$order->order_items->create({
			item       => $item->item->id,
			quantity   => $item->quantity,
			unit_price => $item->unit_price,
		});
	}
	
	# Empty the basket
	# TODO: uncomment this when checkout process dev is finished  :)
	#$c->basket->basket_items->delete;
	#$c->basket->delete;
	
	# Find out if we need to get a different delivery address or not
	# TODO: Skip delivery address and postage options stages for virtual goods
	my $uri;
	if ( $c->request->params->{ 'get_delivery_address' } ) {
		# Redirect to delivery address stage
		$uri = $c->uri_for( '/shop', 'checkout', 'delivery-address' );
	}
	else { # Deliver to billing address
		# Store the delivery address
		$order->update({
			delivery_address  => $order->billing_address,
			delivery_town     => $order->billing_town,
			delivery_county   => $order->billing_county,
			delivery_country  => $order->billing_country,
			delivery_postcode => $order->billing_postcode,
		});
		# Redirect straight to postage options stage
		$uri = $c->uri_for( '/shop', 'checkout', 'postage-options' );
	}
	
	# Stash the order
	$c->stash->{ 'order' } = $order;
	
	# Redirect to the next stage
	$c->response->redirect( $uri );
}


=head2 delivery_address

Get the customer's delivery address

=cut

sub delivery_address : Chained('base') : PathPart('delivery-address') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 'You must fill in your billing address first.';
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
	}
}


=head2 add_delivery_address

Add the customer's delivery address to the order

=cut

sub add_delivery_address : Chained('base') : PathPart('add-delivery-address') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check for the 'back' button first
	if ( $c->request->params->{ 'go' } eq 'Back' ) {
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# Extract the delivery address from the form data
	my $delivery_address  = $c->request->params->{'address' };
	my $delivery_town	  = $c->request->params->{'town'    };
	my $delivery_county   = $c->request->params->{'county'  };
	my $delivery_country  = $c->request->params->{'country' };
	my $delivery_postcode = $c->request->params->{'postcode'};
	
	# Check address for required fields
	unless ( $delivery_address and $delivery_town and $delivery_postcode ) {
		if ( not $delivery_address ) {
			$c->flash->{ error_msg } = 'Please fill in your address.';
		}
		elsif ( not $delivery_town ) {
			$c->flash->{ error_msg } = 'Please fill in your town.';
		}
		elsif ( not $delivery_country ) {
			$c->flash->{ error_msg } = 'Please select your country.';
		}
		elsif ( not $delivery_postcode ) {
			$c->flash->{ error_msg } = 'Please fill in your postcode.';
		}
		# Re-populate any fields they did fill in
		$c->flash->{ address  } = $c->request->params->{'address'  };
		$c->flash->{ town     } = $c->request->params->{'town'     };
		$c->flash->{ county   } = $c->request->params->{'county'   };
		$c->flash->{ country  } = $c->request->params->{'country'  };
		$c->flash->{ postcode } = $c->request->params->{'postcode' };
		# Bounce them back to the form
		my $uri = $c->uri_for( 'delivery-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# TODO: Sanity check postcode?  Would need i18n support
	
	$c->stash->{ 'order' }->update({
		delivery_address  => $delivery_address,
		delivery_town     => $delivery_town,
		delivery_county   => $delivery_county,
		delivery_country  => $delivery_country,
		delivery_postcode => $delivery_postcode,
	});
	
	# Redirect to the next stage
	my $uri = $c->uri_for( '/shop', 'checkout', 'postage-options' );
	$c->response->redirect( $uri );
}


=head2 postage_options

Get the customer's postage options

=cut

sub postage_options : Chained('base') : PathPart('postage-options') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 'You must fill in your billing address first.';
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	unless ( $c->stash->{ 'order' }->delivery_address ) {
		$c->flash->{ error_msg } = 'You must fill in your delivery address first.';
		my $uri = $c->uri_for( 'delivery-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# TODO: batch delivery rates, minimum costs, and other complexities
	# For now, just get all the postage options and de-dupe them
	my @order_items = $c->stash->{ order }->order_items->all;
	my $postage_options = {};
	foreach my $item ( @order_items ) {
		my @item_options = $item->item->postages->all;
		foreach my $option ( @item_options ) {
			$postage_options->{ $option->id } = $option;
		}
	}
	my $options = [];
	foreach my $key ( sort keys %$postage_options ) {
		push @$options, $postage_options->{ $key };
	}
	
	# Stash them
	$c->stash->{ postage_options } = $options;
}


=head2 add_postage_options

Save the customer's postage options

=cut

sub add_postage_options : Chained('base') : PathPart('add-postage-options') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check for the 'back' button first
	if ( $c->request->params->{ 'go' } =~ m/Back/ ) {
		my $uri;
		if ( $c->request->params->{ 'back_to' } ) {
			$uri = $c->uri_for( $c->request->params->{ 'back_to' } );
		}
		else {
			$uri = $c->uri_for( 'billing-address' );
		}
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# Get the selected postage option
	my $postage_id = $c->request->params->{ 'postage' };
	
	# Store the selected postage option
	my @order_items = $c->stash->{ order }->order_items->all;
	foreach my $item ( @order_items ) {
		$item->order_item_postage_options->create({
			postage => $postage_id,
		});
	}
	
	my $uri = $c->uri_for( 'payment' );
	$c->response->redirect( $uri );
}


=head2 payment

Send the customer off to pay

=cut

sub payment : Chained('base') : PathPart('payment') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 'You must fill in your billing address first.';
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	unless ( $c->stash->{ 'order' }->delivery_address ) {
		$c->flash->{ error_msg } = 'You must fill in your delivery address first.';
		my $uri = $c->uri_for( 'delivery-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
}



=head1 AUTHOR

Denny de la Haye <2013@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2013 Shiny Ideas (www.shinyideas.co.uk).

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

