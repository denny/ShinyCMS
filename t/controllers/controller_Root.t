# ===================================================================
# File:		t/controllers/controller-Root.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS root controller (/, search, etc)
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


# Get a mech object
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# /
$t->get_ok(
	'/',
	'Go to /'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded homepage (default CMS page+section, from Pages controller)'
);

# Affilliate tracking
$t->host( '127.0.0.1' );
$t->get_ok(
	'/?affiliate=TEST-AFFILIATE',
	'Go to /affiliate=TEST-AFFILIATE'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded homepage'
);
my $affiliate_cookie = $t->cookie_jar->get_cookies(
	'127.0.0.1',
	'shinycms_affiliate'
);
ok(
	$affiliate_cookie eq 'TEST-AFFILIATE',
	"Verified that affiliate cookie was set to 'TEST-AFFILIATE'"
);

# Log in
$t->get_ok(
	'/login',
	'Go to /login'
);
$t->title_is(
	'Log In - ShinySite',
	'Loaded user login page (from User controller)'
);

# Log out
$t->add_header( Referer => undef );
my $user = create_test_user( 'test_logout' );
$t = login_test_user( $user->username, $user->username )
	or die 'Failed to log in as logout test user';
my $c = $t->ctx;
ok(
	$c->user_exists,
	'User is logged in'
);
$t->get_ok(
	'/logout',
	'Go to /logout'
);
$t->title_is(
	'Home - ShinySite',
	'Get redirected to homepage'
);
my $user_exists = $c->user_exists ? 1 : 0;
ok(
	$user_exists,
	'User is not logged in'
);

# Search
$t->get_ok(
	'/search',
	'Go to /search'
);
$t->title_is(
	'Search - ShinySite',
	'Got search page'
);
# Do a search
$t->submit_form_ok({
	form_id => 'search_form',
	fields => {
		search => 'test'
	}},
	'Submitted search form'
);
$t->title_is(
	'Search Results - ShinySite',
	'Got search results page'
);

# Style switcher
$t->add_header( Referer => undef );
$t->host( '127.0.0.1' );
$t->get_ok(
	'/switch-style/TEST-SWITCHER',
	'Go to /style-switcher/TEST-SWITCHER'
);
$t->title_is(
	'Home - ShinySite',
	'Redirected to homepage'
);
my $stylesheet_cookie = $t->cookie_jar->get_cookies(
	'127.0.0.1',
	'stylesheet'
);
ok(
	$stylesheet_cookie eq 'TEST-SWITCHER',
	"Verified that stylesheet cookie was set to 'TEST-SWITCHER'"
);
$t->get_ok(
	'/switch-style/default',
	'Go to /style-switcher/default'
);
$t->title_is(
	'Home - ShinySite',
	'Redirected to homepage'
);
$stylesheet_cookie = $t->cookie_jar->get_cookies(
	'127.0.0.1',
	'stylesheet'
);
my $removed = $stylesheet_cookie ? 0 : 1;
ok(
	$removed == 1,
	'Verified that stylesheet cookie was removed'
);

# 404
$t->get( '/this-page-does-not-exist' );
ok(
	$t->status == 404,
	'Attempting to load non-existent page reaches 404 handler'
);
$t->title_is(
	'Page Not Found - ShinySite',
	'Got helpful 404 page with search form and link to sitemap'
);
$t->follow_link_ok(
	{ text => 'sitemap' },
	'Click link to visit sitemap'
);
$t->title_is(
	'Sitemap - ShinySite',
	'Reached sitemap page'
);


# Tidy up
$t->cookie_jar->clear( '127.0.0.1' );

done_testing();
