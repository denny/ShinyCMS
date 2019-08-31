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

use lib 't/support';
require 'login_helpers.pl';  ## no critic


# Get a mech object
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Start at the beginning  :)
$t->get_ok(
	'/shop',
	'Fetch shop homepage'
);
$t->title_is(
	'Shop Categories - ShinySite',
	'Loaded shop homepage (currently, shop categories page)'
);

# View and page through recent items
$t->get_ok(
	'/shop/recent',
	'View recently-added items'
);
$t->get_ok(
	'/shop/recent/2/5',
	'View recently-added items, page 2, 5 items per page'
);

# List of categories
$t->get_ok(
	'/shop/category',
	'Try to fetch /category without a category specified'
);
$t->title_is(
	'Shop Categories - ShinySite',
	'Loaded shop categories page again'
);
$t->get_ok(
	'/shop/categories',
	'Fetch category list deliberately at /shop/categories'
);
$t->title_is(
	'Shop Categories - ShinySite',
	'Loaded shop categories page'
);

# List of items in empty category
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/doodahs$} },
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

# List of items in non-empty category
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/widgets$} },
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

# Individual item
$t->follow_link_ok(
	{ url_regex => qr{/shop/item/[-\w]+$}, n => 3 }, # 2 links per item
	'Click on link to view second item'
);
$t->title_is(
	'Green ambidextrous widget - ShinySite',
	'Loaded individual item page'
);
my $widget_path = $t->uri->path;

# Go to alt category page from item page
$t->follow_link_ok(
	{ url_regex => qr{/shop/category/[-\w]+$}, n => 2 },
	'Click on link to view second category in list from item page'
);
$t->title_is(
	'Ambidextrous Widgets - ShinySite',
	'Loaded Ambidextrous Widgets category page'
);

# Back to item page, try like/unlike/favourite
$t->back;
$t->follow_link_ok(
	{ text => 'Like this item' },
	'Click on link to like this item'
);
$t->text_contains(
	'You like this item',
	"Verified that 'like' feature worked"
);
$t->get_ok(
	$t->uri->path . '/favourite',
	'Try to add item to favourites, whilst not logged in'
);
$t->text_contains(
	'You must be logged in to add favourites',
	'Adding to favourites failed due to not being logged in'
);

# Try to view favourites
$t->add_header( Referer => undef );
$t->get_ok(
	'/shop/favourites',
	'Try to view favourite items, before logging in'
);
$t->text_contains(
	'You must be logged in to view your favourites',
	'Favourites feature only available to logged in users'
);

# Try to see list of recently viewed items (won't work, not logged in yet)
$t->get_ok(
	'/shop/recently-viewed',
	'Try to view recently-viewed items, whilst not logged in'
);
$t->text_contains(
	'You must be logged in to see your recently viewed items',
	'Recently viewed feature only available to logged in users'
);

# Log in
my $user1 = create_test_user( 'test_shop_user1' );
$t = login_test_user( $user1->username, $user1->username ) or die 'Failed to log in';
my $c = $t->ctx;
ok(
	$c->user->username eq 'test_shop_user1',
	'Logged in as a test user'
);

# Look at recently viewed again
$t->get_ok(
	'/shop/recently-viewed',
	'Try to view recently-viewed items, after logging in'
);
$t->title_is(
	'Recently Viewed - ShinySite',
	'Loaded recently viewed items'
);
$t->text_contains(
	'Viewing items 0 to 0 of 0',
	'No recently-viewed items ... yet'
);

# Go look at an item
$t->get_ok(
	$widget_path,
	'Look at a widget again'
);

# Like item as a logged-in user
$t->follow_link_ok(
	{ text => 'Like this item' },
	'Click on link to like item as logged-in user'
);
$t->text_contains(
	'You like this item',
	"Verified that 'like' feature worked"
);

# Add to favourites now that we're logged in
$t->follow_link_ok(
	{ text => 'Add to favourites' },
	'Click on link to add this item to favourites'
);
$t->text_contains(
	'Remove from favourites',
	'Verified that adding to favourites worked'
);

# View and page through favourites
$t->get_ok(
	'/shop/favourites',
	'View favourite items'
);
$t->get_ok(
	'/shop/favourites/2/5',
	'View favourite items, page 2, 5 items per page'
);

# Look at recently viewed again
$t->get_ok(
	'/shop/recently-viewed',
	'Then go back to recently-viewed items page'
);
$t->text_contains(
	'Viewing items 1 to 1 of 1',
	'And now we have something in recently-viewed items!'
);

# Log in as a different user
my $user2 = create_test_user( 'test_shop_user2' );
$t = login_test_user( $user2->username, $user2->username ) or die 'Failed to log in';
$c = $t->ctx;
ok(
	$c->user->username eq 'test_shop_user2',
	'Logged in as a different test user'
);
$t->get_ok(
	$widget_path,
	'Look at the same widget again'
);

# Log back in as first user, remove like and favourite
$t = login_test_user( $user1->username, $user1->username ) or die 'Failed to log in';
$c = $t->ctx;
ok(
	$c->user->username eq 'test_shop_user1',
	'Logged back in as first test user'
);
$t->get_ok(
	$widget_path,
	'Back to the widget page again'
);
$t->follow_link_ok(
	{ text => 'Remove from favourites' },
	'Click on link to remove this item from favourites'
);
$t->text_contains(
	'Add to favourites',
	'Verified that removing from favourites worked'
);
$t->follow_link_ok(
	{ text => 'undo' },
	"Click on link to remove 'like' from this item"
);
$t->text_contains(
	'Like this item',
	"Verified that 'like' removal worked"
);

# Log out, remove anon like
$t->follow_link_ok(
	{ text => 'logout' },
	'Log out'
);
$t->get_ok(
	$widget_path,
	'Back to the widget page again again'
);
$t->follow_link_ok(
	{ text => 'undo' },
	"Click on link to remove 'like' from this item"
);
$t->text_contains(
	'Like this item',
	"Verified that 'like' removal worked"
);

# Tags
$t->follow_link_ok(
	{ text => 'green' },
	"Click on link to view items tagged 'green'"
);
$t->title_is(
	"Items tagged 'green' - ShinySite",
	"Reached list of items tagged 'green'"
);
$t->text_contains(
	'Viewing items 1 to 2 of 2',
	'Found two items, as expected'
);
$t->get_ok(
	'/shop/tag/green/2/5',
	'View tagged items, page 2, 5 items per page'
);

# Try to view non-existent category
$t->get_ok(
	'/shop/category/DOES-NOT-EXIST',
	'Try to view non-existent category'
);
$t->text_contains(
	'Category not found - please choose from the options below',
	'Got helpful error message about non-existent category'
);

# Try to view non-existent item
$t->get_ok(
	'/shop/item/NO-SUCH-ITEM',
	'Try to view non-existent item'
);
$t->text_contains(
	'Specified item not found. Please try again.',
	'Got helpful error message about non-existent item'
);

# Try to view basket
$t->get_ok(
	'/shop/basket',
	'Try to view basket'
);
$t->title_is(
	'Your Basket - ShinySite',
	'Loaded shopping basket'
);
# Try to view checkout with empty basket
$t->get_ok(
	'/shop/checkout',
	'Try to view checkout with no items in basket'
);
$t->title_is(
	'Your Basket - ShinySite',
	'Redirected to shopping basket'
);
$t->text_contains(
	'There is nothing in your basket',
	'Got helpful error message about empty basket'
);

# Go to item page
$t->get_ok(
	'/shop/item/blue-lh-widget',
	'Go to item page'
);
$t->title_is(
	'Blue left-handed widget - ShinySite',
	'Loaded item page'
);
# Put item in basket
$t->submit_form_ok({
	form_id => 'add_to_basket',
	fields => {
		quantity => '1',
	}},
	'Submitted form to add item to basket'
);
$t->text_contains(
	'Item added.',
	'Got confirmation message that item has been added to basket'
);
$t->get_ok(
	'/shop/basket',
	'View basket'
);
$t->title_is(
	'Your Basket - ShinySite',
	'Loaded shopping basket'
);
$t->follow_link_ok(
	{ text => 'Empty basket' },
	'Click link to empty basket'
);
$t->text_contains(
	'Basket emptied.',
	'Got confirmation message that basket was emptied.'
);
# Put item in basket again
$t->get_ok(
	'/shop/item/blue-lh-widget',
	'Go back to item page'
);
$t->submit_form_ok({
	form_id => 'add_to_basket',
	fields => {
		quantity => '1',
	}},
	'Add item to basket again'
);
$t->post_ok(
	'/shop/basket/remove-item',
	{
		item_id => 1,
	},
	'Post request to remove item from basket'
);
$t->text_contains(
	'Item removed.',
	'Got confirmation message that item was removed.'
);
# Put item in basket again
$t->get_ok(
	'/shop/item/blue-lh-widget',
	'Go back to item page'
);
$t->submit_form_ok({
	form_id => 'add_to_basket',
	fields => {
		quantity => '1',
	}},
	'Add item to basket again'
);
$t->submit_form_ok({
	form_id => 'add_to_basket',
	fields => {
		quantity => '2',
	}},
	'Submitted form to add 2 more of item to basket'
);
$t->text_contains(
	'Items added.',
	'Got confirmation message that items have been added to basket'
);
# Put another item in the basket
$t->get_ok(
	'/shop/item/green-t-shirt',
	'Go to another item page'
);
$t->title_is(
	'Green T-shirt - ShinySite',
	'Loaded t-shirt page'
);
$t->submit_form_ok({
	form_id => 'add_to_basket',
	fields => {
		quantity => '1',
		shop_item_attribute_colour => 'Black',
		shop_item_attribute_size   => 'Small',
	}},
	'Add item to basket again'
);
# View basket again
$t->follow_link_ok(
	{ url_regex => qr{/shop/basket$} },
	'Click on link to view basket contents'
);
$t->title_is(
	'Your Basket - ShinySite',
	'Loaded shopping basket'
);
$t->text_contains(
	'Blue left-handed widget',
	'Verified that item added earlier is in basket'
);
# Update basket
$t->form_id( 'update_basket' );
my @quantity_inputs = $t->grep_inputs({
	name => qr{^quantity_\d+$},
});
my $quantity_one = $quantity_inputs[0]->name;
my $quantity_two = $quantity_inputs[1]->name;
$t->submit_form_ok({
	form_id => 'update_basket',
	fields => {
		$quantity_one => '5',
		$quantity_two => '0',
	}},
	'Submitted form to update basket to contain 5 widgets and 0 t-shirts'
);
$t->text_contains(
	'Basket updated',
	'Got confirmation message that basket was updated'
);

# Try to view checkout again
$t->follow_link_ok(
	{ text => 'Go to checkout' },
	'Click on link to go to checkout'
);
$t->title_is(
	'Checkout: Billing Address - ShinySite',
	'Loaded first page of checkout process; enter billing address'
);

# Hit some checkout URLs in the wrong order, to make sure we get redirected
$t->get_ok(
	'/shop/checkout/delivery-address',
	'Attempt to load delivery address page before setting billing address'
);
$t->text_contains(
	'You must fill in your billing address before you can continue.',
	'Got redirected, with appropriate error message'
);
$t->get_ok(
	'/shop/checkout/postage-options',
	'Attempt to load postage options page before setting billing address'
);
$t->text_contains(
	'You must fill in your billing address before you can continue.',
	'Got redirected, with appropriate error message'
);
$t->get_ok(
	'/shop/checkout/payment',
	'Attempt to load payment page before setting billing address'
);
$t->text_contains(
	'You must fill in your billing address before you can continue.',
	'Got redirected, with appropriate error message'
);

# Submit billing address
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		get_delivery_address => 'on',
	}},
	'Submit billing address form with entire address missing'
);
$t->text_contains(
	'Please fill in your address.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		address  => '1 Test Avenue',
	}},
	'Submit billing address form with most of address missing'
);
$t->text_contains(
	'Please fill in your town.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
	}},
	'Submit billing address form with a bit more address added'
);
$t->text_contains(
	'Please select your country.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
	}},
	'Submit billing address form with more but still not enough address added'
);
$t->text_contains(
	'Please select your country.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
		country  => 'UK',
	}},
	'Submit billing address form with almost the full address'
);
$t->text_contains(
	'Please fill in your postcode.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_billing_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
		postcode => 'T3 5TS',
		country  => 'UK',
		get_delivery_address => 'on',
	}},
	'Submit billing address form with full address'
);
$t->title_is(
	'Checkout: Delivery Address - ShinySite',
	'Loaded (optional) second page of checkout process; enter delivery address'
);

# More out-of-sequence checks
$t->get_ok(
	'/shop/checkout/postage-options',
	'Attempt to load postage options page before setting delivery address'
);
$t->text_contains(
	'You must fill in your delivery address before you can continue.',
	'Got redirected, with appropriate error message'
);
$t->get_ok(
	'/shop/checkout/payment',
	'Attempt to load payment page before setting delivery address'
);
$t->text_contains(
	'You must fill in your delivery address before you can continue.',
	'Got redirected, with appropriate error message'
);

# Submit delivery address
$t->submit_form_ok({
	form_id => 'checkout_delivery_address',
	fields  => {
		county   => 'Testshire',
	}},
	'Submit delivery address form with most of address missing'
);
$t->text_contains(
	'Please fill in your address.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_delivery_address',
	fields  => {
		address  => '1 Test Avenue',
		county   => 'Testshire',
	}},
	'Submit delivery address form with most of address missing again'
);
$t->text_contains(
	'Please fill in your town.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_delivery_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
	}},
	'Submit delivery address form with some but not enough of address added'
);
$t->text_contains(
	'Please fill in your country.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_delivery_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
		country  => 'UK',
	}},
	'Submit delivery address form with almost full address'
);
$t->text_contains(
	'Please fill in your postcode.',
	'Got appropriate error messsage'
);
$t->submit_form_ok({
	form_id => 'checkout_delivery_address',
	fields  => {
		address  => '1 Test Avenue',
		town     => 'Testtown',
		county   => 'Testshire',
		postcode => 'T3 5TS',
		country  => 'UK',
	}},
	'Submit delivery address form with full address'
);
$t->title_is(
	'Checkout: Postage Options - ShinySite',
	'Loaded third page of checkout process; choose postage option'
);

# Last out-of-sequence check
$t->get_ok(
	'/shop/checkout/payment',
	'Attempt to load payment page before setting postage options'
);
$t->text_contains(
	'You must select postage options for all of your items before you can continue.',
	'Got redirected, with appropriate error message'
);

# Get postage option input name from form (changes when tests are re-run)
$t->form_id( 'checkout_postage_options' );
my @postage_inputs = $t->grep_inputs({
	type => qr{^radio$},
	name => qr{^postage_\d+$},
});
# Submit postage options
$t->submit_form_ok({
	form_id => 'checkout_postage_options',
	fields  => {
		$postage_inputs[0]->name => '2',
	}},
	'Submit postage options form'
);
$t->title_is(
	'Checkout: Payment - ShinySite',
	'Loaded fourth page of checkout process; payment details'
);


# get_tags() isn't used in current demo templates, but is used by some end users
$c = $t->ctx;
my $tags = $c->controller( 'Shop' )->get_tags( $c );
ok(
	ref $tags eq 'ARRAY',
	'Controller::Shop->get_tags() returns an arrayref'
);
ok(
	"@$tags" eq 'ambidextrous clothing demo green',
	'The tags are the four we expect from the demo data, in the correct order'
);

# Call search method without setting search param
my $results = $c->controller( 'Shop' )->search( $c );
my $returns_undef = defined $results ? 0 : 1;
my $no_results    = defined $c->stash->{ shop_results } ? 0 : 1;
ok(
	$returns_undef && $no_results,
	"search() without param('search') set returns undef & stashes no results"
);

# Tidy up
$user1->shop_item_views->delete;
$user2->shop_item_views->delete;
remove_test_user( $user1 );
remove_test_user( $user2 );

done_testing();
