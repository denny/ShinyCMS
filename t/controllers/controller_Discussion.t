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

my $schema = get_schema();

my $blog_discussion_id = $schema->resultset( 'Discussion' )->search({
	resource_type => 'BlogPost',
})->first->id;

my $forum_discussion_id = $schema->resultset( 'Discussion' )->search({
	resource_type => 'ForumPost',
})->first->id;

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
	'/discussion/9999',
	"Try to view a discussion that doesn't exist"
);
$t->text_contains(
	'Discussion not found.',
	'Got appropriate error message'
);
$t->get_ok(
	"/discussion/$blog_discussion_id",
	'Try to view a discussion without context'
);
$t->title_is(
	'w1n5t0n - ShinySite',
	"/discussion/$blog_discussion_id redirects to parent blog post"
);
# Post comment as pseudonymous user
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type  => 'Unverified',
		author_email => 'tester1@shinycms.org',
		author_link  => 'https://shinycms.org',
		title        => 'First Test Comment',
		body         => 'This is a test comment, posted by a pseudonymous user.',
	}},
	'Posting a pseudonymous comment'
);
$t->content_contains(
	'This is a test comment, posted by a pseudonymous user.',
	'Comment posted successfully (pseudonymous)'
);
# Post another comment as pseudonymous user
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type  => 'Unverified',
		author_name  => 'Test Suite',
		author_email => 'tester2@shinycms.org',
		title        => 'Another Test Comment',
		body         => 'This is another pseudonymous test comment.',
	}},
	'Posting a pseudonymous comment with different author details set'
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
		title       => 'Second Test Comment',
		body        => 'This is a test comment, posted by an anonymous user.',
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
		title       => 'Not logged in yet...',
		body        => 'This should post anonymously',
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
	'But comment was posted anonymously, despite attempted form param manipulation'
);

# Log in
my $comment_tester = create_test_user( 'comment_tester' );
$t = login_test_user( 'comment_tester', 'comment_tester' )
	or die 'Failed to log in as comment tester';

$t->get_ok(
	"/discussion/$blog_discussion_id/add-comment",
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
$t->follow_link_ok(
	{ text => 'Reply' },
	'Follow link to reply to a comment'
);
$t->title_like(
	qr{^Reply to:},
	'Reached page for posting a reply'
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_name => 'Testing Testing',
		author_type => 'Unverified',
		title       => 'First Reply',
		body        => 'This is a reply from a pseudonymous user.',
	}},
	'Posting a pseudonymous reply'
);
$t->follow_link_ok(
	{ text => 'Reply', n => 8 },
	'Follow link to reply again'
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type => 'Site User',
		title       => 'Second Reply',
		body        => 'This is a test reply from a logged-in user.',
	}},
	'Posting a logged-in reply'
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

my $like_link = $t->find_link( text => '1 like' );
my $like_url  = $like_link->url;

# Remove the logged-in like
$t->get( $path );
$t->follow_link_ok(
	{ text => '1 like' },
	"Remove the 'like' again"
);

# Try to hide a comment without appropriate admin privs
my $hide_url = $like_url;
$hide_url =~ s{like}{hide};
$t->get( $hide_url );
$t->text_contains(
	'You do not have the ability to hide a comment',
	'Failed to hide a comment without moderator privs'
);

# Try to delete a comment without appropriate admin privs
my $delete_url = $like_url;
$delete_url =~ s{like}{delete};
$t->get( $delete_url );
$t->text_contains(
	'You do not have the ability to delete a comment',
	'Failed to delete a comment without moderator privs'
);


# Discussion attached to a forum post
$t->get_ok(
	"/discussion/$forum_discussion_id",
	'Try to view a forum discussion without context'
);
$t->title_is(
	'Laptop Contest! - ShinySite',
	"/discussion/$forum_discussion_id redirects to parent post on forums"
);
# Post comment as pseudonymous user
$t->follow_link_ok(
	{ text => 'Add a new comment' },
	"Click 'Add a new comment' link"
);
$t->submit_form_ok({
	form_id => 'add_comment',
	fields => {
		author_type => 'Unverified',
		author_name => 'Test Suite',
		title       => 'Test Comment In Forum',
		body        => 'This is a test comment in the forums.',
	}},
	'Posting a comment in the forums'
);
$t->content_contains(
	'This is a test comment in the forums.',
	'Forum comment posted successfully'
);


# Create and log in as a comment moderator
my $moderator = create_test_admin( 'test_comment_mod', 'Comment Moderator' );
$t = login_test_user( $moderator->username, $moderator->username )
	or die 'Failed to log in as Comment Moderator';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Comment Moderator' ),
	'Logged in as Comment Moderator'
);
$t->get( $path );

# Hide and un-hide a comment
$t->follow_link_ok(
	{ url_regex => qr{$hide_url$} },
	'Clicking link to hide a comment'
);
$t->text_contains(
	'Comment hidden',
	'Verified that comment was hidden'
);
$t->follow_link_ok(
	{ url_regex => qr{$hide_url$} },
	'Clicking link to unhide the comment'
);
$t->text_contains(
	'Comment un-hidden',
	'Verified that comment was un-hidden'
);

# Delete a comment
$t->follow_link_ok(
	{ url_regex => qr{$delete_url$} },
	'Clicking link to delete a comment'
);
$t->text_contains(
	'Comment deleted',
	'Verified that comment was deleted'
);

# Call search method without setting search param
$c = $t->ctx;
my $results = $c->controller( 'Discussion' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ discussion_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);


# Tidy up
$moderator->user_logins->delete;
remove_test_admin( $moderator );

remove_test_user( $comment_liker  );

my $tester_like = $comment_tester->comments_like->first;
$tester_like->update({ user => undef });
$tester_like->comment->comments_like->delete;
$comment_tester->comments->delete;
remove_test_user( $comment_tester );

$schema->resultset( 'Comment' )->search({
	author_type => { '!=' => 'Site User' },
})->delete;


done_testing();
