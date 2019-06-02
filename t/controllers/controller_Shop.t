# ===================================================================
# File:		t/controllers/controller_Shop.t
# Project:	ShinyCMS
# Purpose:	Tests for shop features
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

# Start at the beginning  :)
$t->get_ok(
    '/shop',
    'Fetch shop homepage'
);
$t->title_is(
    'Shop Categories - ShinySite',
    'Loaded shop homepage'
);
$t->get_ok(
    '/shop/category',
    'Try to fetch /category without a category specified'
);
$t->title_is(
    'Shop Categories - ShinySite',
    'Loaded shop homepage again'
);
$t->follow_link_ok(
    { url_regex => qr{/shop/category/[-\w]+$} },
    'Click on link to view first category'
);
$t->title_is(
    'Doodahs - ShinySite',
    'Loaded Doodah category page'
);
$t->text_contains(
    'Viewing items 0 to 0 of 0',
    'Confirmed that there are no items in this category'
);
$t->back;
$t->follow_link_ok(
    { url_regex => qr{/shop/category/[-\w]+$}, n => 2 },
    'Go back, click on link to view next category'
);
$t->title_is(
    'Widgets - ShinySite',
    'Loaded Widgets category page'
);
$t->text_contains(
    'Viewing items 1 to 3 of 3',
    'Confirmed that there are 3 items in this category'
);
$t->follow_link_ok(
    { url_regex => qr{/shop/item/[-\w]+$}, n => 3 }, # 2 links per item
    'Click on link to view second item'
);
$t->title_is(
    'Green ambidextrous widget - ShinySite',
    'Loaded individual item page'
);
$t->follow_link_ok(
    { text => 'Like this item' },
    'Click on link to like this item'
);
$t->text_contains(
    'You like this item',
    "Verified that 'like' feature worked"
);

done_testing();

# TODO: the next follow_link call stops at the redirect instead of following it,
# for some reason...??

=b0rk b0rk bork

$t->follow_link_ok(
    { text => 'Add to favourites' },
    'Clicked link to add item to favourites'
);
$t->text_contains(
    'You must be logged in to add favourites',
    'Adding to favourites failed due to not being logged in'
);
$t->follow_link_ok(
    { url_regex => qr{/shop/category/[-\w]+$}, n => 2 },
    'Click on link to view second category in list from item page'
);
$t->title_is(
    'Ambidextrous Widgets - ShinySite',
    'Loaded Ambidextrous Widgets category page'
);

# TODO: ...

done_testing();
