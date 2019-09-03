# ===================================================================
# File:		t/controllers/controller-Newsletters.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS newsletter controller
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

# Get a connected Schema object
my $schema = get_schema();

# Get a Mech object
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Get the list of recent newsletters
$t->get_ok(
	'/newsletters',
	'Fetch list of newsletters'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Loaded list of newsletters'
);
# View an individual newsletter
$t->follow_link_ok(
	{ text => 'Donations and a word to teachers and librarians' },
	'Click on link to view newsletter'
);
$t->content_contains(
	"<h1>\n\tDonations and a word to teachers and librarians\n</h1>",
	'Loaded newsletter'
);
# Try to fetch a non-existent newsletter
$t->get_ok(
	'/newsletters/2012/01/does-not-exist',
	'Try to view a non-existent newsletter'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Redirected back to list of newsletters instead'
);
$t->text_contains(
	'Specified newsletter not found',
	'Got helpful error message about missing newsletter'
);
# Give paging code some basic exercise
$t->get_ok(
	'/newsletters/view?page=2&count=5',
	'Fetch second page of newsletter list, 5 items per page'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Loaded list of newsletters'
);

# Try to view mailing list subscriptions before logging in
$t->get_ok(
	'/newsletters/lists',
	'Try to view mailing list subscriptions, before logging in'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'You need to log in before you can edit your mailing list subscriptions',
	'... and got a message telling us to log in'
);

# Try to view mailing list subscriptions, not logged in, using an invalid token
$t->get_ok(
	'/newsletters/lists/this-is-not-the-token-you-are-looking-for',
	'Try to view mailing list subscriptions, using non-existent token'
);
$t->text_contains(
	'Subscriber not found.',
	'Got appropriate error message'
);

# Try to view mailing list subscriptions, not logged in, using a valid token
$t->get_ok(
	'/newsletters/lists/abcd1234abcd1234abcd1234abcd3333',
	'Try to view mailing list subscriptions, using token'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'You can only see the private lists that you are currently subscribed to.',
	'Can see list subscriptions, including private lists'
);

# Submit an update to list subscriptions, identifying with an invalid token
$t->post_ok(
	'/newsletters/lists/update',
	{
		token => 'MADE_OF_FAIL',
	},
	'Try to update subscription data using an invalid token'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Got bounced to the lists page'
);
$t->text_contains(
	'No email address specified.',
	'Got error message stating that no email address was specified'
);

# Log in
$t = login_test_user( 'admin', 'changeme' ) or die 'Failed to log in';
my $c = $t->ctx;
ok(
	$c->user->username eq 'admin',
	'Logged in as default admin from demo data'
);
# Try to view mailing list subscriptions after logging in
$t->get_ok(
	'/newsletters/lists',
	'Try to view mailing list subscriptions, after logging in'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'To subscribe to a list, check the box next to it.',
	'Reached subscribe/unsubscribe page for mailing lists'
);
# Get checkbox values
$t->form_id( 'list_subs' );
my @inputs1 = $t->current_form->find_input( 'lists' );
my @values1;
foreach my $input1 ( @inputs1 ) {
	push @values1, $input1->value if $input1->value;
}
ok(
	"@values1" eq '3 2',
	'Curently subscribed to lists 3 and 2'
);
# Update subscription selections
# (unsubscribe from list 3, subscribe to lists 4 and 5, leave list 2 as it is)
$t->form_id( 'list_subs'  );
$t->untick(  'lists', '3' );
$t->tick(    'lists', '4' );
$t->tick(    'lists', '5' );
$t->submit_form();
$t->text_contains(
	'Your subscriptions have been updated',
	'Submitted form to update subscriptions'
);
# Get checkbox values again
$t->form_id( 'list_subs' );
my @inputs2 = $t->current_form->find_input( 'lists' );
my @values2;
foreach my $input2 ( @inputs2 ) {
	push @values2, $input2->value if $input2->value;
}
ok(
	"@values2" eq '4 5 2',
	'Curently subscribed to lists 4, 5, and 2'
);

# Reset mailing list subscriptions to starting values
$t->get( '/newsletters/lists' );
$t->form_id( 'list_subs'  );
$t->tick(    'lists', '3' );
$t->untick(  'lists', '4' );
$t->untick(  'lists', '5' );
$t->submit_form();


# Subscribe to an autoresponder
$t->post_ok(
	'/newsletters/autoresponder/subscribe',
	{
		autoresponder => 'example',
		name          => 'Test AR Sub',
		email         => 'test_ar_sub@shinycms.org',
		'g-recaptcha-response' => 'fake',
	},
	'Attempt to subscribe to an autoresponder'
);
$t->title_is(
	'Home - ShinySite',
	'Got redirected to homepage after submitting subscribe form'
);
$t->text_contains(
	'Subscription successful.',
	'Got confirmation message'
);
# Do it again, to poke the 'existing recipient' code
$t->post_ok(
	'/newsletters/autoresponder/subscribe',
	{
		autoresponder => 'example',
		name          => 'Test Autoresponder Subscriber',
		email         => 'test_ar_sub@shinycms.org',
		status_msg    => 'Test subscription successful.',
		redirect_url  => '/newsletters/lists',
		'g-recaptcha-response' => 'fake',
	},
	'Subscribe same recipient again, with custom success message and redirect'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Got redirected to mailing lists page this time'
);
$t->text_contains(
	'Test subscription successful.',
	'Got custom confirmation message'
);

# Test error handling
$t->add_header( Referer => undef );
$t->post_ok(
	'/newsletters/autoresponder/subscribe',
	{
		autoresponder => 'example',
		name          => 'Test AR Sub Fail',
		email         => 'test_ar_sub_fail@shinycms.org',
	},
	'Post to autoresponder subscribe endpoint without recaptcha param'
);
$t->text_contains(
	'You must fill in the reCaptcha.',
	'Got helpful error message'
);
$t->post_ok(
	'/newsletters/autoresponder/subscribe',
	{
		name          => 'Test AR Sub Fail',
		email         => 'test_ar_sub_fail@shinycms.org',
		'g-recaptcha-response' => 'fake',
	},
	'Post to autoresponder subscribe endpoint without specifying autoresponder'
);
$t->text_contains(
	'No autoresponder specified.',
	'Got helpful error message'
);
$t->post_ok(
	'/newsletters/autoresponder/subscribe',
	{
		autoresponder => 'example',
		name          => 'Test AR Sub Fail',
		'g-recaptcha-response' => 'fake',
	},
	'Post to autoresponder subscribe endpoint without email param'
);
$t->text_contains(
	'No email address provided.',
	'Got helpful error message'
);


# Tidy up
$schema->resultset( 'Autoresponder' )->search({ url_name => 'example' })
	->first->autoresponder_emails->search_related('queued_emails')->delete;

done_testing();
