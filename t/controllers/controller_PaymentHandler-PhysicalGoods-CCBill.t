# ===================================================================
# File:		t/controllers/controller_PaymentHandler-PhysicalGoods-CCBill.t
# Project:	ShinyCMS
# Purpose:	Tests for CCBill payment handler for physical goods
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

# Get the CCBill key from the config
my $key = $config->{ 'Controller::PaymentHandler::PhysicalGoods::CCBill' }->{ key };

# Get a database-connected schema object
my $schema = get_schema();

# Get a mech
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );


# Check that URL-munging gets what it deserves
$t->post( '/payment-handler/physical-goods/ccbill' );
ok(
	$t->status == 400,
	'Accessing the Payment Handler without specifying a key is a Bad Request'
);
$t->post( "/payment-handler/physical-goods/ccbill/$key" );
ok(
	$t->status == 400,
	'Accessing the Payment Handler without specifying an action is a Bad Request'
);

# Invalid key
$t->post( '/payment-handler/physical-goods/ccbill/INVALID-KEY/success' );
ok(
	$t->status == 403,
	'Accessing the Payment Handler with an invalid key is Forbidden'
);

# Redirect STDERR to /dev/null while we run noisy tests
open my $origstderr, '>&', STDERR;
open STDERR, '>', File::Spec->devnull() or die "Could not open STDERR: $!";

# Failed transaction, with valid key but no order ID
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/fail",
	{
		enc => 'Made of fail',
	},
	'Post to fail endpoint with valid key, but no order ID in post data, logs a warning'
);
$t->text_contains(
	'Incomplete data provided; missing order ID',
	'Failed early, due to missing order ID (but returned 200 to prevent retries)'
);
# Failed transaction, with valid key but invalid order ID
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/fail",
	{
		shinycms_order_id => '99999',
	},
	'Post to fail endpoint with valid key but invalid order ID, logs a warning'
);
$t->text_contains(
	'Could not find the specified order',
	'Failed early, due to unknown order ID (but returned 200 to prevent retries)'
);
# Successful transaction, with valid key but no order ID
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/success",
	{
		enc => 'Made of fail',
	},
	'Post to success endpoint with valid key, but no order ID in post data, logs an error'
);
$t->text_contains(
	'Incomplete data provided; missing order ID',
	'Failed early, due to missing order ID (but returned 200 to prevent retries)'
);
# Successful CCBill transaction, with valid key but invalid order ID
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/success",
	{
		shinycms_order_id => '99999',
	},
	'Post to success endpoint with valid key but invalid order ID, logs an error'
);
$t->text_contains(
	'Could not find the specified order',
	'Failed early, due to unknown order ID (but returned 200 to prevent retries)'
);

# Restore STDERR
open STDERR, '>&', $origstderr or die "Can't restore stderr: $!";

# Set up some order data
my $user  = $schema->resultset('User' )->search->first;
my $order = $schema->resultset('Order')->find_or_create({
	user   => $user->id,
	email  => 'test@example.com',
	status => 'Awaiting payment',
	billing_address  => 'Test Suite',
	billing_town     => 'Testville',
	billing_postcode => 'TEST',
	billing_country  => 'Testland',
});

# Valid post to fail endpoint
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/fail",
	{
		shinycms_order_id => $order->id,
		enc => 'Made of fail, successfully',
	},
	'Valid post to fail endpoint'
);
$order->discard_changes;
ok(
	$order->status eq 'Awaiting payment',
	'Order has not been paid for'
);

# TODO: Valid post to success endpoint
$t->post_ok(
	"/payment-handler/physical-goods/ccbill/$key/success",
	{
		shinycms_order_id => $order->id,
		transaction_id => 'TEST1',
		enc => 'Success!',
	},
	'Valid post to success endpoint'
);
$order->discard_changes;
ok(
	$order->status eq 'Payment received',
	'Order has been paid for'
);

# ...

# Tidy up
$order->delete;

done_testing();
