# ===================================================================
# File:		t/controllers/controller-Blog.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS blog features
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

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Go to the blog
$t->get_ok(
	'/blog',
	'Get recent blog posts page'
);
$t->title_is(
	'Recent posts - ShinySite',
	'Reached recent posts page'
);
# Look at a blog post
$t->follow_link_ok(
	{ text => '0 comments' },
	'Click on link to first blog post'
);
$t->title_is(
	'A nondescript white 18-wheeler - ShinySite',
	'Reached first blog post'
);
# Look at tagged posts
$t->follow_link_ok(
	{ text => 'truck' },
	'Click on truck tag'
);
$t->title_is(
	"Posts tagged 'truck' - ShinySite",
	'Reached list of tagged blog posts'
);
# Look at older tagged posts
$t->get_ok(
	'/blog/tag/truck?page=2&count=3',
	'View some older tagged posts'
);
# Look at older untagged posts
$t->follow_link_ok(
	{ text => 'Blog' },
	'Click on menu link for blog'
);
$t->follow_link_ok(
	{ text_regex => qr{Older$} },
	'Click on link to older posts'
);
# Look at a post with comments
$t->follow_link_ok(
	{ text_regex => qr{^\d+ comments?$}, n => 3 },
	'Click on link to third post on this page'
);
$t->title_is(
	'w1n5t0n - ShinySite',
	'Reached blog post'
);
# Click through to comment form
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'add new comment' link"
);
$t->title_is(
	'Reply to: w1n5t0n - ShinySite',
	'Reached top-level comment page'
);
# Visit author page
$t->follow_link_ok(
	{ text => 'w1n5t0n' },
	'Click on link to author profile'
);
# Look at older posts by author
$t->get_ok(
	'/blog/author/w1n5t0n?page=2&count=3',
	'View some older posts by an author'
);
# Try to view a post that doesn't exist
$t->get_ok(
	'/blog/2013/1/no-such-blog-post',
	"Try to view a post that doesn't exist"
);
$t->text_contains(
	'Failed to find specified blog post.',
	'Failed to find non-existent blog post'
);
# View a post with comments disabled
$t->get_ok(
	'/blog/2013/1/anything-they-ask',
	'View a blog post with comments disabled'
);
$t->text_contains(
	'Commenting has been disabled on this post',
	'Verified that comments are disabled'
);
# View a post with no tags
$t->get_ok(
	'/blog/2013/1/kidnapped',
	'View a blog post with no tags'
);
$t->text_lacks(
	'Tags:',
	'Verified that there are no tags on this post'
);
# View blog posts from a specified author
$t->get_ok(
	'/blog/author/w1n5t0n',
	'Get blog posts from a specific author'
);
$t->title_is(
	'Recent posts - ShinySite',
	'Reached first page of posts by specified author'
);
# View blog posts from a specified year
$t->get_ok(
	'/blog/2013',
	'Get blog posts from the current year'
);
$t->title_is(
	'Posts from 2013 - ShinySite',
	'Reached first page of posts from 2013'
);
# Request blog posts from an invalid year
$t->get( '/blog/two-thousand-and-thirteen' );
ok(
	$t->status == 400,
	'Attempted to fetch blog posts for invalid year'
);
$t->text_contains(
	'Year must be a number',
	'Got helpful error message'
);
# View posts in a specified month
$t->get_ok(
	'/blog/2013/1',
	'Get blog posts from January 2013'
);
$t->title_is(
	'Posts in January 2013 - ShinySite',
	'Reached first page of posts from January 2013'
);
# View posts in a specified month, with an invalid year
$t->get( '/blog/this-year/1' );
ok(
	$t->status == 400,
	'Attempted to fetch blog posts for invalid year, valid month'
);
$t->text_contains(
	'Year must be a number',
	'Got helpful error message'
);
# View posts in a specified month, with an invalid month
$t->get( '/blog/2014/13' );
ok(
	$t->status == 400,
	'Attempted to fetch blog posts for valid year, invalid month'
);
$t->text_contains(
	'Month must be a number between 1 and 12',
	'Got helpful error message'
);
# View blog post, with an invalid year
$t->get( '/blog/this-year/1/whatever' );
ok(
	$t->status == 400,
	'Attempted to fetch blog post in invalid year'
);
$t->text_contains(
	'Year must be a number',
	'Got helpful error message'
);
# View blog post, with an invalid month
$t->get( '/blog/2014/13/whatever' );
ok(
	$t->status == 400,
	'Attempted to fetch blog post in invalid month'
);
$t->text_contains(
	'Month must be a number between 1 and 12',
	'Got helpful error message'
);


# get_tags() isn't used in current demo templates, but is used by some end users
my $c = $t->ctx;
my $tags = $c->controller( 'Blog' )->get_tags( $c );
ok(
	ref $tags eq 'ARRAY',
	'Controller::Blog->get_tags() returns an arrayref'
);
ok(
	"@$tags" eq 'armed forces cell crowds demo explosions interview paperwork phone prison school sirens surveillance terrorism toilet break truck USA  yard',
	'The tags are the ones we expect from the demo data, in alphabetical order'
);

# Call search method without setting search param
my $results = $c->controller( 'Blog' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ blog_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);

done_testing();
