# ===================================================================
# File:		t/controllers/controller-Forums.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS forums controller
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
	'/forums',
	'Fetch list of forums'
);
$t->title_is(
	'Forums - ShinySite',
	'Loaded list of forums'
);/hardware/laptops
$t->follow_link_ok(
	{ text => 'Hardware' },
	'Follow link to view a forum section'
);
$t->title_is(
	'Hardware - Forums - ShinySite',
	'Reached hardware section'
);
$t->follow_link_ok(
	{ text => 'Desktops' },
	'Follow link to view a single forum, with no content'
);
$t->title_is(
	'Desktops - Hardware - Forums - ShinySite',
	'Reached desktops forum'
);
$t->back;
$t->follow_link_ok(
	{ text => 'Laptops' },
	'Go back, then follow link to view a single forum with some content'
);
$t->title_is(
	'Laptops - Hardware - Forums - ShinySite',
	'Reached laptops forum'
);
$t->follow_link_ok(
	{ text => 'General chat' },
	'Follow link to see a forum thread with some nested comments'
);
$t->title_is(
	'General chat - ShinySite',
	"Reached 'general chat' thread"
);
$t->back;
$t->follow_link_ok(
	{ text => 'No talking' },
	'Go back, then follow link to see a forum post with no comments'
);
$t->title_is(
	'No talking - ShinySite',
	"Reached 'no talking' thread"
);

# Posts by specified author
$t->get_ok(
	'/forums/author/admin',
	"Try to load page of posts posted by user 'admin'"
);
$t->text_contains(
	'No talking',
	"Found posts posted by user 'admin'"
);

# Posts with specified tag
$t->get_ok(
	'/forums/tag/test',
	"Try to load page of posts tagged with 'test'"
);
$t->text_contains(
	'General chat',
	"Found post tagged with 'test'"
);

# Load the user profile page of the default admin account
# (Exercises the get_recent_forum_post() method)
$t->get_ok(
	'/user/admin',
	"Fetch the default admin user's profile page"
);
$t->title_is(
	'Admin - ShinySite',
	"Loaded the profile page for the 'admin' user"
);
$t->text_contains(
	'General chat',
	"Found link to forum post by 'admin'"
);



done_testing();
