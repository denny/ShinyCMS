# ===================================================================
# File:		t/admin-controllers/controller_Admin-FileServer.t
# Project:	ShinyCMS
# Purpose:	Tests for fileserver admin features
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


# Create and log in as a Fileserver Admin
my $admin = create_test_admin( 'test_admin_fileserver', 'Fileserver Admin' );

my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Fileserver Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Fileserver Admin' ),
	'Logged in as Fileserver Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'Access logs for all files - ShinyCMS',
	'Redirected to admin area for fileserver'
);


# Get a list of all files which have access log data
$t->follow_link_ok(
	{ text => 'Fileserver logs' },
	'Follow link to view access logs for all files'
);
$t->title_is(
	'Access logs for all files - ShinyCMS',
	'Reached list of files'
);
# Look at second page of data, to make Devel::Cover happy
$t->get_ok(
	$t->uri->path . '?page=2&count=5',
	'Fetch second page of data'
);
$t->back;

# View access logs for specific file
# TODO: this is one of the few admin area tests that requires the demo data to be loaded
$t->follow_link_ok(
	{ text => 'Access Logs' },
	'Follow link to view access logs for first file listed'
);
$t->title_is(
	'Access logs for: empty-file.txt - ShinyCMS',
	'Reached access logs for specific file'
);
$t->text_contains(
	'10.10.10.10',
	'Found expected IP address'
);
# Look at second page of data, to make Devel::Cover happy
$t->get_ok(
	$t->uri->path . '?page=2&count=5',
	'Fetch second page of data'
);
$t->back;

# Get list of files in specified path which have access data
$t->get_ok(
	'/admin/fileserver/access-logs/dir-one',
	"Fetch list of restricted files in 'dir-one' directory"
);
$t->title_is(
	'Access logs for: dir-one - ShinyCMS',
	'Reached list of files in specific directory'
);
# Look at second page of data, to make Devel::Cover happy
$t->get_ok(
	$t->uri->path . '?page=2&count=5',
	'Fetch second page of data'
);


# Log out, then try to access admin area for fileserver again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of fileserver admin account'
);
$t->get_ok(
	'/admin/fileserver',
	'Try to access admin area for fileserver after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're blocked
my $poll_admin = create_test_admin( 'test_admin_fileserver_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/fileserver',
	'Attempt to fetch fileserver admin area as Poll Admin'
);
$t->title_unlike(
	qr{^Access logs.* - ShinyCMS$},
	'Failed to reach fileserver access logs without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
