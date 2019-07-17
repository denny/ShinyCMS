# ===================================================================
# File:		t/admin-controllers/controller_Admin-FileManager.t
# Project:	ShinyCMS
# Purpose:	Tests for file manager admin features
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


# Creat and log in as a File Admin
my $admin = create_test_admin(
	'test_admin_filemanager',
	'CMS Page Editor',
	'File Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as a File Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'File Admin' ),
	'Logged in as File Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to admin area for CMS Pages'
);


# Upload a new file
$t->follow_link_ok(
	{ text => 'Upload file' },
	'Follow link to file upload page'
);
$t->title_is(
	'Upload a file - ShinyCMS',
	'Reached file upload page'
);
$t->submit_form_ok({
	form_id => 'upload_file',
	fields => {
		upload => 'README.md'
	}},
	'Submitted file upload form'
);
# View list of CMS-uploaded files
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of CMS-uploaded files in admin area'
);
$t->content_contains(
	'README.md',
	'Verified that file was uploaded'
);
# Look at sub-directory
$t->follow_link_ok(
	{ text => 'images' },
	'Follow link to images directory'
);
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of CMS-uploaded files in admin area'
);
$t->content_contains(
	'Shiny.jpg',
	'Verified that we reached the images directory'
);


# TODO: Delete a CMS-uploaded file (feature not implemented yet!)


# Log out, then try to access admin area for file uploads again
$t->get( '/admin' );
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of file manager admin account'
);
$t->get_ok(
	'/admin/filemanager',
	'Try to access admin area for file uploads after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're blocked
my $poll_admin = create_test_admin( 'test_admin_filemanager_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/filemanager',
	'Try to access admin area for file uploads'
);
$t->title_unlike(
	qr{^.*Shop.* - ShinyCMS$},
	'Poll Admin cannot access admin area for file uploads'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
