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

my $test_admin = create_test_admin();

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Try to fetch the admin area, expecting to fail and be aked to log in first
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
		username => $test_admin->username,
    	password => $test_admin->username,
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
    }},
    'Submitted form to create new user'
);
$t->title_is(
	'Edit user - ShinyCMS',
	'Redirected to edit page for new user'
);
my @inputs1 = $t->grep_inputs({ name => qr/^email$/ });
ok(
    $inputs1[0]->value eq $test_data_email,
    'Verified that user was created'
);
# Update user details
$t->submit_form_ok({
    form_id => 'edit_user',
    fields => {
		admin_notes => 'User updated by test suite'
    }},
    'Submitted form to update user'
);
my @inputs2 = $t->grep_inputs({ name => qr/^admin_notes$/ });
ok(
    $inputs2[0]->value eq 'User updated by test suite',
    'Verified that user was updated'
);
my @inputs3 = $t->grep_inputs({ name => qr/^user_id$/ });
my $user_id = $inputs3[0]->value;
# TODO: Roles and User Roles
# TODO: Access and User Access
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

remove_test_admin();

done_testing();
