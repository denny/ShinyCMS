package ShinyCMS::Controller::PaymentHandler::AccessSubscription::CCBill;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::PaymentHandler::AccessSubscription::CCBill

=head1 DESCRIPTION

Controller for handling payment for access subscriptions via CCBill.

=cut


__PACKAGE__->config->{ namespace } = 'payment-handler/access-subscription/ccbill';

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

=head2 base

Set up path etc

=cut

sub base : Chained( '/base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $key ) = @_;
	
	unless ( $key eq $self->key ) {
		$c->response->code( 403 );
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
		notes  => 'Subscription ID: '. $c->request->param( 'subscription_id' ),
	});
	
	# Find the access duration they've paid for
	my $duration        = $c->request->param( 'initialPeriod'   );
	my $subscription_id = $c->request->param( 'subscription_id' );
	my $recurring       = $c->request->param( 'recurringPeriod' ) || undef;
	
	# Find the access type
	my $access = $c->model( 'DB::Access' )->find({
		access => $self->access,
	});
	
	# Check to see if the user already has access
	my $user_access = $c->stash->{ user }->user_accesses->find({
		access => $access->id,
	});
	my $now = DateTime->now;
	if ( $user_access and $user_access->expires > $now ) {
		# Extend the access period
		my $expires = $user_access->expires;
		my $expiry = $expires->add( days => $duration, hours => 1 );
		$user_access->update({
			expires         => $expiry,
			subscription_id => $subscription_id,
			recurring       => $recurring,
		});
	}
	else {
		# Set the user's access up
		my $expiry = DateTime->now->add( days => $duration, hours => 1 );
		$c->stash->{ user }->user_accesses->update_or_create({
			access          => $access->id,
			expires         => $expiry,
			subscription_id => $subscription_id,
			recurring       => $recurring,
		});
	}
	
	$c->response->body( 'Payment successful' );
	$c->detach;
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
