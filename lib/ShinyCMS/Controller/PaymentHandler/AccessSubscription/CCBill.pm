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


=head2 get_user

Find the user account to connect the access subscription to

=cut

sub get_user : Chained( 'check_key' ) : PathPart( '' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Find the user
	my $username = $c->request->param( 'shinycms_username' );

	if ( $c->request->uri->path !~ m{/success$} and not $username ) {
		$c->log->warn( 'Incomplete data received for failed CCBill payment' );
		# Return a 200 to prevent retries, but otherwise die here
		$c->response->code( 200 );
		$c->response->body( 'Incomplete data provided; unable to find user' );
		$c->detach;
	}

	my $user;

	if ( $username ) {
		$user = $c->stash->{ user } = $c->model( 'DB::User' )->find({
			username => $username,
		});
		$c->log->warn( "User not found for username: $username" ) unless $user;
	}
	else {
		$c->log->warn(
			'Incomplete data received for SUCCESSFUL CCBill payment: '.
			'shinycms_username was missing'
		);
	}

	# Attempt to rescue cases where CCBill doesn't pass through our username,
	# or a bad username was passed in (which shouldn't happen, but hey)
	unless ( $user ) {
		my $email = $c->request->param( 'email' );
		if ( $email ) {
			$user = $c->stash->{ user } = $c->model( 'DB::User' )->search({
				email => $c->request->param( 'email' ),
			})->single;
			$c->log->warn( "User not found for email: $email" ) unless $user;
		}
		else {
			$c->log->warn(
				'Incomplete data received for SUCCESSFUL CCBill payment: '.
				'email was missing'
			);
		}
	}

	# Stil failed to find the user
	unless ( $user ) {
		$c->log->error( 'User not found for SUCCESSFUL CCBill payment' );

		# Clone POST data, removing credit card details and most personal data
		# (We do log the email address, for debugging and customer service)
		my $params = { %{ $c->request->params } };
		delete $params->{ cardType       };
		delete $params->{ customer_fname };
		delete $params->{ customer_lname };
		delete $params->{ address1       };
		delete $params->{ city           };
		delete $params->{ state          };
		delete $params->{ country        };
		delete $params->{ phone_number   };
		delete $params->{ zipcode        };
		delete $params->{ ip_address     };
		# 'username' and 'password' should be empty; only log if they're not
		delete $params->{ username } unless $params->{ username };
		delete $params->{ password } unless $params->{ password };
		# If 'password' is set, overwrite it - we don't want to log real passwords
		$params->{ password } = 'PASSWORD WAS NOT EMPTY' if $params->{ password };
		# Denial/Decline stuff should be empty for a successful payment;
		# again, only log them if they're not empty
		delete $params->{ denialId             } unless $params->{ denialId             };
		delete $params->{ reasonForDecline     } unless $params->{ reasonForDecline     };
		delete $params->{ reasonForDeclineCode } unless $params->{ reasonForDeclineCode };

		# Log the sanitised POST data
		use Data::Dumper;
		$Data::Dumper::Sortkeys = 1;
		$c->log->debug( Data::Dumper->Dump( [ $params ], [ 'CCBill_data' ] ) );

		# Email the site admin  TODO: make this configurable
		my $site_name  = $c->config->{ site_name  };
		my $site_email = $c->config->{ site_email };
		my $site_url   = $c->uri_for( '/' );
		my $body = <<"EOT";
CCBill just sent us incomplete data for a successful payment - specifically,
they did not send us the ShinyCMS username for the person who made the payment.
They also either did not send their email, or we could not connect the
email to a user account.

Without this data, ShinyCMS has no way of telling which account to upgrade,
which means that currently somebody has paid for access but did not get it. :(


Here is the data that CCBill did send us (name and address have been removed):

$params


--
$site_name
$site_url
EOT
		$c->stash->{ email_data } = {
			from    => $site_name .' <'. $site_email .'>',
			to      => $site_email,
			subject => 'CCBill payment problem on '. $site_name,
			body    => $body,
		};
		$c->forward( $c->view( 'Email' ) );

		# Return a 200 to prevent retries, but otherwise die here
		$c->response->code( 200 );
		$c->response->body( 'Incomplete or bad data provided; unable to find user' );
		$c->detach;
	}
}


=head2 success

Handle a payment attempt which succeeded at CCBill's end

=cut

sub success : Chained( 'get_user' ) : PathPart( 'success' ) : Args( 0 ) {
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

sub fail : Chained( 'get_user' ) : PathPart( 'fail' ) : Args( 0 ) {
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
