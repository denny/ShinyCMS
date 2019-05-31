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

# TODO: Replace with in-test registration?
my $test_user = create_test_user();

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

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
# TODO: Register an account
# Log in
$t->get_ok(
    '/user/login',
    'Fetch user login page'
);
$t->title_is(
    'Log In - ShinySite',
    'Reached user login page'
);
$t->submit_form_ok({
    form_id => 'login',
    fields => {
        username => $test_user->username,
        password => $test_user->username,
    }},
    'Submitted login form'
);
my $link = $t->find_link( text => 'logout' );
ok( $link, 'Login successful' );
# Try to fetch /user again, after logging in
$t->get_ok(
    '/user',
    'Try to fetch /user while logged in'
);
$t->title_is(
    $test_user->username . ' - ShinySite',
    "/user redirects to the user's own profile page if they are logged in"
);

remove_test_user();

done_testing();
