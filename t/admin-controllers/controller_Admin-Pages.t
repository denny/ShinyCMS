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


# Get a database handle, for use later on
my $schema = get_schema();

# Create and log in as a CMS Template Admin
my $template_admin = create_test_admin(
	'test_admin_pages_template_admin',
	'CMS Page Editor',
	'CMS Page Admin',
	'CMS Template Admin'
);
my $t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as CMS Template Admin';
# Check that the login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Template Admin' ),
	'Logged in as CMS Template Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to admin area for CMS pages'
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
my @template_inputs1 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$template_inputs1[0]->value eq 'Test Template',
	'Verified that new template was created'
);
$t->uri->path =~ m{/admin/pages/template/(\d+)/edit};
my $template1_id = $1;
# Update CMS template
$t->submit_form_ok({
	form_id => 'edit_template',
	fields => {
		name => 'Updated Test Template',
	}},
	'Submitted form to update CMS template'
);
my @template_inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$template_inputs2[0]->value eq 'Updated Test Template',
	'Verified that template was updated'
);

# Add extra element to template
$t->submit_form_ok({
	form_id => 'add_template_element',
	fields => {
		new_element => 'extra_element',
		new_type    => 'Image',
	}},
	'Submitted form to add extra element to template'
);
$t->text_contains(
	'Element added',
	'Verified that element was added'
);

# Add second template
$t->follow_link_ok(
	{ text => 'Add template' },
	'Follow menu link to add another CMS template'
);
$t->submit_form_ok({
	form_id => 'add_template',
	fields => {
		name => 'Test Template Two',
		template_file => 'test-template.tt'
	}},
	'Submitted form to create second CMS template'
);
$t->uri->path =~ m{/admin/pages/template/(\d+)/edit};
my $template2_id = $1;


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
my @section_inputs1 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$section_inputs1[0]->value eq 'test-section',
	'Verified that new section was created'
);
# Update CMS section
$t->submit_form_ok({
	form_id => 'edit_section',
	fields => {
		name	 => 'Updated Test Section',
		url_name => '',
		hidden   => 'on',
	}},
	'Submitted form to update CMS section'
);
my @section_inputs2 = $t->grep_inputs({ name => qr{^url_name$} });
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
		name     => 'New Page From Test Suite',
		template => $template1_id,
	}},
	'Submitted form to create new CMS page'
);
$t->title_is(
	'Edit Page - ShinyCMS',
	'Redirected to edit page for new CMS page'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$inputs1[0]->value eq 'new-page-from-test-suite',
	'Verified that new page was created'
);
$t->uri->path =~ m{/admin/pages/page/(\d+)/edit};
my $page1_id = $1;
$t->follow_link_ok(
	{ text => 'Add page' },
	'Follow menu link to add a second page'
);
$t->submit_form_ok({
	form_id => 'add_page',
	fields => {
		name     => 'Another Test Page',
		url_name => 'another-test-page',
		hidden   => 'on',
		menu_position => '1',
	}},
	'Submitted form to create second, hidden, test page'
);
$t->uri->path =~ m{/admin/pages/page/(\d+)/edit};
my $page2_id = $1;
my $edit_page_path = $t->uri->path;

# Clone a page (can't use submit_form_ok due to javascript confirmation)
print STDERR '/admin/pages/page/'.$page1_id.'/clone';
$t->post_ok(
	'/admin/pages/page/'.$page1_id.'/clone',
	{},
	'Submitted request to clone first CMS page'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to list of pages'
);
my $page3_id = $schema->resultset( 'CmsPage' )->get_column( 'id' )->max;
$t->content_contains(
	"Duplicator cloned a CmsPage from ID $page1_id to ID $page3_id",
	'Got success message for cloning page'
);

# Add extra element to page
$t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as CMS Template Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'CMS Template Admin' ),
	'Logged back in as CMS Template Admin'
);
$t->get( $edit_page_path );
$t->submit_form_ok({
	form_id => 'add_element',
	fields => {
		new_element => 'extra_page_element',
		new_type    => 'Short Text',
	}},
	'Submitted form to add extra element to page'
);
$t->text_contains(
	'Element added',
	'Verified that element was added'
);
$t->submit_form_ok({
	form_id => 'edit_page',
	fields => {
		url_name => 'updated-second-test-page',
	}},
	'Submitted form to update second CMS page, as a Template Admin'
);


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
	'Try to reach area for adding a CMS page'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to list of CMS pages, because Page Editors cannnot add pages'
);

# Now edit the page we created earlier
$t->follow_link_ok(
	{ url_regex => qr{/admin/pages/page/$page1_id/edit$} },
	'Click edit button for page we created a moment ago'
);
$t->submit_form_ok({
	form_id => 'edit_page',
	fields => {
		name	 => 'Updated Page From Test Suite!',
		url_name => '',
		template => $template1_id,
		hidden   => 'on',
	}},
	'Submitted form to update CMS page'
);
my @inputs2 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$inputs2[0]->value eq 'updated-page-from-test-suite',
	'Verified that CMS page was updated'
);
$t->submit_form_ok({
	form_id => 'edit_page',
	fields => {
		template => 1,
		hidden   => undef,
	}},
	'Update page again to unhide (for last preview test!) and change template'
);

# And preview the page a couple of times
my $page1 = $schema->resultset('CmsPage')->find({ id => $page1_id });
my $page1_section_url_name = $page1->section->url_name;
my $page1_url_name = $page1->url_name;
$t->post_ok(
	"/pages/$page1_section_url_name/$page1_url_name/preview",
	{
		name      => 'Testing Preview Feature',
		template  => 1,
		name_1    => 'element_test_name',
		content_1 => 'Element test: content',
	},
	'Test if preview feature works (with template param)'
);
$t->post_ok(
	"/pages/$page1_section_url_name/$page1_url_name/preview",
	{
		name      => 'Testing Preview Feature',
		name_1    => 'element_test_name',
		content_1 => 'Element test: content',
	},
	'Test if preview feature works (without template param)'
);
$t->title_is(
	'Testing Preview Feature - ShinySite',
	'Loaded preview page with expected title'
);


# Log out, then try to access admin area for pages again
$t->get_ok(
	'/logout',
	'Log out of CMS page editor account'
);
$t->get_ok(
	'/admin/pages',
	'Try to access admin area for CMS pages after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);


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
	qr{^.*Page.* - ShinyCMS$},
	'Poll Admin cannot view admin area for CMS pages'
);


# Try to preview a page without Editor/Admin privs
$t->post_ok(
	"/pages/$page1_section_url_name/$page1_url_name/preview",
	{
		name => 'Testing Preview Feature Without Privs',
	},
	'Attempt to preview a page without page editor/admin privs'
);
$t->text_contains(
	'You do not have the ability to preview page edits',
	'Got appropriate error message'
);


# Delete pages
$t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as CMS Page Admin';
$t->post_ok(
	'/admin/pages/page/'.$page1_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete first CMS page'
);
$t->post_ok(
	'/admin/pages/page/'.$page2_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete second CMS page'
);
$t->post_ok(
	'/admin/pages/page/'.$page3_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete third (cloned) CMS page'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Redirected to list of pages'
);
$t->content_lacks(
	'Updated Page From Test Suite!',
	'Verified that first page was deleted'
);
$t->content_lacks(
	'Another Test Page',
	'Verified that second page was deleted'
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


# Delete template element, and template, as template admin
$t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as CMS Template Admin';
# Delete template element
$t->follow_link_ok(
	{ text => 'List templates' },
	'Log back in as template admin, fetch the list of templates'
);
$t->follow_link_ok(
	{ url_regex => qr{/admin/pages/template/$template1_id/edit$} },
	'Click edit button for our test template'
);
$t->follow_link_ok(
	{ url_regex => qr{/admin/pages/template/$template1_id/delete-element/\d+$} },
	'Delete the first template element'
);
$t->text_contains(
	'Element removed',
	'Got confirmation message for deletion of template element'
);

# Clone template (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/pages/template/'.$template1_id.'/clone',
	{},
	'Submitted request to clone first CMS template'
);
$t->title_is(
	'Page Templates - ShinyCMS',
	'Redirected to list of templates'
);
my $template3_id = $schema->resultset( 'CmsTemplate' )->get_column( 'id' )->max;
$t->content_contains(
	"Duplicator cloned a CmsTemplate from ID $template1_id to ID $template3_id",
	'Got success message for cloning template'
);

# Delete templates (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/pages/template/'.$template1_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete first CMS template'
);
$t->post_ok(
	'/admin/pages/template/'.$template2_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete second CMS template'
);
$t->post_ok(
	'/admin/pages/template/'.$template3_id.'/edit-do',
	{ delete => 'Delete' },
	'Submitted request to delete third (cloned) CMS template'
);
$t->title_is(
	'Page Templates - ShinyCMS',
	'Redirected to list of templates'
);
$t->content_lacks(
	'Updated Test Template',
	'Verified that first CMS template was deleted'
);
$t->content_lacks(
	'Test Template Two',
	'Verified that second CMS template was deleted'
);


# Tidy up user accounts
remove_test_admin( $template_admin );
remove_test_admin( $admin          );
remove_test_admin( $editor         );
remove_test_admin( $poll_admin     );

done_testing();
