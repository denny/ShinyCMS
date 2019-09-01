# ===================================================================
# File:		t/controllers/controller-Events.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS events controller
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

# Look at the list of events
$t->get_ok(
	'/events',
	'Fetch list of events'
);
$t->title_is(
	'Events - ShinySite',
	'Loaded list of events'
);

# Look at the list of events
my $year = DateTime->now->year;
$t->get_ok(
	"/events/$year/12",
	'Fetch list of events for December'
);
$t->title_is(
	'Events - ShinySite',
	'Loaded list of events'
);
$t->text_contains(
	'Tis the season to be jolly',
	'Found the demo-data event for Xmas Day'
);
$t->back;

# Click through to a single event
$t->follow_link_ok(
	{ text => 'Current Event' },
	'Go back to current event list, click through to single event page'
);
$t->text_contains(
	'This is the second demo/test event, it is happening today',
	'Found the demo-data event for today'
);

# Call search method without setting search param
my $c = $t->ctx;
my $results = $c->controller( 'Events' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ events_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);


done_testing();
