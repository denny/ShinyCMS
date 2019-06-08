# ===================================================================
# File:		t/meta/11_login_helpers.t
# Project:	ShinyCMS
# Purpose:	Tests for the login helpers used in the controller tests
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

# Create, log in as, and remove, default non-admin test user
my $user1 = create_test_user();
ok(
    ref $user1 eq 'ShinyCMS::Schema::Result::User',
    'create_test_user() returned user object'
);
ok(
    $user1->username eq 'test_user',
    'create_test_user() created the default test user'
);
my $mech1 = login_test_user();
ok(
    ref $mech1 eq 'Test::WWW::Mechanize::Catalyst::WithContext',
    'login_test_user() created a mech object logged in as the default test user'
);
remove_test_user();
ok(
    $user1->in_storage == 0,
    'remove_test_user() removed default test user'
);

# Create, log in as, and remove, a non-default non-admin test user
my $user2 = create_test_user( 'alt_tester' );
ok(
    $user2->username eq 'alt_tester',
    "create_test_user( 'alt_tester' ) succeeded"
);
my $mech2 = login_test_user( 'alt_tester', 'alt_tester' );
my $c2 = $mech2->ctx;
ok(
    $c2->user->username eq 'alt_tester',
    "login_test_user( 'alt_tester', 'alt_tester' ) succeeded"
);
remove_test_user( $user2 );
ok(
    $user2->in_storage == 0,
    'remove_test_user( $user_obj ) succeeded'
);

# Fail to log in as non-existent user
my $undef3 = login_test_user( 'user_does', 'not_exist' );
ok(
    not( defined $undef3 ),
    "login_test_user( 'user_does', 'not_exist' ) failed"
);

# Log in as default admin test user
my $admin4 = create_test_admin();
ok(
    ref $admin4 eq 'ShinyCMS::Schema::Result::User',
    'create_test_admin() returned a user object'
);
ok(
    $admin4->username eq 'test_admin',
    'create_test_admin() created the default test admin'
);
my $mech4 = login_test_admin();
ok(
    ref $mech4 eq 'Test::WWW::Mechanize::Catalyst::WithContext',
    'login_test_admin() returned a mech logged in as the default test admin'
);
remove_test_admin();
ok(
    $admin4->in_storage == 0,
    'remove_test_admin() removed default test admin'
);

# Create, log in as, and remove, a non-default admin test user, with all roles
my $admin5 = create_test_admin( 'alt_admin' );
ok(
    $admin5->username eq 'alt_admin',
    "create_test_admin( 'alt_admin' ) succeeded"
);
my $mech5 = login_test_admin( 'alt_admin', 'alt_admin' );
my $c5 = $mech5->ctx;
ok(
    $c5->user->username eq 'alt_admin',
    "login_test_admin( 'alt_admin', 'alt_admin' ) succeeded"
);
ok(
    $c5->user->user_roles->count > 10,
    'alt_admin has the full set of roles'
);
remove_test_admin( $admin5 );
ok(
    $admin5->in_storage == 0,
    'remove_test_admin( $user_obj ) succeeded'
);

# Create, log in as, and remove, a test admin with a restricted set of roles
my $admin6 = create_test_admin( 'ltd_admin', 'Poll Admin', 'Events Admin' );
ok(
    $admin6->username eq 'ltd_admin',
    "create_test_admin( 'ltd_admin', 'Poll Admin', 'Events Admin' ) succeeded"
);
my $mech6 = login_test_admin( 'ltd_admin', 'ltd_admin' );
my $c6 = $mech6->ctx;
ok(
    $c6->user->user_roles->count == 2,
    'ltd_admin only has two roles'
);
remove_test_admin( $admin6 );

# Fail to log in as non-existent admin
my $undef7 = login_test_admin( 'admin_does', 'not_exist' );
ok(
    not( defined $undef7 ),
    "login_test_admin( 'admin_does', 'not_exist' ) failed"
);

done_testing();
