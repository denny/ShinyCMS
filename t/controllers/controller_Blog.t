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
# Look at older posts
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

done_testing();
