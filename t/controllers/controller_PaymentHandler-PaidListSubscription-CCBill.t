# ===================================================================
# File:		t/controllers/controller_PaymentHandler-PaidListSubscription-CCBill.t
# Project:	ShinyCMS
# Purpose:	Tests for CCBill payment handler for paid list subscriptions
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
my $key = $config->{ 'Controller::PaymentHandler::PaidListSubscription::CCBill' }->{ key };

# Get a database-connected schema object
my $schema = get_schema();

# Get a mech
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );


# Check that URL-munging gets what it deserves
$t->post( '/payment-handler/paid-list-subscription/ccbill' );
ok(
	$t->status == 400,
	'Accessing the Payment Handler without specifying a key is a Bad Request'
);
$t->post( "/payment-handler/paid-list-subscription/ccbill/$key" );
ok(
	$t->status == 400,
	'Accessing the Payment Handler without specifying an action is a Bad Request'
);

# Invalid key
$t->post( '/payment-handler/paid-list-subscription/ccbill/INVALID-KEY/success' );
ok(
	$t->status == 403,
	'Accessing the Payment Handler with an invalid key is Forbidden'
);

# Create some test data
my $paid_list = $schema->resultset('PaidList')->find_or_create({
	name     => 'Test List (Paid)',
	url_name => 'test-list-paid',
});
my $template = $schema->resultset('NewsletterTemplate')->find_or_create({
	name     => 'Test Template',
	filename => 'test.tt',
});
my $paid_list_email = $paid_list->paid_list_emails->find_or_create({
	subject  => 'Test Paid List Email',
	template => $template->id,
	delay    => 3,
});

# Valid post to fail endpoint
my $queued_before_fail = $paid_list_email->queued_paid_emails->count;
$t->post_ok(
	"/payment-handler/paid-list-subscription/ccbill/$key/fail",
	{
		shinycms_list_id => $paid_list->id,
		enc              => 'Successful failure',
	},
	'Valid post to fail endpoint'
);
my $queued_after_fail = $paid_list_email->queued_paid_emails->count;
$t->text_contains(
	'Unsuccessful payment attempt was logged',
	'Unsuccessful payment attempt was logged'
);
ok(
	$queued_after_fail == $queued_before_fail,
	'Subscriber was not added to paid list'
);

# Valid post to success endpoint
my $queued_before_success = $schema->resultset('QueuedPaidEmail')->count;
$t->post_ok(
	"/payment-handler/paid-list-subscription/ccbill/$key/success",
	{
		shinycms_list_id  => $paid_list->id,
		shinycms_username => 'admin',
		transaction_id    => 'TEST1',
		enc               => 'Successful success 1',
	},
	'First valid post to success endpoint (identifying recipient by username)'
);
my $queued_after_success = $paid_list_email->queued_paid_emails->count;
ok(
	$queued_after_success == $queued_before_success + 1,
	'Subscriber was added to paid list'
);

# And post again, this time with email instead of username
$t->post_ok(
	"/payment-handler/paid-list-subscription/ccbill/$key/success",
	{
		shinycms_list_id => $paid_list->id,
		shinycms_email   => 'new.paid.subscriber@example.com',
		transaction_id   => 'TEST2',
		enc              => 'Successful success 2',
		status_msg       => 'Paid subscription test was successful',
		redirect_url     => '/',
	},
	'Second valid post to success endpoint (identifying recipient by email)'
);
my $queued_after_more_success = $paid_list_email->queued_paid_emails->count;
ok(
	$queued_after_more_success == $queued_after_success + 1,
	'Subscriber was added to paid list'
);

# Tidy up
$paid_list_email->queued_paid_emails->delete;
$paid_list_email->delete;
$paid_list->delete;
$template->delete;

done_testing();
