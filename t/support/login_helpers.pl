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
use Config::General;
use Test::WWW::Mechanize::Catalyst;

# Load local modules
use FindBin qw( $Bin );
use lib "$Bin/../lib";
use ShinyCMS::Schema;


my $test_user;
my $test_user_details = {
    username => 'test_user',
    password => 'test user password',
    email    => 'test-user@example.com',
};

my $test_admin;
my $test_admin_details = {
    username => 'test_admin',
    password => 'test admin password',
    email    => 'test-admin@example.com',
};


# Get the database connection details from the config file, and connect
my $reader = Config::General->new( $Bin .'/../../config/shinycms.conf' );
my %config = $reader->getall;
my $connect_info = $config{ 'Model::DB' }->{ connect_info };
my $schema = ShinyCMS::Schema->connect( $connect_info );


# Create a test user
sub create_test_user {
    $test_user = $schema->resultset( 'User' )
        ->find_or_create( $test_user_details );
    return $test_user, $test_user_details->{ password };
}


# Create an admin user, give them the specified roles (or default to all roles)
sub create_test_admin {
    my @requested_roles = @_;

    $test_admin = $schema->resultset( 'User' )
        ->find_or_create( $test_admin_details );
    $test_admin->user_roles->delete_all;

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

    foreach my $role ( @roles ) {
        $test_admin->user_roles->create({ role => $role->id });
    }

    return $test_admin, $test_admin_details->{ password };
}


# Log in as a non-admin user, return the logged-in mech object
sub login_test_user {
    # Create a mech object and log it in as the test user
    my $mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );
    $mech->get( '/user/login' );
    $mech->submit_form(
    	form_id => 'login',
        fields => {
    		username => $test_user_details->{ username },
        	password => $test_user_details->{ password }
    	},
    );
    # Check the login attempt was successful, return mech object if it was
    my $link = $mech->find_link( text => 'logout' );
    return $mech if $link;
    return;
}


# Log in as an admin user, return the logged-in mech object
sub login_test_admin {
    # Create a mech object and log it in as the test user
    my $mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );
    $mech->get( '/admin/users/login' );
    $mech->submit_form(
    	form_id => 'login',
        fields => {
    		username => $test_admin_details->{ username },
        	password => $test_admin_details->{ password }
    	},
    );
    my $link = $mech->find_link( text => 'Logout' );
    return $mech if $link;
    return;
}


# Remove the test user from the database
sub remove_test_user {
    $test_user->user_logins->delete;
    $test_user->delete;
}


# Remove the test admin from the database
sub remove_test_admin {
    $test_admin->user_roles->delete;
    $test_admin->delete;
}


# EOF
1;
