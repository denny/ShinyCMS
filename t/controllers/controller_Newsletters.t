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
# Get checkbox values
$t->form_id( 'list_subs' );
my @inputs1 = $t->current_form->find_input( 'lists' );
my @values1;
foreach my $input1 ( @inputs1 ) {
	push @values1, $input1->value if $input1->value;
}
ok(
	@values1 = [ 2 ],
	'Curently subscribed to list 2'
);
# Update subscription selections
# (unsubscribe from list 2, subscribe to lists 3 & 5, ignore 1 and 4)
$t->form_id( 'list_subs' );
#$t->tick(   'lists', '1' );
$t->untick( 'lists', '2' );
$t->tick(   'lists', '3' );
#$t->tick(   'lists', '4' );
$t->tick(   'lists', '5' );
$t->submit_form();
$t->text_contains(
	'Your subscriptions have been updated',
	'Submitted form to update subscriptions'
);
# Get checkbox values again
$t->form_id( 'list_subs' );
my @inputs2 = $t->current_form->find_input( 'lists' );
my @values2;
foreach my $input2 ( @inputs2 ) {
	push @values2, $input2->value if $input2->value;
}
ok(
	@values2 = [ 3, 5 ],
	'Curently subscribed to lists 3 and 5'
);

# TODO ...

done_testing();
