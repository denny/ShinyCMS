# ===================================================================
# File:		t/admin-controllers/controller_Admin-Events.t
# Project:	ShinyCMS
# Purpose:	Tests for event admin features
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

use lib 't/support';
require 'login_helpers.pl';  ## no critic


# Create and log in as an Events Admin
my $admin = create_test_admin(
	'test_admin_events',
	'Events Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Events Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Events Admin' ),
	'Logged in as Events Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Events - ShinyCMS',
	'Redirected to admin area for events'
);


# Add a new event
$t->follow_link_ok(
	{ text => 'Add new event' },
	'Follow link to add a new event'
);
$t->title_is(
	'Add event - ShinyCMS',
	'Reached page for adding new event'
);
$t->submit_form_ok({
	form_id => 'add_event',
	fields => {
		name	   => 'This is a test event',
		start_date => DateTime->now->ymd,
		end_date   => DateTime->now->ymd,
	}},
	'Submitted form to create new event'
);
$t->title_is(
	'Edit event - ShinyCMS',
	'Redirected to edit page for newly created event'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$inputs1[0]->value eq 'this-is-a-test-event',
	'Verified that event was created'
);

# Update event
$t->submit_form_ok({
	form_id => 'edit_event',
	fields => {
		name => 'Updated test event',
	}},
	'Submitted form to update event name'
);
$t->submit_form_ok({
	form_id => 'edit_event',
	fields => {
		url_name => '',
	}},
	'Submitted form to update event url_name'
);
my @inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$inputs2[0]->value eq 'Updated test event',
	'Verified that event was updated'
);
# Save event ID for use when deleting
my @inputs3 = $t->grep_inputs({ name => qr{^event_id$} });
my $event1_id = $inputs3[0]->value;

# Create second event, to test hidden condition
$t->follow_link_ok(
	{ text => 'Add new event' },
	'Follow link to add another new event'
);
$t->submit_form_ok({
	form_id => 'add_event',
	fields => {
		name	   => 'This is a hidden test event',
		url_name   => 'hidden-test-event',
		start_date => DateTime->now->ymd,
		end_date   => DateTime->now->ymd,
		hidden     => 'on',
	}},
	'Submitted form to create hidden test event'
);
my @inputs4 = $t->grep_inputs({ name => qr{^event_id$} });
my $event2_id = $inputs4[0]->value;

# Delete events (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/events/edit-event-do/'.$event1_id,
	{
		event_id => $event1_id,
		delete   => 'Delete'
	},
	'Submitted request to delete event'
);
$t->post_ok(
	'/admin/events/edit-event-do/'.$event2_id,
	{
		event_id => $event2_id,
		delete   => 'Delete'
	},
	'Submitted request to delete event'
);
# View list of events
$t->title_is(
	'List Events - ShinyCMS',
	'Reached list of events'
);
$t->content_lacks(
	'Updated test event',
	'Verified that the first event was deleted'
);
$t->content_lacks(
	'This is a hidden test event',
	'Verified that the hidden test event was deleted'
);


# Log out, then try to access admin area for events again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of event admin account'
);
$t->get_ok(
	'/admin/events',
	'Try to access admin area for events after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_events_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/events',
	'Attempt to fetch events admin area as a Poll Admin'
);
$t->title_unlike(
	qr{^.*Event.* - ShinyCMS$},
	'Failed to reach events admin area without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
