package ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill

=head1 DESCRIPTION

Controller for handling payment for physical goods via CCBill.

=cut


__PACKAGE__->config->{ namespace } = 'payment-handler/physical-goods/ccbill';

has key => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);

has despatch_email => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);


=head1 METHODS

=head2 base

Set up path etc

=cut

sub base : Chained( '/base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $key ) = @_;

	unless ( $key eq $self->key ) {
		$c->response->code( '403' );
		$c->response->body( 'Access forbidden.' );
		$c->detach;
	}

	# Find the order
	if ( $c->request->param( 'shinycms_order_id' ) ) {
		$c->stash->{ order } = $c->model( 'DB::Order' )->find({
			id => $c->request->param( 'shinycms_order_id' ),
		});
	}
}


=head2 index

Shouldn't be here - redirect to homepage

=cut

sub index : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Shouldn't be here
	$c->response->redirect( $c->uri_for( '/' ) );
}


=head2 success

Handler for successful payment

=cut

sub success : Chained( 'base' ) : PathPart( 'success' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Log the transaction
	$c->stash->{ user }->transaction_logs->create({
		status => 'Success',
		notes  => 'Transaction ID: '. $c->request->param( 'transaction_id' ), # TODO
	});

	# Email site owner to prompt despatch of goods
	$c->forward( 'send_order_received_email' );

	# Adjust quantities of goods
	my @items = $c->stash->{ order }->order_items->all;
	foreach my $item ( @items ) {
		$item->item->update({ stock => $item->item->stock - $item->quantity })
			unless $item->item->stock == undef;
	}

	# Email order confirmation to customer
	$c->forward( 'send_order_confirmation_email' );

	$c->response->body( 'Payment successful' );
	$c->detach;
}


=head2 send_order_received_email

Email site owner to prompt despatch of goods

TODO: Extract email body into template

=cut

sub send_order_received_email : Private {
	my ( $self, $c ) = @_;

	my $site_name = $c->config->{ site_name };
	my $site_url  = $c->uri_for( '/' );
	my $order     = $c->stash->{ order };
	my $username  = 'Somebody';
	$username     = $c->user->username if $c->user_exists;
	my $body1 = <<"EOT1";
You have received an order on $site_name!

$username has ordered the following goods:
EOT1

# TODO

$body1 .= <<"EOT2";

Requested delivery address:
$order->address
$order->town
$order->county
$order->postcode
$order->country

Their contact details in case of problems:
Email: $order->email
Phone: $order->telephone

--
$site_name
$site_url
EOT2

	$c->stash->{ email_data } = {
		from    => $site_name .' <'. $c->config->{ site_email } .'>',
		to      => $self->despatch_email,
		subject => 'Order placed on '. $site_name,
		body    => $body1,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 send_order_confirmation_email

Email order confirmation to customer

TODO: Extract email body into template

=cut

sub send_order_confirmation_email : Private {
	my ( $self, $c ) = @_;

	my $site_name = $c->config->{ site_name };
	my $site_url  = $c->uri_for( '/' );
	my $order     = $c->stash->{ order };

	my $body = <<"EOT1";
Thank you for placing an order on $site_name!

We will shortly be despatching the following goods to you:

EOT1

# TODO

$body .= <<"EOT2";
--
$site_name
$site_url
EOT2

	$c->stash->{ email_data } = {
		from    => $site_name .' <'. $c->config->{ site_email } .'>',
		to      => $order->email,
		subject => 'Order confirmation from '. $site_name,
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 fail

Handler for failed payment

=cut

sub fail : Chained( 'base' ) : PathPart( 'fail' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Log the transaction
	$c->stash->{ user }->transaction_logs->create({
		status => 'Failed',
		notes  => 'Enc: '. $c->request->param( 'enc' ),
	});

	$c->response->body( 'Sorry, your payment was not successful.' );
	$c->detach;
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
