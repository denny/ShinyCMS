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

Set up path

=cut

sub base : Chained( '/base' ) : PathPart( 'payment-handler/access-subscription/ccbill' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 index

No key or action specified - bad request

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->response->code( 400 );
	$c->response->body( 'Bad Request' );
	$c->detach;
}


=head2 check_key

Check the key from the URL against the key from the config file

=cut

sub check_key : Chained( 'base' ) : PathPart( '' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $key ) = @_;

	unless ( $key eq $self->key ) {
		$c->response->code( 403 );
		$c->response->body( 'Access Forbidden' );
		$c->detach;
	}

	# Find the user
	if ( $c->request->param( 'shinycms_username' ) ) {
		$c->stash->{ user } = $c->model( 'DB::User' )->find({
			username => $c->request->param( 'shinycms_username' ),
		});
	}
	else {
		$c->log->error( 'Incomplete data received by CCBill payment handler' );
		my $params = $c->request->params; # TODO: sanitise this (remove card details etc)
		use Data::Dumper;
		$c->log->debug( Data::Dumper->Dump( [ $params ], [ 'c->request->params' ] ) );

		# TODO: Email the site admin

		# Return a 200 to prevent retries, but otherwise die here
		$c->response->code( 200 );
		$c->response->body( 'Incomplete data: shinycms_username was missing' );
		$c->detach;
	}
}


=head2 no_action

Got a valid key but no action (success/fail) - bad request

=cut

sub no_action : Chained( 'check_key' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->response->code( 400 );
	$c->response->body( 'Bad Request' );
	$c->detach;
}


=head2 success

Handle a payment attempt which succeeded at CCBill's end

=cut

sub success : Chained( 'check_key' ) : PathPart( 'success' ) : Args( 0 ) {
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

	$c->response->body( 'Access granted.' );
	$c->detach;
}


=head2 fail

Handle a payment attempt which failed at CCBill's end

=cut

sub fail : Chained( 'check_key' ) : PathPart( 'fail' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Log the transaction
	$c->stash->{ user }->transaction_logs->create({
		status => 'Failed',
		notes  => 'Enc: '. $c->request->param( 'enc' ),
	});

	$c->response->body( 'Payment failure logged.' );
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
