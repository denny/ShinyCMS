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
	{ text => 'About ShinyCMS' },
	"Follow link to 'about' page"
);
$t->title_is(
	'About ShinyCMS - ShinySite',
	'Loaded about page'
);

# ...

# Test some failure conditions in utility methods
my $c = $t->ctx;
my $P = 'ShinyCMS::Controller::Pages';

my $orig_default_section_name = $P->default_section( $c );
my $orig_default_section_id   = $c->stash->{ section }->id;
my $orig_default_section      = $c->stash->{ section };

ok(
	$orig_default_section_name eq 'home',
	"Confirmed that the original default section url_name is 'home'"
);
my $orig_default_page_name = $P->default_page( $c );
my $orig_default_page = $c->stash->{ page };
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

delete $c->stash->{ section };
{
	open STDERR, '>', File::Spec->devnull() or die "Could not open STDERR: $!";

	my $no_default_page_found = $P->default_page( $c ) ? 0 : 1;
	ok(
		$no_default_page_found,
		'Removed section from stash, verified that default page cannot be found'
	);
}

# Tidy up
$orig_default_section->update({ default_page => $orig_default_section_id });


done_testing();
