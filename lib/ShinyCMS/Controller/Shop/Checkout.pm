package ShinyCMS::Controller::Shop::Checkout;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use ShinyCMS::Controller::Shop::Basket;


=head1 NAME

ShinyCMS::Controller::Shop::Checkout

=head1 DESCRIPTION

Controller for shop checkout features.

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

sub base : Chained('/base') : PathPart('shop/checkout') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash( controller => 'Shop::Checkout' );
	
	# Stash the currency symbol
	$c->stash->{ currency } = $self->currency;
	
	# Stash the basket (if any)
	my $basket = ShinyCMS::Controller::Shop::Basket->get_basket( $c );
	$c->stash( basket => $basket );
	
	# Stash the order (if any)
	my $order = $self->get_order( $c );
	$c->stash( order => $order );
}


=head2 index

No index action (currently?); redirect customer to billing address stage

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $uri = $c->uri_for( 'billing-address' );
	$c->response->redirect( $uri );
}


=head2 get_order

Get the order

=cut

sub get_order : Private {
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
				order_by => { -desc => 'me.created' },
			}
		)->first;
		return $order;
	}
	
	# If not a logged-in user, find by session ID
	my $session_id = $c->sessionid || '';
	my $order = $c->model('DB::Order')->search(
		{
			session => 'session:' . $session_id,
			user    => undef,
		},
		{
			join     => 'order_items',
			prefetch => 'order_items',
			order_by => { -desc => 'me.created' },
		}
	)->first;
	return $order;
}


=head2 billing_address

Get the customer's billing address

=cut

sub billing_address : Chained('base') : PathPart('billing-address') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'basket' } or defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 'There is nothing in your basket.';
		my $uri = $c->uri_for( '/shop', 'basket' );
		$c->response->redirect( $uri );
	}
}


=head2 add_billing_address

Process the customer's billing address submission - create the order

=cut

sub add_billing_address : Chained('base') : PathPart('add-billing-address') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Store the billing address
	my $email            = $c->request->params->{'email'   };
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
		$c->flash->{ email    } = $c->request->params->{'email'    };
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
		email            => $email,
		billing_address  => $billing_address,
		billing_town     => $billing_town,
		billing_county   => $billing_county,
		billing_country  => $billing_country,
		billing_postcode => $billing_postcode,
		created          => DateTime->now,
	});
	
	# Store the order items
	my $basket_items = $c->stash->{ basket }->basket_items;
	while ( my $item = $basket_items->next ) {
		my $order_item = $order->order_items->create({
			item       => $item->item->id,
			quantity   => $item->quantity,
			unit_price => $item->unit_price,
		});
		my $attributes = $item->basket_item_attributes;
		while ( my $attribute = $attributes->next ) {
			$order_item->order_item_attributes->create({
				name  => $attribute->name,
				value => $attribute->value,
			});
		}
	}
	
	# Find out if we need to get a different delivery address or not
	# TODO: Skip delivery address and postage options stages for virtual goods
	my $uri;
	if ( $c->request->params->{ 'get_delivery_address' } ) {
		# Redirect to delivery address stage
		$uri = $c->uri_for( 'delivery-address' );
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
		# Set up redirect hint for back button on subsequent pages
		$c->flash->{ back_to } = $c->uri_for( 'billing-address' );
		# Redirect straight to postage options stage
		$uri = $c->uri_for( 'postage-options' );
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
		$c->flash->{ error_msg } = 
				'You must fill in your billing address before you can continue.';
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
	
	# Check for 'oops, changed my mind, deliver to billing address'
	if ( $c->request->params->{ 'use_billing_address' } ) {
		$c->stash->{ 'order' }->update({
			delivery_address  => $c->stash->{ 'order' }->billing_address,
			delivery_town     => $c->stash->{ 'order' }->billing_town,
			delivery_county   => $c->stash->{ 'order' }->billing_county,
			delivery_country  => $c->stash->{ 'order' }->billing_country,
			delivery_postcode => $c->stash->{ 'order' }->billing_postcode,
		});
		
		# And send them to the next stage
		my $uri = $c->uri_for( 'postage-options' );
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
	my $uri = $c->uri_for( 'postage-options' );
	$c->response->redirect( $uri );
}


=head2 postage_options

Get the customer's postage options

=cut

sub postage_options : Chained('base') : PathPart('postage-options') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 
				'You must fill in your billing address before you can continue.';
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	unless ( $c->stash->{ 'order' }->delivery_address ) {
		$c->flash->{ error_msg } = 
				'You must fill in your delivery address before you can continue.';
		my $uri = $c->uri_for( 'delivery-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# TODO: batch delivery rates and other complexities
}


=head2 add_postage_options

Save the customer's postage option selections

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
	
	# Get the selected postage options from the form and save them to database
	my @keys = keys %{ $c->request->params };
	foreach my $key ( @keys ) {
		next unless $key =~ m/^postage_(\d+)$/;
		my $order_item_id = $1;
		
		$c->stash->{ order }->order_items->find({
			id => $order_item_id,
		})->update({
			postage => $c->request->params->{ $key },
		});
	}
	
	$c->stash->{ 'order' }->update({
		status  => 'Awaiting payment',
		updated => DateTime->now,
	});
	
	my $uri = $c->uri_for( 'payment' );
	$c->response->redirect( $uri );
}


=head2 payment

Send the customer off to pay

=cut

sub payment : Chained('base') : PathPart('payment') : Args(0) {
	my ( $self, $c ) = @_;
	
	unless ( defined $c->stash->{ 'order' } ) {
		$c->flash->{ error_msg } = 
				'You must fill in your billing address before you can continue.';
		my $uri = $c->uri_for( 'billing-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	unless ( $c->stash->{ 'order' }->delivery_address ) {
		$c->flash->{ error_msg } = 
				'You must fill in your delivery address before you can continue.';
		my $uri = $c->uri_for( 'delivery-address' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# Check to make sure postage options have been selected for all items
	my $postage_problem = 0;
	foreach my $item ( $c->stash->{ order }->order_items->all ) {
		$postage_problem = 1 unless $item->postage;
	}
	if ( $postage_problem ) {
		$c->flash->{ error_msg } = 
			'You must select postage options for all of your items before you can continue.';
		my $uri = $c->uri_for( 'postage-options' );
		$c->response->redirect( $uri );
		$c->detach;
	}
	
	# Empty the basket
	if ( defined $c->stash->{ basket } ) {
		$c->stash->{ basket }->basket_items
			->search_related( 'basket_item_attributes' )->delete;
		$c->stash->{ basket }->basket_items->delete;
		$c->stash->{ basket }->delete;
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
