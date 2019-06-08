# ===================================================================
# File:		t/admin-controllers/controller_Admin-Pages.t
# Project:	ShinyCMS
# Purpose:	Tests for CMS page admin features
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

# Log in as a CMS Template Admin
my $template_admin = create_test_admin(
	'test_admin_pages_template_admin',
	'CMS Page Editor',
	'CMS Page Admin',
	'CMS Template Admin'
);

my $t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as CMS Template Admin';

my $c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Template Admin' ),
	'Logged in as CMS Template Admin'
);

# Head to the Page Template admin area
$t->get_ok(
	'/admin/pages/templates',
	'Try to fetch admin area for CMS templates'
);
$t->title_is(
	'Page Templates - ShinyCMS',
	'Reached admin area for CMS templates'
);

# Add new CMS template
$t->follow_link_ok(
	{ text => 'Add template' },
	'Follow menu link to add a new CMS template'
);
$t->title_is(
	'Add Template - ShinyCMS',
	'Reached page for adding new CMS templates'
);
$t->submit_form_ok({
	form_id => 'add_template',
	fields => {
		name => 'Test Template',
		template_file => 'test-template.tt'
	}},
	'Submitted form to create new CMS template'
);
$t->title_is(
	'Edit Template - ShinyCMS',
	'Redirected to edit page for new CMS template'
);
my @template_inputs1 = $t->grep_inputs({ name => qr/^name$/ });
ok(
	$template_inputs1[0]->value eq 'Test Template',
	'Verified that new template was created'
);
$t->uri->path =~ m{/admin/pages/template/(\d+)/edit};
my $template_id = $1;
$t->submit_form_ok({
	form_id => 'edit_template',
	fields => {
		name => 'Updated Test Template',
	}},
	'Submitted form to update CMS template'
);
my @template_inputs2 = $t->grep_inputs({ name => qr/^name$/ });
ok(
	$template_inputs2[0]->value eq 'Updated Test Template',
	'Verified that template was updated'
);

# Now log in as a CMS Page Admin
my $admin = create_test_admin(
	'test_admin_pages',
	'CMS Page Editor',
	'CMS Page Admin'
);
$t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as CMS Page Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Page Admin' ),
	'Logged in as CMS Page Admin'
);
$t->get_ok(
	'/admin/pages',
	'Try to fetch admin area for CMS pages'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Reached admin area for CMS pages'
);

# Add new CMS section
$t->follow_link_ok(
	{ text => 'Add section' },
	'Follow menu link to add a new CMS section'
);
$t->title_is(
	'Add Section - ShinyCMS',
	'Reached page for adding new CMS sections'
);
$t->submit_form_ok({
	form_id => 'add_section',
	fields => {
		name => 'Test Section'
	}},
	'Submitted form to create new CMS section'
);
$t->title_is(
	'Edit Section - ShinyCMS',
	'Redirected to edit page for new CMS section'
);
my @section_inputs1 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$section_inputs1[0]->value eq 'test-section',
	'Verified that new section was created'
);
$t->submit_form_ok({
	form_id => 'edit_section',
	fields => {
		name	 => 'Updated Test Section',
		url_name => '',
		hidden   => 'on',
	}},
	'Submitted form to update CMS section'
);
my @section_inputs2 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$section_inputs2[0]->value eq 'updated-test-section',
	'Verified that section was updated'
);
$t->uri->path =~ m{/admin/pages/section/(\d+)/edit};
my $section_id = $1;

# Add new CMS page
$t->follow_link_ok(
	{ text => 'Add page' },
	'Follow menu link to add a new CMS page'
);
$t->title_is(
	'Add Page - ShinyCMS',
	'Reached page for adding new CMS pages'
);
$t->submit_form_ok({
	form_id => 'add_page',
	fields => {
		name => 'New Page From Test Suite'
	}},
	'Submitted form to create new CMS page'
);
$t->title_is(
	'Edit Page - ShinyCMS',
	'Redirected to edit page for new CMS page'
);
my @inputs1 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$inputs1[0]->value eq 'new-page-from-test-suite',
	'Verified that new page was created'
);
$t->uri->path =~ m{/admin/pages/page/(\d+)/edit};
my $page_id = $1;

# Now log in as a CMS Page Editor and check we can still access the page admin area
my $editor = create_test_admin( 'test_admin_pages_editor', 'CMS Page Editor' );
$t = login_test_admin( $editor->username, $editor->username )
	or die 'Failed to log in as CMS Page Editor';
$c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Page Editor' ),
	'Logged in as CMS Page Editor'
);
$t->get_ok(
	'/admin/pages',
	'Try to fetch admin area for CMS pages again'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Reached admin area for CMS pages'
);
$t->get_ok(
	'/admin/pages/add',
	'Try to fetch admin area for CMS pages again'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to list of CMS pages, because Page Editors cannnot add pages'
);

# Now edit the page we created earlier
$t->follow_link_ok(
	{ url_regex => qr{/admin/pages/page/$page_id/edit$} },
	'Click edit button for page we created a moment ago'
);
$t->submit_form_ok({
	form_id => 'edit_page',
	fields => {
		name	 => 'Updated Page From Test Suite!',
		url_name => '',
		template => 1,
		hidden   => 'on',
	}},
	'Submitted form to update CMS page'
);
my @inputs2 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$inputs2[0]->value eq 'updated-page-from-test-suite',
	'Verified that CMS page was updated'
);

# Delete template (can't use submit_form_ok due to javascript confirmation)
$t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as CMS Template Admin';
$t->post_ok(
	'/admin/pages/template/'.$template_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete CMS template'
);
$t->title_is(
	'Page Templates - ShinyCMS',
	'Redirected to list of templates'
);
$t->content_lacks(
	'Updated Test Template',
	'Verified that CMS template was deleted'
);

# Delete page
$t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as CMS Page Admin';
$t->post_ok(
	'/admin/pages/page/'.$page_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete CMS page'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to list of pages'
);
$t->content_lacks(
	'Updated Page From Test Suite!',
	'Verified that CMS page was deleted'
);

# Delete section
$t->post_ok(
	'/admin/pages/section/'.$section_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete CMS section'
);
$t->title_is(
	'Sections - ShinyCMS',
	'Redirected to list of sections'
);
$t->content_lacks(
	'Updated Test Section',
	'Verified that CMS section was deleted'
);

# Tidy up
remove_test_admin( $editor         );
remove_test_admin( $admin          );
remove_test_admin( $template_admin );

# Log in as the wrong sort of admin, and make sure we're blocked
my $poll_admin = create_test_admin( 'test_admin_pages_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/pages',
	'Try to fetch admin area for CMS pages'
);
$t->title_unlike(
	qr/List Pages - ShinyCMS/,
	'Poll Admin cannot view admin area for CMS pages'
);
remove_test_admin( $poll_admin );

done_testing();
