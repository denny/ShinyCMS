package ShinyCMS::Controller::PaymentHandler::Subscription::CCBill;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::PaymentHandler::Subscription::CCBill

=head1 DESCRIPTION

Controller for handling payment for subscriptions via CCBill.

=cut


has key => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);

has access => (
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

sub base : Chained( '/' ) : PathPart( 'paymenthandler/subscription/ccbill' ) : CaptureArgs( 1 ) {
    my ( $self, $c, $key ) = @_;
	
	unless ( $key eq $self->key ) {
		$c->response->code( '403' );
		$c->response->body( 'Access forbidden.' );
		$c->detach;
	}
	
	# Find the user
	if ( $c->request->param( 'shinycms_username' ) ) {
		$c->stash->{ user } = $c->model( 'DB::User' )->find({
			username => $c->request->param( 'shinycms_username' ),
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
		notes  => 'Subscription ID: '. $c->request->param( 'subscription_id' ),
	});
	
	# Find the access duration they've paid for
	my $duration = $c->request->param( 'initialPeriod' );
	my $now      = DateTime->now;
	my $expiry   = $now->add( days => $duration, hours => 1 );
	
	# Find the access type
	my $access = $c->model( 'DB::Access' )->find({
		access => $self->access,
	});
	
	# Check to see if the user already has access
	my $user_access = $c->stash->{ user }->user_accesses->find({
		access => $access->id,
	});
	
	if ( $user_access ) {
		# Extend the access period
		my $expires = $user_access->expires || $now;
		$expiry = $expires->add( days => $duration, hours => 1 );
		$user_access->update({
			expires => $expiry,
		});
	}
	else {
		# Set the user's access up
		$c->stash->{ user }->user_accesses->create({
			access  => $access->id,
			expires => $expiry,
		});
	}
	
	$c->response->body( 'Okay' );
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
	
	$c->response->body( 'Sorry' );
	$c->detach;
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

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

