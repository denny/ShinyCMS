# ===================================================================
# File:		t/admin-controllers/controller_Admin-Blog.t
# Project:	ShinyCMS
# Purpose:	Tests for blog admin features
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


# Create and log in as a Blog Admin
my $admin = create_test_admin(
	'test_admin_blog',
	'Blog Author',
	'Blog Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Blog Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Blog Admin' ),
	'Logged in as Blog Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'Blog Posts - ShinyCMS',
	'Redirected to admin area for blog'
);


# Add a blog post
$t->follow_link_ok(
	{ text => 'New blog post' },
	'Follow link to add a new blog post'
);
$t->title_is(
	'New blog post - ShinyCMS',
	'Reached page for adding blog post'
);
$t->submit_form_ok({
	form_id => 'add_post',
	fields => {
		title => 'This is a test blog post',
		body  => 'This is some test content.',
		tags  => 'test, tests',
	}},
	'Submitted form to create blog post'
);
$t->title_is(
	'Edit blog post - ShinyCMS',
	'Redirected to edit page for newly created blog post'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_title$} });
ok(
	$inputs1[0]->value eq 'this-is-a-test-blog-post',
	'Verified that blog post was created'
);

# Update blog post
$t->submit_form_ok({
	form_id => 'edit_post',
	fields => {
		title => 'Blog post updated by test suite'
	}},
	'Submitted form to update blog post'
);
my @inputs2 = $t->grep_inputs({ name => qr{^title$} });
ok(
	$inputs2[0]->value eq 'Blog post updated by test suite',
	'Verified that blog post was updated'
);
$t->submit_form_ok({
	form_id => 'edit_post',
	fields => {
		tags => undef,
		allow_comments => undef,
	}},
	'Submitted form to remove tags and discussion thread from blog post'
);
$t->submit_form_ok({
	form_id => 'edit_post',
	fields => {
		tags => 'test, tests, tags',
		allow_comments => 'on',
	}},
	'Submitted form to add new tags to blog post'
);

# Delete blog post (can't use submit_form_ok due to javascript confirmation)
my $edit_url = $t->form_id( 'edit_post' )->action;
$edit_url =~ m{/(\d+)/edit-do$};
my $id = $1;
$t->post_ok(
	'/admin/blog/post/'.$id.'/edit-do',
	{
		delete => 'Delete'
	},
	'Submitted request to delete blog post'
);
# View list of blog posts
$t->title_is(
	'Blog Posts - ShinyCMS',
	'Reached list of blog posts'
);
$t->content_lacks(
	'Blog post updated by test suite',
	'Verified that blog post was deleted'
);


# Log out, then try to access admin area for blog again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of blog admin account'
);
$t->get_ok(
	'/admin/blog',
	'Try to access admin area for blog after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_blog_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/shop',
	'Try to access blog admin area as Poll Admin'
);
$t->title_unlike(
	qr{^.*Blog.* - ShinyCMS$},
	'Poll Admin cannot access blog admin area'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
