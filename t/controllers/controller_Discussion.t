# ===================================================================
# File:		t/controllers/controller-Discussion.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS discussion features
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

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Check that hand-munged/malformed URLs do something sensible
$t->get_ok(
    '/discussion',
    'Try to fetch /discussion with no params'
);
$t->title_is(
    'Home - ShinySite',
    '/discussion (with no params) redirects to /'
);
$t->get_ok(
    '/discussion/1',
    'Try to view a discussion without context'
);
$t->title_is(
    'w1n5t0n - ShinySite',
    '/discussion/1 redirects to parent blog post'
);
# Fetch the 'add comment' page for a discussion thread
$t->get_ok(
    '/discussion/1/add-comment',
    "Fetch the 'add comment' page for a discusion thread"
);
$t->submit_form_ok({
    form_id => 'add_comment',
    with_fields => {
        author_type => 'Unverified',
        author_name => 'Test Suite',
        title       => 'First Test Comment',
        body        => 'This is a test comment, posted by a pseudonymous user.',
    }},
    'Posting a pseudonymous comment'
);
$t->content_contains(
    'This is a test comment, posted by a pseudonymous user.',
    'Comment posted successfully (pseudonymous)'
);

$t->follow_link_ok(
    { text => 'Add a new comment' },
    "Click 'Add a new comment' link"
);
$t->submit_form_ok({
    form_id => 'add_comment',
    fields => {
        author_type => 'Anonymous',
        title       => 'Second Test Comment',
        body        => 'This is a test comment, posted by an anonymous user.',
    }},
    'Posting an anonymous comment'
);
$t->content_contains(
    'This is a test comment, posted by an anonymous user.',
    'Comment posted successfully (anonymous)'
);

# Log in
$t = login_test_user() or die 'Failed to log in as non-admin test user';

$t->get_ok(
    '/discussion/1/add-comment',
    'Fetch the add-comment page again'
);
$t->submit_form_ok({
    form_id => 'add_comment',
    fields => {
        author_type => 'Site User',
        title       => 'Third Test Comment',
        body        => 'This is a test comment, posted by a logged-in user.',
    }},
    'Posting a logged-in comment'
);
$t->content_contains(
    'This is a test comment, posted by a logged-in user.',
    'Comment posted successfully (logged-in user)'
);
# 'Like' a comment while logged in
$t->follow_link_ok(
    { text => '0 likes' },
    "Click 'like' on first comment, before logging out"
);
# Log out, then go back to where we were
my $path = $t->uri->path;
$t->follow_link_ok(
    { text => 'logout' },
    'Log out'
);
$t->get( $path );
# 'Like' a comment while logged out
$t->follow_link_ok(
    { text => '1 like' },
    "Click 'like' on first comment, after logging out"
);

# Tidy up
my $user_like = $test_user->comments_like->first;
$user_like->update({ user => undef });
$user_like->comment->comments_like->delete;

$test_user->comments->delete;

remove_test_user();

done_testing();
