# ===================================================================
# File:		t/admin-controllers/controller_Admin-Forums.t
# Project:	ShinyCMS
# Purpose:	Tests for forum admin features
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

# Log in as a Forums Admin
my $admin = create_test_admin( 'test_admin_forums', 'Forums Admin' );

my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Forums Admin';

my $c = $t->ctx;
ok(
	$c->user->has_role( 'Forums Admin' ),
	'Logged in as Forums Admin'
);

# Try to access the admin area for forums
$t->get_ok(
	'/admin/forums',
	'Try to access admin area for forums'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of all forums'
);

# Add a new forum section
$t->follow_link_ok(
	{ text => 'Add new section' },
	'Follow link to add a new forum section'
);
$t->title_is(
	'Add Section - ShinyCMS',
	'Reached page for adding new section'
);
$t->submit_form_ok({
	form_id => 'add_section',
	fields => {
		name => 'Test Section',
	}},
	'Submitted form to create new forum section'
);
$t->title_is(
	'Edit Section - ShinyCMS',
	'Redirected to edit page for newly created section'
);
my @section_inputs1 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
	$section_inputs1[0]->value eq 'test-section',
	'Verified that new forum section was created'
);
# Update the section
$t->submit_form_ok({
	form_id => 'edit_section',
	fields => {
		name => 'Updated Test Section',
		url_name => '',
		display_order => 2
	}},
	'Submitted form to update forum section'
);
my @section_inputs2 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
	$section_inputs2[0]->value eq 'updated-test-section',
	'Verified that forum section was updated'
);
$t->uri->path =~ m{/forums/section/(\d+)/edit$};
my $section_id = $1;
# Try to edit a non-existent section
$t->get_ok(
	'/admin/forums/section/42/edit',
	'Try to access edit page for non-existent forum section'
);
$t->text_contains(
	'Specified section not found',
	'Got a helpful error message warning that the section does not exist'
);
$t->title_is(
	'Sections - ShinyCMS',
	'Got redirected to the list of forum sections instead'
);

# Add a new forum
$t->follow_link_ok(
	{ text => 'Add new forum' },
	'Follow link to add a new forum'
);
$t->title_is(
	'Add Forum - ShinyCMS',
	'Reached page for adding new forum'
);
$t->submit_form_ok({
	form_id => 'add_forum',
	fields => {
		name => 'Test Forum',
		section => $section_id,
	}},
	'Submitted form to create new forum'
);
$t->title_is(
	'Edit Forum - ShinyCMS',
	'Redirected to edit page for newly created forum'
);
my @forum_inputs1 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
	$forum_inputs1[0]->value eq 'test-forum',
	'Verified that new forum was created'
);
# Update the section
$t->submit_form_ok({
	form_id => 'edit_forum',
	fields => {
		name => 'Updated Test Forum',
		url_name => '',
		display_order => 2
	}},
	'Submitted form to update forum'
);
my @forum_inputs2 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
	$forum_inputs2[0]->value eq 'updated-test-forum',
	'Verified that forum was updated'
);
$t->uri->path =~ m{/forums/forum/(\d+)/edit$};
my $forum_id = $1;
# Try to edit a non-existent forum
$t->get_ok(
	'/admin/forums/forum/42/edit',
	'Try to access edit page for non-existent forum'
);
$t->text_contains(
	'Specified forum not found',
	'Got a helpful error message warning that the forum does not exist'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Got redirected to the list of forums instead'
);

# TODO: Edit forum post


# TODO: Delete forum post (can't use submit_form_ok due to javascript confirmation)


# Try to delete non-empty forum section
$t->post_ok(
	'/admin/forums/section/'.$section_id.'/save',
	{
		delete  => 'Delete'
	},
	'Submitted request to delete forum section when it still contains forums'
);
$t->text_contains(
	'You cannot delete a section that still contains forums',
	'Got a suitable error message warning that the section still has content'
);
$t->text_contains(
	'Updated Test Section',
	'Non-empty forum section was not deleted'
);

# Delete forum
$t->post_ok(
	'/admin/forums/forum/'.$forum_id.'/save',
	{
		delete  => 'Delete'
	},
	'Submitted request to delete forum'
);
# View list of forums
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of forums'
);
$t->content_lacks(
	'Updated Test Forum',
	'Verified that forum was deleted'
);

# Delete (now empty) forum section
$t->post_ok(
	'/admin/forums/section/'.$section_id.'/save',
	{
		delete  => 'Delete'
	},
	'Submitted request to delete (empty) forum section'
);
# View list of forum sections
$t->title_is(
	'Sections - ShinyCMS',
	'Reached list of forum sections'
);
$t->content_lacks(
	'Updated Test Section',
	'Verified that forum section was deleted'
);
remove_test_admin( $admin );

# Try to access forum admin area without appropriate permissions
my $poll_admin = create_test_admin( 'forum_poll_admin', 'Poll Admin' );
$t = login_test_admin( 'forum_poll_admin', 'forum_poll_admin' )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/forums',
	'Try to access admin area for forums'
);
$t->title_unlike(
	qr/Shop.* - ShinyCMS/,
	'Poll Admin cannot access admin area for forums'
);
remove_test_admin( $poll_admin );

done_testing();
