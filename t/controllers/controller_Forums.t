# ===================================================================
# File:		t/controllers/controller-Forums.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS forums controller
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
use Test::WWW::Mechanize::Catalyst::WithContext;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Forums (all of them)
$t->get_ok(
	'/forums',
	'Fetch list of forums'
);
$t->title_is(
	'Forums - ShinySite',
	'Loaded list of forums'
);
# Sections
$t->follow_link_ok(
	{ text => 'Hardware' },
	'Follow link to view a forum section'
);
$t->title_is(
	'Hardware - Forums - ShinySite',
	'Reached hardware section'
);
# Forums (individually)
$t->follow_link_ok(
	{ text => 'Desktops' },
	'Follow link to view a single forum, with no content'
);
$t->title_is(
	'Desktops - Hardware - Forums - ShinySite',
	'Reached desktops forum'
);
$t->back;
$t->follow_link_ok(
	{ text => 'Laptops' },
	'Go back, then follow link to view a single forum with some content'
);
$t->title_is(
	'Laptops - Hardware - Forums - ShinySite',
	'Reached laptops forum'
);
$t->get_ok(
	'/forums/hardware/laptops?page=2&count=3',
	'Try to load second page of (3) posts in laptops forum in hardware section'
);
# Posts
$t->back;
$t->follow_link_ok(
	{ text => 'Laptop Contest!' },
	'Follow link to see a forum thread with some nested comments'
);
$t->title_is(
	'Laptop Contest! - ShinySite',
	"Reached 'laptop contest' thread"
);
$t->back;
$t->follow_link_ok(
	{ text => 'No talking' },
	'Go back, then follow link to see a forum post with no comments'
);
$t->title_is(
	'No talking - ShinySite',
	"Reached 'no talking' thread"
);
$t->get_ok(
	'/forums/hardware/laptops/999/no-such-post',
	'Try to load non-existent forum post'
);
$t->text_contains(
	'Failed to find specified forum post.',
	'Got appropriate error message'
);

# Posts by specified author
$t->get_ok(
	'/forums/author/admin',
	"Try to load page of posts by user 'admin'"
);
$t->text_contains(
	'No talking',
	"Found posts posted by user 'admin'"
);
$t->get_ok(
	'/forums/author/admin?page=2&count=3',
	"Try to load second page of (3) posts by user 'admin'"
);

# Posts with specified tag
$t->get_ok(
	'/forums/tag/test',
	"Try to load page of posts tagged with 'test'"
);
$t->text_contains(
	'Laptop Contest!',
	"Found post tagged with 'test'"
);
my $path = $t->uri->path;
$t->get_ok(
	'/forums/tag/test?page=2&count=3',
	"Try to load second page of (3) posts tagged with 'test'"
);

# Load the user profile page of the default admin account
# (Exercises the get_recent_forum_post() method)
$t->get_ok(
	'/user/admin',
	"Fetch the default admin user's profile page"
);
$t->title_is(
	'Admin - ShinySite',
	"Loaded the profile page for the 'admin' user"
);
$t->text_contains(
	'Laptop Contest!',
	"Found link to forum post by 'admin'"
);

# Try to post to the forums without logging in first
$t->get_ok(
	'/forums/post/hardware/laptops',
	'Try to load the page for posting to the forums, while not logged in'
);
$t->title_is(
	'Log In - ShinySite',
	'Loaded the login page instead'
);
$t->text_contains(
	'You must be logged in to post on the forums.',
	'Got appropriate error message'
);
$t->post_ok(
	'/forums/add-post-do',
	{
		title => 'Fail Test',
	},
	'Try to post directly to form handler despite still not being logged in'
);
$t->title_is(
	'Log In - ShinySite',
	'Loaded the login page again'
);
$t->text_contains(
	'You must be logged in to post on the forums.',
	'Got that helpful error message again'
);

# Log in
my $forum_tester = create_test_user( 'forum_tester' );
$t = login_test_user( 'forum_tester', 'forum_tester' )
	or die 'Failed to log in as forum_tester';

# Post to the forum
$t->get_ok(
	'/forums/post/hardware/laptops',
	'Load the page for posting to the laptops forums'
);
$t->title_is(
	'Add new thread - ShinySite',
	'Reached the page for posting to the laptops forums'
);
$t->submit_form_ok({
	form_id => 'add_post',
	fields => {
		title => 'Test Forum Post',
		url_title => 'test-post',
		body => '<p>This is a test post in the laptops forum.</p>',
		tags => 'test, forum, post',
	}},
	'Submit form to create a new post in the laptops forum'
);
# Post again
$t->get_ok(
	'/forums/post/hardware/laptops',
	'Reload the page for posting to the laptops forums'
);
$t->submit_form_ok({
	form_id => 'add_post',
	fields => {
		title => 'Second Test Post',
		body  => '<p>This is another test post.</p>',
	}},
	'Submit form to create another new post'
);

# Log out
$t->follow_link_ok(
	{ text => 'logout' },
	'Log out'
);

# Call search method without setting search param
my $c = $t->ctx;
my $results = $c->controller( 'Forums' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ forum_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);


my @top_poster = $c->controller( 'Forums' )->get_top_posters( $c, 1 );
ok(
	scalar @top_poster == 1,
	'Found our top forum poster'
);

my @top_posters = $c->controller( 'Forums' )->get_top_posters( $c );
ok(
	scalar @top_posters == 10,
	'Found the top 10 forum posters'
);


# Tidy up
$forum_tester->forum_posts->delete;
$forum_tester->comments->delete;
remove_test_user( $forum_tester );

done_testing();
