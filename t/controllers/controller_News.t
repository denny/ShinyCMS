# ===================================================================
# File:		t/controllers/controller-News.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS news controller
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

# Posts
$t->get_ok(
	'/news',
	'Fetch list of news'
);
$t->title_is(
	'News - ShinySite',
	'Loaded list of news'
);
$t->get_ok(
	'/news?page=2&count=3',
	'Test pagination of recent posts'
);
$t->back;
$t->follow_link_ok(
	{ text => '"Straighten your pope hat."' },
	'Go back, click on link to open most recent news article'
);
$t->title_is(
	'"Straighten your pope hat." - ShinySite',
	'Reached most recent news article'
);
$t->back;

# Tags
$t->follow_link_ok(
	{ text => 'Bender Burgers' },
	'Go back, click on link to open earliest news article, which has a tag'
);
$t->title_is(
	'Bender Burgers - ShinySite',
	'Reached earliest news article'
);
$t->text_contains(
	'Tags: truck',
	'Found expected tag list'
);
$t->follow_link_ok(
	{ text => 'truck' },
	'Clicked on tag'
);
$t->title_is(
	"News tagged 'truck' - ShinySite",
	'Reached listing of tagged news items'
);
$t->get_ok(
	'/news/tag/truck?page=2&count=3',
	'Test pagination of tagged posts'
);

# Invalid URLs
$t->get( '/news/FOO/12/no-such-post' );
ok(
	$t->status == 400,
	'Trying to fetch news URL with invalid year throws 400 error'
);
$t->text_contains(
	'Year must be a number',
	'Page body contains appropriate error message for invalid year'
);
$t->get( '/news/1999/0/still-no-such-post'        );
ok(
	$t->status == 400,
	'Trying to fetch news URL with month=0 throws 400 error'
);
$t->get( '/news/1999/123/still-no-such-post'      );
ok(
	$t->status == 400,
	'Trying to fetch news URL with month=123 throws 400 error'
);
$t->get( '/news/1999/December/still-no-such-post' );
ok(
	$t->status == 400,
	'Trying to fetch news URL with month=December throws 400 error'
);
$t->text_contains(
	'Month must be a number between 1 and 12',
	'Page body contains appropriate error message for invalid month'
);
$t->get_ok(
	'/news/1999/12/ALSO-NO-SUCH-POST',
	'Try to fetch non-existent news item'
);
$t->title_is(
	'News - ShinySite',
	'Loaded recent news items instead'
);
$t->text_contains(
	'Failed to find specified news item.',
	'Page contains appropriate error message for non-existent item'
);

# Call search method without setting search param
my $c = $t->ctx;
my $results = $c->controller( 'News' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ news_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);

done_testing();
