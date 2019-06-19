# ===================================================================
# File:		t/admin-controllers/controller_Admin-News.t
# Project:	ShinyCMS
# Purpose:	Tests for news admin features
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


# Create and log in as a News Admin
my $admin = create_test_admin(
	'test_admin_news',
	'News Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as News Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'News Admin' ),
	'Logged in as News Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List News Items - ShinyCMS',
	'Redirected to admin area for news'
);


# Add a news item
$t->follow_link_ok(
	{ text => 'Add news item' },
	'Follow link to add a news item'
);
$t->title_is(
	'Add News Item - ShinyCMS',
	'Reached page for adding news item'
);
$t->submit_form_ok({
	form_id => 'add_item',
	fields => {
		title => 'This is some test news'
	}},
	'Submitted form to create news item'
);
$t->title_is(
	'Edit News Item - ShinyCMS',
	'Redirected to edit page for newly created news item'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_title$} });
ok(
	$inputs1[0]->value eq 'this-is-some-test-news',
	'Verified that news item was created'
);

# Update news item
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		title	 => 'News item updated by test suite',
		url_title => ''
	}},
	'Submitted form to update news item title'
);
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		posted_date => DateTime->now->ymd,
		posted_time => '12:34:56',
		hidden	    => 'on'
	}},
	'Submitted form to update news item date, time, and hidden status'
);
my @inputs2 = $t->grep_inputs({ name => qr{^title$} });
ok(
	$inputs2[0]->value eq 'News item updated by test suite',
	'Verified that news item was updated'
);
my @inputs3 = $t->grep_inputs({ name => qr{^item_id$} });
my $item1_id = $inputs3[0]->value;

# Create second news item to test hidden and url_title conditions
$t->follow_link_ok(
	{ text => 'Add news item' },
	'Follow link to add a second news item'
);
$t->submit_form_ok({
	form_id => 'add_item',
	fields => {
		title     => 'This is a hidden news item',
		url_title => 'hidden-news-item',
		hidden    => 'on',
	}},
	'Submitted form to create hidden news item'
);
my @inputs4 = $t->grep_inputs({ name => qr{^item_id$} });
my $item2_id = $inputs4[0]->value;

# Load second page of news items
$t->get_ok(
	'/admin/news?page=2&count=5',
	'Fetch news admin area, with paging params'
);
$t->title_is(
	'List News Items - ShinyCMS',
	'Loaded second page of news admin area'
);

# Delete news items (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/news/edit-do/'.$item1_id,
	{
		item_id => $item1_id,
		delete  => 'Delete'
	},
	'Submitted request to delete first news item'
);
$t->post_ok(
	'/admin/news/edit-do/'.$item2_id,
	{
		item_id => $item2_id,
		delete  => 'Delete'
	},
	'Submitted request to delete hidden news item'
);
# View list of news items
$t->title_is(
	'List News Items - ShinyCMS',
	'Reached list of news items'
);
$t->content_lacks(
	'News item updated by test suite',
	'Verified that first item was deleted'
);
$t->content_lacks(
	'This is a hidden news item',
	'Verified that hidden item was deleted'
);


# Log out, then try to access admin area for news again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of news admin account'
);
$t->get_ok(
	'/admin/news',
	'Try to access admin area for news after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_news_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/news',
	'Attempt to fetch news admin area as Poll Admin'
);
$t->title_unlike(
	qr{^.*News.* - ShinyCMS$},
	'Failed to reach news admin area without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
