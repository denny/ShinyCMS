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
# Register an account
$t->submit_form_ok({
	form_id => 'login',
	fields => {
		username  => $username,
		password  => $username,
		password2 => $username,
		email	 => $username.'@shinycms.org',
		'g-recaptcha-response' => 'fake'
	}},
	'Submitted registration form'
);
# Fetch the login page again
$t->get_ok(
	'/user/login',
	'Fetch user login page again'
);
# Invalid login attempt
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
# Valid login attempt
$t->submit_form_ok({
	form_id => 'login',
	fields => {
		username => $username,
		password => $username,
	}},
	'Submitted login form with valid details but before confirming registration'
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

# ...

# Tidy up
$c = $t->ctx;
my $user_obj = $c->model('DB::User')->search({ username => $username })->single;
$user_obj->confirmations->delete;
remove_test_user( $user_obj );

done_testing();
