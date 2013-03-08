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


has key => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);


=head1 METHODS

=head2 index

Shouldn't be here - redirect to homepage

=cut

sub index : Path : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	# Shouldn't be here
	$c->response->redirect( '/' );
}


=head2 base

Set up path etc

=cut

sub base : Chained( '/' ) : PathPart( 'paymenthandler/physicalgoods/ccbill' ) : CaptureArgs( 1 ) {
    my ( $self, $c, $key ) = @_;
	
	unless ( $key eq $self->key ) {
		$c->response->code( '403' );
		$c->response->body( 'Access forbidden.' );
		$c->detach;
	}
	
	# Find the order
	if ( $c->request->param( 'shinycms_order_id' ) ) {
		$c->stash->{ user } = $c->model( 'DB::Order' )->find({
			id => $c->request->param( 'shinycms_order_id' ),
		});
	}
}


=head2 success

Handler for successful payment

=cut

sub success : Chained( 'base' ) : PathPart( 'success' ) : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	# Log the transaction
	$c->stash->{ user }->ccbill_logs->create({
		status => 'Success',
		notes  => 'TODO',
	});
	
	
	# TODO
	
	
	$c->response->body( 'Payment successful' );
	$c->detach;
}


=head2 fail

Handler for failed payment

=cut

sub fail : Chained( 'base' ) : PathPart( 'fail' ) : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	# Log the transaction
	$c->stash->{ user }->ccbill_logs->create({
		status => 'Failed',
		notes  => 'Enc: '. $c->request->param( 'enc' ),
	});
	
	$c->response->body( 'Sorry, your payment was not successful.' );
	$c->detach;
}



=head1 AUTHOR

Denny de la Haye <2013@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2013 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at 
your option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

