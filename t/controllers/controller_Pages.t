# ===================================================================
# File:		t/controllers/controller-Pages.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS page features
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

# Get a connected Schema object
my $schema = get_schema();

# Get a Mech object
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Fetch site homepage a few different ways, to test default section/page code
$t->get_ok(
	'/pages',
	'Fetch /pages'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller but not section or page)'
);
$t->get_ok(
	'/pages/home',
	'Fetch /pages/home'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller and section but not page)'
);
$t->get_ok(
	'/pages/home/home',
	'Fetch /pages/home/home'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded default CMS page (specified controller, section, and page)'
);
# Load a different CMS page in a different section
$t->follow_link_ok(
	{ text => 'Feature List' },
	"Follow link to 'feature list' page"
);
$t->title_is(
	'Feature List - ShinySite',
	'Loaded feature list page'
);
# Load a section with no default page configured
$t->follow_link_ok(
	{ text => 'More' },
	"Follow link to 'More' section"
);
$t->title_is(
	'About ShinyCMS - ShinySite',
	"Loaded 'About ShinyCMS' page - the first page in that section"
);


# Test 404 handling
$t->get( '/pages/NO_SUCH_SECTION' );
ok(
	$t->status == 404,
	'Trying to visit missing section gets 404 error'
);
$t->title_is(
	'Page Not Found - ShinySite',
	'404 page loads instead'
);
$t->content_contains(
	'<form id="search" action="/search" method="post">',
	'404 page includes site search form'
);
$t->get( '/pages/home/NO_SUCH_PAGE' );
ok(
	$t->status == 404,
	'Trying to visit missing page in valid section also gets 404 error'
);


my $c = $t->ctx;
my $P = 'ShinyCMS::Controller::Pages';


# Exercise the default/fall-through page handler for sites with no content
$P->no_page_data( $c );
ok(
	$c->response->body =~ m{If you are the site admin, please add some content},
	'Got expected fall-through text when calling no_page_data() directly'
);


# Test some failure conditions in utility methods
my $orig_default_section      = $c->stash->{ section };
my $orig_default_section_id   = $c->stash->{ section }->id;
my $orig_default_section_name = $P->default_section( $c );
my $orig_default_page_id      = $c->stash->{ section }->default_page->id;
my $orig_default_page_name    = $P->default_page( $c );

ok(
	$orig_default_section_name eq 'home',
	"Confirmed that the original default section url_name is 'home'"
);
ok(
	$orig_default_page_name eq 'home',
	"Confirmed that the original default page url_name is 'home'"
);

$c->stash->{ section }->update({ default_page => undef });
my $fallback_default_page_name = $P->default_page( $c );
ok(
	$fallback_default_page_name eq 'contact-us',
	"Confirmed that the fallback default page url_name is 'contact-us'"
);
$c->stash->{ section }->update({ default_page => $orig_default_page_id });

# Create an empty section
my $empty = $c->model( 'DB::CmsSection' )->find_or_create({
	name     => 'Empty Test Section',
	url_name => 'empty'
});

# Wipe the section from the stash
delete $c->stash->{ section };

# Redirect STDERR to /dev/null while we run noisy tests
open my $origstderr, '>&', STDERR;
open STDERR, '>', File::Spec->devnull() or die "Could not open STDERR: $!";

my $no_default_page_found = $P->default_page( $c ) ? 0 : 1;
ok(
	$no_default_page_found,
	'Removed section from stash, verified that default page cannot be found'
);

$c->stash->{ section } = $empty;
my $no_default_page_found2 = $P->default_page( $c ) ? 0 : 1;
ok(
	 $no_default_page_found2,
	 'default_page() returned undef for section with no pages'
);
# TODO: Better test here! Something like this? Use Try::Tiny?
#ok(
#	 STDERR =~ m{stashed section has no pages},
#	 'Got warning for calling default_page() on section with no pages'
#);

# Restore STDERR
open STDERR, '>&', $origstderr or die "Can't restore stderr: $!";

# Restore the correct section to the stash
$c->stash->{ section } = $orig_default_section;


# Call search method without setting search param
$c = $t->ctx;
my $results = $c->controller( 'Pages' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ page_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') returns undef and stashes no results"
);

# Test the get_feed_items() method
my $feed = $schema->resultset( 'Feed' )->find_or_create({
	name => 'Test',
	url  => 'https://shinycms.org/static/feeds/atom.xml',
});
$feed->feed_items->find_or_create({
	title => 'A Test Feed Item',
});
$feed->feed_items->find_or_create({
	title => 'Another Test Item',
});
my $feed_items = $c->controller( 'Pages' )->get_feed_items( $c, 'Test' );
ok(
	$feed_items->count == 2,
	'Got two feed items'
);
my $feed_1item = $c->controller( 'Pages' )->get_feed_items( $c, 'Test', 1 );
ok(
	$feed_1item->count == 1,
	'Got one feed item'
);


# Tidy up
$empty->delete;
$feed->feed_items->delete;
$feed->delete;

done_testing();
