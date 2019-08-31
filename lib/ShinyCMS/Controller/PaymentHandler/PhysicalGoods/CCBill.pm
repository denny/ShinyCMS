package ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill

=head1 DESCRIPTION

Controller for handling payment for physical goods via CCBill.

=cut


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

Set up path

=cut

sub base : Chained( '/base' ) : PathPart( 'payment-handler/physical-goods/ccbill' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 index

No key or action specified - bad request


=cut
sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'return_status', [ 400, 'Bad Request' ] );
}


=head2 check_key

Check the key from the URL against the key from the config file

=cut

sub check_key : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $key ) = @_;

	$c->go( 'return_status', [ 403, 'Access Forbidden' ] ) unless $key eq $self->key;
}


=head2 no_action

Got a valid key but no action (success/fail) - bad request

=cut

sub no_action : Chained( 'check_key' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'return_status', [ 400, 'Bad Request' ] );
}


=head2 get_order

Find the order that this payment relates to

=cut

sub get_order : Chained( 'check_key' ) : PathPart( '' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Get the order ID
	# TODO: Should this code be using a guid rather than the id column?
	my $order_id = $c->request->param( 'shinycms_order_id' );
	unless ( $order_id ) {
		if ( $c->request->uri->path =~ m{/success$} ) {
			$c->log->error( 'Incomplete data received for SUCCESSFUL CCBill payment' );

			# TODO: This is probably bad - somebody has paid and we don't know
			# who they are or what they paid for. Notify site owner, etc.
		}
		else {
			$c->log->warn( 'Incomplete data received for failed CCBill payment' );
		}

		# Return a 200 to prevent retries, but otherwise die here
		$c->go( 'return_status', [ 200, 'Incomplete data provided; missing order ID' ] );
	}

	# Find the order details
	$c->stash->{ order } = $c->model( 'DB::Order' )->find({
		id => $c->request->param( 'shinycms_order_id' ),
	});

	unless ( $c->stash->{ order } ) {
		if ( $c->request->uri->path =~ m{/success$} ) {
			$c->log->error( "Could not find order $order_id matching SUCCESSFUL payment" );
			
			# TODO: Again, this is bad - notify site owner, etc.
		}
		else {
			$c->log->warn( "Could not find order $order_id matching failed payment" );
		}

		# Return a 200 to prevent retries, but otherwise die here
		$c->go( 'return_status', [ 200, 'Could not find the specified order' ] );
	}
}


=head2 success

Handler for successful payment

=cut

sub success : Chained( 'get_order' ) : PathPart( 'success' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Log the transaction
	my $log_data = {
		status => 'Success',
		notes  => 'Transaction ID: '. $c->request->param( 'transaction_id' ), # TODO
	};
	$log_data->{ user } = $c->stash->{ order }->user->id if $c->stash->{ order }->user;
	$c->model( 'DB::TransactionLog' )->create( $log_data );

	# Update order status
	$c->stash->{ order }->update({ status => 'Payment received' });

	# Email site owner to prompt despatch of goods
	$c->forward( 'send_order_received_email' );

	# Adjust quantities of goods
	my @items = $c->stash->{ order }->order_items->all;
	foreach my $item ( @items ) {
		next unless defined $item->item->stock; 
		$item->item->update({ stock => $item->item->stock - $item->quantity });
	}

	# Email order confirmation to customer
	$c->forward( 'send_order_confirmation_email' );

	$c->response->body( 'Payment successful' );
	$c->detach;
}


=head2 fail

Handler for failed payment

=cut

sub fail : Chained( 'get_order' ) : PathPart( 'fail' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Log the transaction
	my $log_data = {
		status => 'Failed',
		notes  => 'Order ID: '. $c->stash->{ 'order' }->id .' | '.
					'Enc: '. $c->request->param( 'enc' ),
	};
	$log_data->{ user } = $c->stash->{ 'user' }->id if $c->stash->{ 'user' };
	$c->model( 'DB::TransactionLog' )->create( $log_data );

	$c->response->body( 'Unsuccessful payment attempt logged.' );
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


=head2 return_status

Return a basic status message and set HTTP status code

=cut

sub return_status : Private {
	my ( $self, $c, $code, $message ) = @_;

	$c->response->code( $code    );
	$c->response->body( $message );
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
