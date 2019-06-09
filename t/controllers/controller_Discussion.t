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
# Post comment as pseudonymous user
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	with_fields => {
		author_type => 'Unverified',
		author_name => 'Test Suite',
		title	   => 'First Test Comment',
		body		=> 'This is a test comment, posted by a pseudonymous user.',
	}},
	'Posting a pseudonymous comment'
);
$t->content_contains(
	'This is a test comment, posted by a pseudonymous user.',
	'Comment posted successfully (pseudonymous)'
);
# Post comment as anonymous user
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type => 'Anonymous',
		title	   => 'Second Test Comment',
		body		=> 'This is a test comment, posted by an anonymous user.',
	}},
	'Posting an anonymous comment'
);
$t->content_contains(
	'This is a test comment, posted by an anonymous user.',
	'Comment posted successfully (anonymous)'
);
# Attempt to comment as a logged-in user, without logging in
my @anons1 = $t->text =~ m{Posted by Anonymous at}g;
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type => 'Site User',
		title	   => 'Not logged in yet...',
		body		=> 'This should post anonymously',
	}},
	'Trying to comment as a logged-in user without being a logged in user'
);
$t->content_contains(
	'This should post anonymously',
	'Comment posted successfully'
);
my @anons2 = $t->text =~ m{Posted by Anonymous at}g;
ok(
	2 + scalar @anons1 == scalar @anons2,
	'But coment was posted anonymously, despite attempted form param manipulation'
);

# Log in
my $comment_tester = create_test_user( 'comment_tester' );
$t = login_test_user( 'comment_tester', 'comment_tester' )
	or die 'Failed to log in as comment tester';

$t->get_ok(
	'/discussion/1/add-comment',
	'Fetch the add-comment page again'
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type => 'Site User',
		title	   => 'Third Test Comment',
		body		=> 'This is a test comment, posted by a logged-in user.',
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
# Log in as another user and like another comment
my $comment_liker = create_test_user( 'comment_liker' );
$t = login_test_user( 'comment_liker', 'comment_liker' )
	or die 'Failed to log in as comment liker';
$t->get( $path );
$t->follow_link_ok(
	{ text => '0 likes' },
	"Click 'like' on an unliked comment, logged in as a different user"
);

# Tidy up
my $liker_like = $comment_liker->comments_like->first;
$liker_like->update({ user => undef });
$liker_like->comment->comments_like->delete;
remove_test_user( $comment_liker  );

my $tester_like = $comment_tester->comments_like->first;
$tester_like->update({ user => undef });
$tester_like->comment->comments_like->delete;
$comment_tester->comments->delete;
remove_test_user( $comment_tester );

done_testing();
