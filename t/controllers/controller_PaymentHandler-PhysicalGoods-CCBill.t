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


# TODO ...


done_testing();
