# ===================================================================
# File:		t/controllers/controller-Polls.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS polls controller
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

# Look at the polls
$t->get_ok(
	'/polls',
	'Fetch list of polls'
);
$t->title_is(
	'Polls - ShinySite',
	'Loaded list of polls'
);
# Look at a poll
$t->follow_link_ok(
	{ text => 'Poll goes where?' },
	'Click on link to view first poll'
);
$t->title_is(
	'Poll goes where? - ShinySite',
	'Reached poll page'
);
$t->text_like(
	qr{Here.+(0 votes).+There.+(0 votes).+Everywhere.+(0 votes)}sm,
	'No votes cast yet'
);
# Vote in the poll
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '1',
	}},
	'Vote in the poll'
);
$t->title_is(
	'Poll goes where? - ShinySite',
	'Reached poll page'
);
$t->text_like(
	qr{Here.+(1 vote).+There.+(0 votes).+Everywhere.+(0 votes)}sm,
	"1 vote cast for 'Here', none for 'There' or 'Everywhere'."
);
# Try to change our vote
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '3',
	}},
	'Vote again, for a different option'
);
$t->text_contains(
	'Somebody with your IP address has already voted in this poll.',
	'Poll detected that somebody from this IP address has already voted'
);
$t->text_like(
	qr{Here.+(1 vote).+There.+(0 votes).+Everywhere.+(0 votes)}sm,
	'Votes remain unchanged.'
);
# Log in
my $poll_path = $t->uri->path;
my $user1 = create_test_user( 'test_polls_user' );
$t = login_test_user( $user1->username, $user1->username ) or die 'Failed to log in';
# Try to change our vote again
$t->get( $poll_path );
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '3',
	}},
	'Vote again, for a different option, after logging in'
);
$t->text_contains(
	'That vote has been replaced by your vote',
	'Poll overrode previous anon vote with our logged-in vote'
);
$t->text_like(
	qr{Here.+(0 votes).+There.+(0 votes).+Everywhere.+(1 vote)}sm,
	"1 vote cast for 'Everywhere', none for 'Here' or 'There'."
);
# And vote yet again...
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '2',
	}},
	'Vote again, for the remaining option'
);
$t->text_contains(
	'You had already voted in this poll',
	'Poll found our previous vote, and changed it'
);
$t->text_like(
	qr{Here.+(0 votes).+There.+(1 vote).+Everywhere.+(0 votes)}sm,
	"1 vote cast for 'There', none for 'Here' or 'Everywhere'."
);
# Log in as a different user and vote again
my $user2 = create_test_user( 'test_polls_user2' );
$t = login_test_user( $user2->username, $user2->username ) or die 'Failed to log in';
# Try to change our vote again
$t->get( $poll_path );
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '1',
	}},
	'Vote again, as a different logged-in user'
);
$t->text_like(
	qr{Here.+(1 vote).+There.+(1 vote).+Everywhere.+(0 votes)}sm,
	"1 vote cast for 'Here', 1 for 'There', none for 'Everywhere'."
);
# Repeat vote
$t->submit_form_ok({
	form_id => 'poll',
	fields => {
		answer => '1',
	}},
	'Vote again, as the same user, for the same option'
);
$t->text_like(
	qr{You have already voted for .+ in this poll},
	'Poll found our previous vote, and kept it'
);
$t->text_like(
	qr{Here.+(1 vote).+There.+(1 vote).+Everywhere.+(0 votes)}sm,
	"Still 1 vote cast for 'Here', 1 for 'There', and none for 'Everywhere'."
);

# Tidy up
$user2->poll_user_votes->delete;
$user1->poll_user_votes->delete;
remove_test_user( $user2 );
remove_test_user( $user1 );

done_testing();
