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

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my( $test_user, $pw ) = create_test_user();

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/blog',
    'Get recent blog posts page'
);
$t->title_is(
    'Recent posts - ShinySite',
    'Reached recent posts page'
);
$t->follow_link_ok(
    { text => '0 comments' },
    'Click on link to first blog post'
);
$t->title_is(
    'A nondescript white 18-wheeler - ShinySite',
    'Reached first blog post'
);
$t->follow_link_ok(
    { text => 'truck' },
    'Click on truck tag'
);
$t->title_is(
    "Posts tagged 'truck' - ShinySite",
    'Reached list of tagged blog posts'
);
$t->follow_link_ok(
    { text => 'Blog' },
    'Click on menu link for blog'
);
$t->follow_link_ok(
    { text_regex => qr/Older$/ },
    'Click on link to older posts'
);
$t->follow_link_ok(
    { text_regex => qr/^\d+ comments?$/, n => 3 },
    'Click on link to third post on this page'
);
$t->title_is(
    'w1n5t0n - ShinySite',
    'Reached blog post'
);
$t->follow_link_ok(
    { text => 'Add a new comment' },
    "Click 'add new comment' link"
);
$t->title_is(
    'Reply to: w1n5t0n - ShinySite',
    'Reached top-level comment page'
);
$t->back;
$t->follow_link_ok(
    { text => '0 likes' },
    "Click 'like' on first comment, before logging in"
);
my $path = $t->uri->path;

# Log in
$t = login_test_user() or die 'Failed to log in as non-admin test user';

$t->get( $path );
$t->follow_link_ok(
    { text => '1 like' },
    "Click 'like' on first comment, after logging in"
);

# Tidy up
my $user_like = $test_user->comments_like->first;
$user_like->update({ user => undef });
$user_like->comment->comments_like->delete_all;

remove_test_user();

done_testing();
