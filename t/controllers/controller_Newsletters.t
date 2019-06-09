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
	'Below is a list of all of our public mailing lists',
	'Reached subscribe/unsubscribe page for mailing lists'
);


done_testing();
