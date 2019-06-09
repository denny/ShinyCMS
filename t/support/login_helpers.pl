# ===================================================================
# File:		t/support/login_helpers.pl
# Project:	ShinyCMS
# Purpose:	Helper methods for controller tests that need to log in
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

# Load CPAN modules
use Test::WWW::Mechanize::Catalyst::WithContext;

# Load local modules
use lib 't/support';
require 'helpers.pl';  ## no critic


# Get a database connection
my $schema = get_schema();

# Used to store the default test user and test admin objects, if needed
my $test_user;
my $test_admin;


=head1 METHODS

=head2 create_test_user

Create a test user:
    my $default_user = create_test_user();  # u/p are both 'test_user'
    my $custom_user = create_test_user( 'testbot' );  u/p are both 'testbot'

=cut

sub create_test_user {
    my( $username ) = @_;

    $username ||= 'test_user';

    $test_user = $schema->resultset( 'User' )->find_or_create({
        username => $username,
        password => $username,
        email    => $username.'@example.com',
    });

    return $test_user;
}


=head2 create_test_admin

Create an admin user, give them the specified roles (or default to all roles)
Note: if you want to specify roles, you must specify a username too:
    my $user_obj = create_test_admin( 'news_admin', 'News Admin' );
    my $user_obj = create_test_admin(); # default u/p & all roles

=cut

sub create_test_admin {
    my( $username, @requested_roles ) = @_;

    $username ||= 'test_admin';

    $test_admin = $schema->resultset( 'User' )->find_or_create({
        username => $username,
        password => $username,
        email    => $username.'@example.com',
    });

    my @roles;
    if ( @requested_roles ) {
        @roles = $schema->resultset( 'Role' )->search({
            role => \@requested_roles
        })->all;
    }
    else {
        # Give them full privileges
        @roles = $schema->resultset( 'Role' )->all;
    }

    $test_admin->user_roles->delete;
    foreach my $role ( @roles ) {
        $test_admin->user_roles->create({ role => $role->id });
    }

    return $test_admin;
}


=head2 login_test_user

Log in as a non-admin test user, return the logged-in mech object
    my $mech = login_test_user( 'username', 'password' );
    my $mech = login_test_user();  # u/p default to test_user/test_user

=cut

sub login_test_user {
    my( $username, $password ) = @_;

    $username ||= 'test_user';
    $password ||= 'test_user';

    # Create a mech object and log it in as the specified user
    my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );
    $mech->get( '/user/login' );
    $mech->submit_form(
        form_id => 'login',
        fields => {
            username => $username,
            password => $password,
        },
    );

    # Check the login attempt was successful, return mech object if it was
    my $link = $mech->find_link( text => 'logout' );
    return $mech if $link;
    return;
}


=head2 login_test_admin

Log in as an admin test user, return the logged-in mech object
    my $mech = login_test_admin( 'username', 'password' );
    my $mech = login_test_admin();  # u/p default to test_admin/test_admin

=cut

sub login_test_admin {
    my( $username, $password ) = @_;

    $username ||= 'test_admin';
    $password ||= 'test_admin';

    my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );
    $mech->get( '/admin/users/login' );
    $mech->submit_form(
        form_id => 'login',
        fields => {
            username => $username,
            password => $password,
        },
    );

    my $link = $mech->find_link( text => 'Logout' );
    return $mech if $link;
    return;
}


=head2 remove_test_user

Remove a test user from the database
    remove_test_user( $user_obj );  # Removes the specified test user
    remove_test_user();             # Removes the default test user

=cut

sub remove_test_user {
    my( $user ) = @_;

    if ( $user ) {
        $user->user_logins->delete;
        $user->delete;
    }
    else {
        $test_user->user_logins->delete;
        $test_user->delete;
    }
}


=head2 remove_test_admin

Remove a test admin user from the database
    remove_test_admin( $user_obj );  # Removes the specified test admin
    remove_test_admin();             # Removes the default test admin

=cut

sub remove_test_admin {
    my( $admin ) = @_;

    if ( $admin ) {
        $admin->user_roles->delete;
        $admin->delete;
    }
    else {
        $test_admin->user_roles->delete;
        $test_admin->delete;
    }
}


# EOF
1;
