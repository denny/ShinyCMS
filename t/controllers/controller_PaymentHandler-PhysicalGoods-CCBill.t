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

# Get the key from the config
my $key = $config->{ 'Controller::PaymentHandler::PhysicalGoods::CCBill' }->{ key };

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

# Send STDERR to /dev/null to hide all the logging output this generates
{
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

}	# end of STDERR nullification

# ...

done_testing();
