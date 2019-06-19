# ===================================================================
# File:		t/admin-controllers/controller_Admin-Polls.t
# Project:	ShinyCMS
# Purpose:	Tests for poll admin features
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


# Create and log in as a Poll Admin
my $admin = create_test_admin( 'test_admin_polls', 'Poll Admin' );
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Poll Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Polls - ShinyCMS',
	'Redirected to admin area for polls'
);


# Add a new poll
$t->follow_link_ok(
	{ text => 'Add poll' },
	'Follow link to add a new poll'
);
$t->title_is(
	'Add Poll - ShinyCMS',
	'Reached page for adding new poll'
);
$t->submit_form_ok({
	form_id => 'edit_poll',
	fields => {
		question => 'Can we create new polls?'
	}},
	'Submitted form to create poll'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Loaded poll editing page'
);
my @inputs1 = $t->grep_inputs({ name => qr{^question$} });
ok(
	$inputs1[0]->value eq 'Can we create new polls?',
	'Verified that new poll was successfully created'
);

# Clear the question and hide the poll
$t->submit_form_ok({
	form_id => 'edit_poll',
	fields => {
		question => undef,
		hidden   => 'on'
	}},
	'Submitted form to save poll as hidden and with blank question text'
);
# Update the question
$t->submit_form_ok({
	form_id => 'edit_poll',
	fields => {
		question => 'What can we do with polls?'
	}},
	'Submitted form to save poll with updated question text'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Reloaded poll editing page'
);
my @inputs2 = $t->grep_inputs({ name => qr{^question$} });
ok(
	$inputs2[0]->value eq 'What can we do with polls?',
	'Successfully updated poll question'
);

# Add a new answer
$t->submit_form_ok({
	form_id => 'add_answer',
	fields => {
		new_answer => 'We can add answers.'
	}},
	'Submitted form to add new answer to poll'
);
my @inputs3 = $t->grep_inputs({ name => qr{^answer_\d+$} });
ok(
	$inputs3[0]->value eq 'We can add answers.',
	'Verifed that new answer was successfully added to poll'
);

# TODO: Alter vote counts (feature doesn't exist yet!)
$t->submit_form_ok({
	form_id => 'edit_poll',
	fields => {
		answer_1_votes => '100',
	}},
	'Submitted form to save poll with altered vote counts'
);
my @inputs4 = $t->grep_inputs({ name => qr{^answer_\d+_votes$} });
#ok(
#	$inputs4[0]->value eq '100',
#	'Vote counts were successfully updated'
#);

# Delete a poll (can't use submit_form_ok due to javascript confirmation)
my @inputs5 = $t->grep_inputs({ name => qr{^poll_id$} });
my $id = $inputs5[0]->value;
$t->post_ok(
	'/admin/polls/save',
	{
		poll_id => $id,
		delete  => 'Delete'
	},
	'Submitted request to delete poll'
);
# View list of polls
$t->title_is(
	'List Polls - ShinyCMS',
	'Viewing list of polls in admin area'
);
$t->content_lacks(
	'What can we do with polls?',
	'Verified that poll was deleted'
);

# Look at second page of data, to make Devel::Cover happy
$t->get_ok(
	$t->uri->path . '?page=2',
	'Fetch second page of data'
);


# Log out, then try to access admin area for polls again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of poll admin account'
);
$t->get_ok(
	'/admin/polls',
	'Try to access admin area for polls after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Now try again with no relevant privs and make sure we're shut out
my $news_admin = create_test_admin( 'test_admin_polls_news_admin', 'News Admin' );
$t = login_test_admin( $news_admin->username, $news_admin->username )
	or die 'Failed to log in as News Admin';
$t->get_ok(
	'/admin/polls',
	'Attempt to fetch poll admin area as News Admin'
);
$t->title_unlike(
	qr{^.*Poll.* - ShinyCMS$},
	'Failed to reach poll admin area without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $news_admin );
remove_test_admin( $admin      );

done_testing();
