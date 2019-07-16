# ===================================================================
# File:		t/admin-controllers/controller_Admin-Users.t
# Project:	ShinyCMS
# Purpose:	Tests for user admin features
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


my $admin = create_test_admin( 'test_admin_users', 'User Admin' );

my $schema = get_schema();

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );


# Try to fetch the admin area, expecting to fail and be asked to log in first
$t->get_ok(
	'/admin',
	'Try to fetch page in admin area'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Admin area requires login'
);

# Submit admin login form
$t->submit_form_ok({
	form_id => 'login',
	fields => {
		username => $admin->username,
		password => $admin->username,
	}},
	'Submit login form'
);
$t->content_contains(
	'Logout',
	'Login attempt successful'
);
# Fetch the admin area again
$t->get_ok(
	'/admin',
	'Fetch admin area again'
);


# TODO: Roles and User Roles


# TODO: Access and User Access


# Add a new user
$t->follow_link_ok(
	{ text => 'Add user' },
	'Follow link to add a new user'
);
$t->title_is(
	'Add new user - ShinyCMS',
	'Reached page for adding new users'
);
my $test_data_email = 'test_email@shinycms.org';
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		username => 'test_username',
		password => 'test_password',
		email    => $test_data_email,
		allow_comments => 'on',
	}},
	'Submitted form to create new user'
);
$t->title_is(
	'Edit user - ShinyCMS',
	'Redirected to edit page for new user'
);
my @inputs1 = $t->grep_inputs({ name => qr{^email$} });
ok(
	$inputs1[0]->value eq $test_data_email,
	'Verified that user was created'
);

# Update user details
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		admin_notes  => 'User updated by test suite',
		date_group_1 => DateTime->now->ymd,
		time_group_1 => DateTime->now->hms,
	}},
	'Submitted form to update user notes and access'
);
my @inputs2 = $t->grep_inputs({ name => qr{^admin_notes$} });
ok(
	$inputs2[0]->value eq 'User updated by test suite',
	'Verified that user was updated'
);
my @inputs3 = $t->grep_inputs({ name => qr{^user_id$} });
my $user_id = $inputs3[0]->value;
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		date_group_1 => 'never',
	}},
	'Submitted form to update user access again'
);

# Add a new user with a clashing username
$t->follow_link_ok(
	{ text => 'Add user' },
	'Follow link to add another new user'
);
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		username => 'test_username',
		password => 'test_password',
		email    => $test_data_email,
	}},
	'Submitted form to create new user with same username as existing user'
);
$t->title_is(
	'Add new user - ShinyCMS',
	'Redirected back to Add User page'
);
$t->text_contains(
	'That username already exists',
	'Adding user with duplicate username failed'
);


# Fetch the list of users
$t->follow_link_ok(
	{ text => 'List users' },
	'Click on link to view list of users in admin area'
);
$t->title_is(
	'List Users - ShinyCMS',
	'Reached user list in admin area'
);

# Search users
$t->submit_form_ok({
	form_id => 'search_users',
	fields => {
		query => 'test_admin_users',
	}},
	'Submitted form to search users'
);
$t->text_contains(
	'test_admin_users@example.com',
	'Search returned matching users'
);
$t->back;

# Change password
$t->follow_link_ok(
	{ text => 'Change Password' },
	"Click on link to change user's password"
);
$t->title_like(
	qr{Change Password for \w+ - ShinyCMS},
	'Reached page for changing user password'
);


# ...


# Look at file access logs for a user
# TODO: this is one of the few admin area tests that relies on the demo data being loaded
my $logs_user_id = $schema->resultset( 'FileAccess' )->first->user->id;
$t->follow_link_ok(
	{ text => 'List users' },
	'Click on link to load user list again'
);
$t->follow_link_ok(
	{ url_regex => qr{/admin/users/user/$logs_user_id/file-access-logs$} },
	"Go back to user list, click link to view file access logs for user $user_id"
);
$t->title_like(
	qr{^Access logs for: [-\w]+ - ShinyCMS$},
	'Reached file access logs'
);


# Delete user (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/users/edit-do',
	{
		user_id => $user_id,
		delete  => 'Delete'
	},
	'Submitted request to delete user'
);
# View list of users
$t->title_is(
	'List Users - ShinyCMS',
	'Reached list of users'
);
$t->content_lacks(
	$test_data_email,
	'Verified that user was deleted'
);


# Log in as the wrong sort of admin, and make sure we're blocked
my $poll_admin = create_test_admin( 'test_admin_users_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/users',
	'Attempt to fetch user admin area as Poll Admin'
);
$t->title_unlike(
	qr{^.*User.* - ShinyCMS$},
	'Failed to reach user admin area without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
