# ===================================================================
# File:		t/meta/04_login_helpers.t
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
my( $user, $user_pw ) = create_test_user();
ok(
    ref $user eq 'ShinyCMS::Schema::Result::User',
    'create_test_user() returned user object'
);
ok(
    $user->username eq 'test_user',
    'create_test_user() created the default test user'
);
my $mech1 = login_test_user();
ok(
    ref $mech1 eq 'Test::WWW::Mechanize::Catalyst::WithContext',
    'login_test_user() created a mech object logged in as the default test user'
);
remove_test_user();
ok(
    $user->in_storage == 0,
    'remove_test_user() removed default test user'
);
# Log in as a non-default non-admin user
my $mech2 = login_test_user( 'viewer', 'changeme' );
ok(
    $mech2,
    "login_test_user( 'viewer', 'changeme' ) logged in as a user from demo data"
);
# Fail to log in as non-existent user
my $undef = login_test_user( 'user_does', 'not_exist' );
ok(
    not( defined $undef ),
    "login_test_user( 'user_does', 'not_exist' ) returned undef"
);
# Log in as default admin test user
my( $admin, $admin_pw ) = create_test_admin();
ok(
    ref $user eq 'ShinyCMS::Schema::Result::User',
    'create_test_admin() returned a user object'
);
ok(
    $admin->username eq 'test_admin',
    'create_test_admin() created the default test admin'
);
my $mech3 = login_test_admin();
ok(
    ref $mech3 eq 'Test::WWW::Mechanize::Catalyst::WithContext',
    'login_test_admin() returned a mech logged in as the default test admin'
);
remove_test_admin();
ok(
    $admin->in_storage == 0,
    'remove_test_admin() removed default test admin'
);

done_testing();
