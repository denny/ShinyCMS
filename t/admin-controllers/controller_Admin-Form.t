# ===================================================================
# File:		t/admin-controllers/controller_Admin-Form.t
# Project:	ShinyCMS
# Purpose:	Tests for form handler admin features
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
use Try::Tiny;

use lib 't/support';
require 'login_helpers.pl';  ## no critic


# Create and log in as a Form Admin
my $admin = create_test_admin(
	'test_admin_forms',
	'CMS Page Editor',
	'CMS Page Admin',
	'CMS Form Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as CMS Form Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Form Admin' ),
	'Logged in as CMS Form Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to admin area for CMS Pages'
);


# Add a new form handler
$t->follow_link_ok(
	{ text => 'Add form handler' },
	'Follow link to add a new form handler'
);
$t->title_is(
	'Add Form Handler - ShinyCMS',
	'Reached page for adding new form handler'
);
$t->submit_form_ok({
	form_id => 'edit_form',
	fields => {
		name => 'New Form Handler'
	}},
	'Submitted form to create new form handler'
);
$t->title_is(
	'Edit Form Handler - ShinyCMS',
	'Redirected to edit page for new form handler'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$inputs1[0]->value eq 'new-form-handler',
	'Verified that new form handler was created'
);

# Edit form handler
$t->submit_form_ok({
	form_id => 'edit_form',
	fields => {
		name => 'Updated form handler!',
		url_name => 'transient-value',
		has_captcha => 1,
	}},
	'Submitted form to update form handler (updated name)'
);
$t->submit_form_ok({
	form_id => 'edit_form',
	fields => {
		url_name => '',
	}},
	'Submitted form to update form handler again (url_name re-set)'
);
my @inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$inputs2[0]->value eq 'Updated form handler!',
	'Verified that form handler was updated'
);

# Delete form Handler (can't use submit_form_ok due to javascript confirmation)
my @inputs3 = $t->grep_inputs({ name => qr{^form_id$} });
my $id = $inputs3[0]->value;
$t->post_ok(
	'/admin/form/edit-form-do',
	{
		form_id => $id,
		delete  => 'Delete'
	},
	'Submitted request to delete form handler'
);
# View list of form handlers
$t->title_is(
	'Form Handlers - ShinyCMS',
	'Redirected to list of form handlers'
);
$t->content_lacks(
	'Updated form handler!',
	'Verified that form handler was deleted'
);

# Try to get template filenames when template directory is missing
my $template_dir = $c->path_to( 'root/emails' );
system( "mv $template_dir $template_dir.test" );
try {
	ShinyCMS::Controller::Admin::Form->get_template_filenames( $c );
}
catch {
	ok(
		m{Failed to open template directory},
		'Caught die() for get_template_filenames() when template directory is missing.'
	);
};
system( "mv $template_dir.test $template_dir" );


# Log out, then try to access admin area for form handlers again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of form admin account'
);
$t->get_ok(
	'/admin/form',
	'Try to access admin area for form handlers after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_form_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/form',
	'Attempt to access form handler admin area as a Poll Admin'
);
$t->title_unlike(
	qr{^.*Form Handler.* - ShinyCMS$},
	'Failed to reach form handler admin area without any appropriate roles enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
