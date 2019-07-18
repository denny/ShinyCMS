# ===================================================================
# File:		t/controllers/controller_User.t
# Project:	ShinyCMS
# Purpose:	Tests for user features
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

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

my $username = 'user_controller_test';


# Try to fetch /user while not logged in
$t->get_ok(
	'/user',
	'Try to fetch /user while not logged in'
);
$t->title_is(
	'Home - ShinySite',
	'/user redirects to homepage if not logged in'
);

# Fetch login page, follow link to register new account
$t->get_ok(
	'/user/login',
	'Fetch user login page'
);
$t->title_is(
	'Log In - ShinySite',
	'Reached user login page'
);
$t->follow_link_ok(
	{ text => 'register a new account' },
	'Click on register link'
);
$t->title_is(
	'Register - ShinySite',
	'Reached user registration page'
);

# Register an account...
# Invalid username
$t->submit_form_ok({
	form_id => 'register',
	fields => {
		username  => 'bobby;drop table "users";',
		password  => $username,
		password2 => $username,
		email     => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form with invalid username'
);
$t->text_contains(
	'Usernames may only contain letters, numbers and underscores.',
	'Got appropriate error message'
);
$t->submit_form_ok({
	form_id => 'register',
	fields => {
		username  => 'admin',
		password  => $username,
		password2 => $username,
		email     => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form with already-taken username'
);
$t->text_contains(
	'Sorry, that username is already taken.',
	'Got appropriate error message'
);
$t->submit_form_ok({
	form_id => 'register',
	fields => {
		username  => $username,
		password  => $username,
		password2 => 'Hunter2',
		email     => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form with not-matching passwords'
);
$t->text_contains(
	'Passwords do not match.',
	'Got appropriate error message'
);
$t->submit_form_ok({
	form_id => 'register',
	fields => {
		username  => $username,
		password  => $username,
		password2 => $username,
		email     => $username.'@shinycms',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form with invalid email address'
);
$t->text_contains(
	'You must set a valid email address.',
	'Got appropriate error message'
);
$t->submit_form_ok({
	form_id => 'register',
	fields => {
		username  => $username,
		password  => $username,
		password2 => $username,
		email     => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form with valid details'
);
$t->text_contains(
	'A confirmation link has been emailed to you.',
	'Registration was successful'
);

# Fetch the login page again
$t->get_ok(
	'/user/login',
	'Fetch user login page again'
);
# Try invalid login details
$t->submit_form_ok({
	form_id => 'login',
	fields => {
		username => 'no_such_user',
		password => 'no such user',
	}},
	'Submitted login form with details for non-existent user'
);
$t->text_contains(
	'Bad username or password',
	'Got error message for bad login details'
);
# Try valid login details, but pre-confirmation
$t->submit_form_ok({
	form_id => 'login',
	fields => {
		username => $username,
		password => $username,
	}},
	'Submitted login form with valid details but before confirming registration'
);
$t->text_contains(
	'Account unavailable.',
	'Got error message for unconfirmed email address'
);

# Confirm registration from earlier
my $c = $t->ctx;
my @confirmations = $c->model('DB::Confirmation')->all;
my $confirmation = pop @confirmations;
my $confirmation_code = $confirmation->code;
$t->get_ok(
	'/user/confirm/'.$confirmation_code,
	'Confirm registration, logging in as '.$username
);

# Try to fetch /user again, after logging in
$t->get_ok(
	'/user',
	'Try to fetch /user while logged in'
);
$t->title_is(
	$username . ' - ShinySite',
	"/user redirects to the user's own profile page if they are logged in"
);
# Hit register page as logged-in user
$t->get_ok(
	'/user/register',
	'Try to go to registration page while logged in'
);
$t->title_is(
	$username . ' - ShinySite',
	"/user/register redirects to the user's own profile page if they are logged in"
);
# Hit login page as logged-in user
$t->get_ok(
	'/user/login',
	'Try to go to login page while logged in'
);
$t->title_is(
	'Feature List - ShinySite',
	"/user/login redirects to the configured page if they're already logged in"
);

# Edit user
$t->follow_link_ok(
	{ url_regex => qr{/user/edit$} },
	'Click link to edit user details'
);
$t->title_is(
	'Edit user details - ShinySite',
	'Reached edit page'
);
$t->submit_form_ok({
	form_id => 'edit_user',
	fields => {
		firstname => 'Testification',
		lastname  => 'User',
		allow_comments => 'on',
	}},
	'Submitted form to update user details'
);
$t->title_is(
	'Edit user details - ShinySite',
	'Redirected back to edit page'
);
$t->form_id( 'edit_user' );
my @inputs1 = $t->grep_inputs({ name => qr{^firstname$} });
ok(
	$inputs1[0]->value eq 'Testification',
	'Verified that user details were updated'
);

# Change password
$t->follow_link_ok(
	{ url_regex => qr{/user/change-password$} },
	"Click on link to change user's password"
);
$t->title_is(
	'Change Password - ShinySite',
	'Reached page for changing user password'
);
$t->submit_form_ok({
	form_id => 'change_password',
	fields => {
		password     => 'this is not right',
		password_one => 'testing_password',
		password_two => 'testing_password',
	}},
	'Submitted form to change password, with incorrect current password'
);
$t->title_is(
	'Change Password - ShinySite',
	'Redirected back to change password page'
);
$t->text_contains(
	'Incorrect current password.',
	'Got error message about password being wrong'
);
$t->submit_form_ok({
	form_id => 'change_password',
	fields => {
		password     => $username,
		password_one => 'testing_password',
		password_two => 'different_password',
	}},
	'Submitted form to change password, with mismatched passwords'
);
$t->title_is(
	'Change Password - ShinySite',
	'Redirected back to change password page'
);
$t->text_contains(
	'Passwords did not match',
	'Got error message about passwords not matching'
);
$t->submit_form_ok({
	form_id => 'change_password',
	fields => {
		password     => $username,
		password_one => 'updated_password',
		password_two => 'updated_password',
	}},
	'Submitted form to change password again, with matching passwords'
);
$t->title_is(
	'Edit user details - ShinySite',
	'Redirected back to user edit page'
);
$t->text_contains(
	'Password changed',
	'Verified that password was changed'
);

# Log out
$t->get_ok(
	'/user/logout',
	'Logged out'
);
# Fetch the 'forgot my details' page
$t->get_ok(
	'/user/forgot-details',
	'Fetch page for recovering login after forgetting username/password'
);
# Submit form with bad username
$t->submit_form_ok({
	form_id => 'forgot_details',
	fields => {
		username => 'no_such_name',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted account recovery form with username of non-existent user'
);
$t->text_contains(
	'We do not have a user with that username in our database.',
	'Got error message for trying to recover non-existent account'
);
# Submit form with good username
$t->get( '/user/forgot-details' );
$t->submit_form_ok({
	form_id => 'forgot_details',
	fields => {
		username => $username,
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted account recovery form with username of our test user'
);
$t->text_contains(
	'We have sent you an email containing a link which will allow you to log in',
	'Got confirmation that recovery email has been sent to us'
);
# Submit form with good email address
$t->get( '/user/forgot-details' );
$t->submit_form_ok({
	form_id => 'forgot_details',
	fields => {
		email => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted account recovery form with email address of our test user'
);
$t->text_contains(
	'we have sent you an email containing a link which will allow you to log in',
	'Got confirmation that recovery email has been sent to us'
);


# TODO: reconnect()


# Tidy up
my $schema = get_schema();
my $user_obj = $schema->resultset( 'User' )->find({ username => $username });
$user_obj->confirmations->delete;
remove_test_user( $user_obj );

done_testing();
