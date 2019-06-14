# ===================================================================
# File:		t/controllers/controller_PaymentHandler-AccessSubscription-CCBill.t
# Project:	ShinyCMS
# Purpose:	Tests for CCBill access subscription payment handler
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

# Get a hashref of the site config (including test overrides, if any)
my $config = get_config();

# Get a database-connected schema object
my $schema = get_schema();

# Get a mech
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Create a test user
my $user = create_test_user( 'test_paymenthandler_accesssubscription_ccbill' );
ok(
	ref $user eq 'ShinyCMS::Schema::Result::User',
	'Created new test user'
);

# Fetch the access groups from the demo data
my $access_groups = $schema->resultset( 'Access' )->search;
ok(
	$access_groups->count == 4,
	'Found 4 pre-defined access groups in demo data'
);
my @access_names = $access_groups->get_column( 'access' )->all;
my $access_names = join ',', ( sort @access_names );
ok(
	$access_names eq 'Eternal,Exclusive,Expired,Unexpired',
	'Access group names as expected: Eternal, Exclusive, Expired, Unexpired'
);

# Get the key from the config
my $key = $config->{ 'Controller::PaymentHandler::AccessSubscription::CCBill' }->{ key };

# Confirm lack of pre-existing access subscriptions for this user
ok(
	$user->user_accesses->count == 0,
	'Test user has no pre-existing access subscriptions'
);

# Check that URL-munging gets what it deserves
$t->post( '/payment-handler/access-subscription/ccbill' );
ok(
	$t->status == 400,
	'Attempting to access Payment Handler without any params is a Bad Request'
);
$t->post(
	"/payment-handler/access-subscription/ccbill/$key",
	content => {
		shinycms_username => $user->username,
	}
);
ok(
	$t->status == 400,
	'Attempting to access Payment Handler without specifying action is a Bad Request'
);

# Invalid key
$t->post( '/payment-handler/access-subscription/ccbill/INVALID-KEY/success' );
ok(
	$t->status == 403,
	'Attempting to access Payment Handler with an invalid key is Forbidden'
);

# Valid key for failed payment, but no username in post data
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/fail",
	{
		enc => 'Made of fail',
	},
	'Post to fail endpoint with valid key, but no username in post data'
);
$t->text_contains(
	'Incomplete data: shinycms_username was missing',
	'Failed early, due to missing username (but returned 200 to prevent retries)'
);

# Valid key for successful payment, but no username in post data
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/success",
	{
		wut => 'Faily McFailface',
		enc => 'Made of fail',
	},
	'Post to success endpoint with valid key, but no username in post data'
);
$t->text_contains(
	'Incomplete data: shinycms_username was missing',
	'Failed early, due to missing username (but returned 200 to prevent retries)'
);
# And again, to poke all the 'remove this param if it's empty' conditions
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/success",
	{
		username => 'test',
		password => 'test',
		denialId => 'test',
		reasonForDecline => 'test',
		reasonForDeclineCode => 'test',
	},
	'Same again, but with all the should-be-empty params set, for the lols'
);

# Valid fail
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/fail",
	{
		shinycms_username => $user->username,
		enc => 'Made of fail',
	},
	'Valid post to fail endpoint'
);
ok(
	$user->user_accesses->count == 0,
	'User still has no access subscriptions'
);

# Success!
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/success",
	{
		shinycms_username => $user->username,
		subscription_id   => 'TEST-ONE-WEEK-ONE-OFF',
		initialPeriod     => '7',
	},
	'Valid post to success endpoint with one-off, one week subscription'
);
ok(
	$user->user_accesses->count == 1,
	'User has gained an access subscription'
);
$t->post_ok(
	"/payment-handler/access-subscription/ccbill/$key/success",
	{
		shinycms_username => $user->username,
		subscription_id   => 'TEST-MONTHLY-RECURRING',
		initialPeriod     => '30',
		recurringPeriod   => '30',
	},
	'Valid post to success endpoint with recurring monthly subscription'
);
ok(
	$user->user_accesses->count == 1,
	'User still only has one access subscription'
);
ok(
	$user->user_accesses->first->recurring == 30,
	"User's access subscription is now marked as recurring"
);

# Tidy up
$user->transaction_logs->delete;
$user->user_accesses->delete;
remove_test_user( $user );

done_testing();
