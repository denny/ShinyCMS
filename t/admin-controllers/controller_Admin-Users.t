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


# Add a new role
$t->follow_link_ok(
	{ text => 'Add role' },
	'Follow link to add a new role'
);
$t->title_is(
	'Add Role - ShinyCMS',
	'Reached page for adding new roles'
);
$t->submit_form_ok({
	form_id => 'add_role',
	fields => {
		role => 'Test Role',
	}},
	'Submitted form to create new role'
);
$t->title_is(
	'Edit Role - ShinyCMS',
	'Redirected to edit page for new role'
);
$t->uri->path =~ m{/admin/users/role/(\d+)/edit};
my $role_id = $1;
$t->submit_form_ok({
	form_id => 'edit_role',
	fields => {
		role => 'Updated Test Role',
	}},
	'Submitted form to update role name'
);


# Add a new access group
$t->follow_link_ok(
	{ text => 'Add access group' },
	'Follow link to add a new access group'
);
$t->title_is(
	'Add Access Group - ShinyCMS',
	'Reached page for adding new access groups'
);
$t->submit_form_ok({
	form_id => 'add_access',
	fields => {
		access => 'Test Group',
	}},
	'Submitted form to create new access group'
);
$t->title_is(
	'Edit Access Group - ShinyCMS',
	'Redirected to edit page for new access group'
);
$t->uri->path =~ m{/admin/users/access-group/(\d+)/edit};
my $access_id = $1;
$t->submit_form_ok({
	form_id => 'edit_access',
	fields => {
		access => 'Test Access Group',
	}},
	'Submitted form to update access group name'
);


# Add a new user
$t->follow_link_ok(
	{ text => 'Add user' },
	'Follow link to add a new user'
);
$t->title_is(
	'Add User - ShinyCMS',
	'Reached page for adding new users'
);
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		username => 'test_username',
		password => 'test_password',
		email    => 'invalid@email',
	}},
	'Submitted form to create new user, with invalid email address'
);
$t->title_is(
	'Add User - ShinyCMS',
	'Redirected back to page for adding new users'
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
	'Submitted form to create new user, with valid email address'
);
$t->title_is(
	'Edit User - ShinyCMS',
	'Redirected to edit page for new user'
);
my @inputs1 = $t->grep_inputs({ name => qr{^email$} });
ok(
	$inputs1[0]->value eq $test_data_email,
	'Verified that user was created'
);
$t->uri->path =~ m{/admin/users/user/(\d+)/edit};
my $user_id = $1;

# Update user details
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		admin_notes  => 'User updated by test suite',
		date_group_1 => DateTime->now->ymd,
		time_group_1 => DateTime->now->hms,
		allow_comments => undef,
	}},
	'Submitted form to update user notes and access, and remove discussion'
);
my @inputs2 = $t->grep_inputs({ name => qr{^admin_notes$} });
ok(
	$inputs2[0]->value eq 'User updated by test suite',
	'Verified that user was updated'
);
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		date_group_1     => 'never',
		'role_'.$role_id => 'on',
	}},
	'Submitted form to update user access again, and add a role'
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
	'Add User - ShinyCMS',
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
	{ url_regex => qr{/admin/users/user/$user_id/change-password$} },
	"Click on link to change user's password"
);
$t->title_like(
	qr{Change Password for \w+ - ShinyCMS},
	'Reached page for changing user password'
);
$t->submit_form_ok({
	form_id => 'change_password',
	fields => {
		password_one => 'testing_password',
		password_two => 'different_password',
	}},
	'Submitted form to change password, with mismatched passwords'
);
$t->title_like(
	qr{Change Password for \w+ - ShinyCMS},
	'Redirected back to change password page'
);
$t->text_contains(
	'Passwords did not match',
	'Got error message about passwords not matching'
);
$t->submit_form_ok({
	form_id => 'change_password',
	fields => {
		password_one => 'testing_password',
		password_two => 'testing_password',
	}},
	'Submitted form to change password again, with matching passwords'
);
$t->title_is(
	'List Users - ShinyCMS',
	'Redirected back to user list'
);
$t->text_contains(
	'Password changed',
	'Verified that password was changed'
);


# ...


# Look at logins/IP logs for a user
$t->follow_link_ok(
	{ text => 'List users' },
	'Click on link to load user list'
);
$t->follow_link_ok(
	{ text => 'Logins' },
	"Click link to view file access logs for user 'admin'"
);
$t->title_is(
	'User Logins - ShinyCMS',
	'Reached list of login details for admin user'
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
	"Go back to user list, click link to view file access logs for user #$user_id"
);
$t->title_like(
	qr{^Access logs for: [-\w]+ - ShinyCMS$},
	'Reached file access logs'
);


# Delete user (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/users/save',
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

# Delete access group
$t->post_ok(
	"/admin/users/access-group/$access_id/save",
	{
		delete => 'Delete'
	},
	'Submitted request to delete access group'
);
$t->title_is(
	'Access Groups - ShinyCMS',
	'Reached list of access groups'
);
$t->content_lacks(
	'Test Access Group',
	'Verified that access group was deleted'
);

# Delete role
$t->post_ok(
	"/admin/users/role/$role_id/save",
	{
		delete => 'Delete'
	},
	'Submitted request to delete role'
);
$t->title_is(
	'Roles - ShinyCMS',
	'Reached list of roles'
);
$t->content_lacks(
	'Test Role',
	'Verified that role was deleted'
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
