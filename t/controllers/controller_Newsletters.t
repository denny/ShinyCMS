# ===================================================================
# File:		t/controllers/controller-Newsletters.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS newsletter controller
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

# Get the list of recent newsletters
$t->get_ok(
	'/newsletters',
	'Fetch list of newsletters'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Loaded list of newsletters'
);
# View an individual newsletter
$t->follow_link_ok(
	{ text => 'Donations and a word to teachers and librarians' },
	'Click on link to view newsletter'
);
$t->content_contains(
	"<h1>\n\tDonations and a word to teachers and librarians\n</h1>",
	'Loaded newsletter'
);
# Try to fetch a non-existent newsletter
$t->get_ok(
	'/newsletters/2012/01/does-not-exist',
	'Try to view a non-existent newsletter'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Redirected back to list of newsletters instead'
);
$t->text_contains(
	'Specified newsletter not found',
	'Got helpful error message about missing newsletter'
);
# Give paging code some basic exercise
$t->get_ok(
	'/newsletters/view?page=2&count=5',
	'Fetch second page of newsletter list, 5 items per page'
);
$t->title_is(
	'Newsletters - ShinySite',
	'Loaded list of newsletters'
);
# Try to view mailing list subscriptions before logging in
$t->get_ok(
	'/newsletters/lists',
	'Try to view mailing list subscriptions, before logging in'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'You need to log in before you can edit your mailing list subscriptions',
	'... and got a message telling us to log in'
);
# Try to view mailing list subscriptions before logging in, using a token
$t->get_ok(
	'/newsletters/lists/abcd1234abcd1234abcd1234abcd3333',
	'Try to view mailing list subscriptions, using token'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'You can only see the private lists that you are currently subscribed to.',
	'Reached list subscriptions page, including a private list'
);
# Log in
$t = login_test_user( 'admin', 'changeme' ) or die 'Failed to log in';
# Try to view mailing list subscriptions after logging in
$t->get_ok(
	'/newsletters/lists',
	'Try to view mailing list subscriptions, after logging in'
);
$t->title_is(
	'Mailing Lists - ShinySite',
	'Reached the lists page...'
);
$t->text_contains(
	'To subscribe to a list, check the box next to it.',
	'Reached subscribe/unsubscribe page for mailing lists'
);
$t->submit_form_ok({
	form_id => 'list_subs',
	fields => {
		lists => [ 1 ],
	}},
	'Submitted form subscribing to list 1 and unsubscribing from list 2'
);
my $content = $t->content;
my @lines = split("\n", $content);
my @matches = grep { /input/ } @lines;
foreach my $match ( @matches ) {
	$match =~ s/^\s+//;
	print $match, "\n";
}
my @inputs = $t->grep_inputs({ name => qr/^lists$/ });
warn @inputs if @inputs;
warn '@inputs is undef' unless @inputs;
my $input = $inputs[0];
warn $input if $input;
warn '$input is undef' unless $input;
warn $input->value if $input;

# TODO ...

done_testing();
