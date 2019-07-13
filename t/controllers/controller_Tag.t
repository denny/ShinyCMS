# ===================================================================
# File:		t/controllers/controller-Tag.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS tag controller
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


# Get db handle, create some odd test data to exercise edge cases
my $schema = get_schema();

# A resource that does exist, but of a resource type that doesn't have tags
my $category_id = $schema->resultset( 'ShopCategory' )->search({})->first->id;
my $tagset1 = $schema->resultset( 'Tagset' )->create({
	resource_type => 'ShopCategory',
	resource_id   => $category_id
});
my $tag1 = $tagset1->tags->create({ tag => 'demo' });

# A resource type that we do handle, but an item that doesn't exist
my $tagset2 = $schema->resultset( 'Tagset' )->create({
	resource_type => 'BlogPost',
	resource_id   => 666
});
my $tag2 = $tagset2->tags->create({ tag => 'demo' });


# Get a mech object
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
	'/tag',
	'Fetch list of tags'
);
$t->title_is(
	'Tag List - ShinySite',
	'Loaded list of tags'
);
$t->get_ok(
	'/tag/tag-cloud',
	'Fetch tag cloud'
);
$t->title_is(
	'Tag Cloud - ShinySite',
	'Loaded tag cloud'
);
$t->get_ok(
	'/tag/demo',
	"Fetch page for 'demo' tag"
);
$t->title_is(
	"Content tagged 'demo' - ShinySite",
	"Loaded individual tag page for 'demo' tag"
);


# Tidy up
$tag1->delete;
$tag2->delete;
$tagset1->delete;
$tagset2->delete;

done_testing();
