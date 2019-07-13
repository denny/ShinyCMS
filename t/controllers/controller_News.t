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

$t->get_ok(
	'/news',
	'Fetch list of news'
);
$t->title_is(
	'News - ShinySite',
	'Loaded list of news'
);
$t->follow_link_ok(
	{ text => '"Straighten your pope hat."' },
	'Clicked on link to open most recent news article'
);
$t->title_is(
	'"Straighten your pope hat." - ShinySite',
	'Reached most recent news article'
);
$t->back;
$t->follow_link_ok(
	{ text => 'Bender Burgers' },
	'Clicked on link to open earliest news article, which has a tag'
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
	"Posts tagged 'truck' - ShinySite",
	'Reached listing of tagged news items'
);


done_testing();
