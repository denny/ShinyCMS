# ===================================================================
# File:		t/admin-controllers/controller_Admin-Shop.t
# Project:	ShinyCMS
# Purpose:	Tests for shop admin features
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
use Try::Tiny;

use lib 't/support';
require 'login_helpers.pl';  ## no critic


# Create some supporting data if it doesn't already exist
my $schema = get_schema();
my $postage = $schema->resultset( 'PostageOption' )->find_or_create({
	name  => 'Standard',
	price => '2.22',
});


# Log in as a Shop Admin
my $admin = create_test_admin(
	'shop_test_admin',
	'Shop Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Shop Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Shop Admin' ),
	'Logged in as Shop Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Shop Items - ShinyCMS',
	'Reached shop admin area'
);


# Add a category
$t->follow_link_ok(
	{ text => 'Add category' },
	'Click on link to add new shop category'
);
$t->submit_form_ok({
	form_id => 'add_category',
	fields => {
		name => 'Test Category',
	}},
	'Submitted form to add new shop category'
);
$t->title_is(
	'Edit Category - ShinyCMS',
	'Redirected to category edit page'
);
my @category_inputs1 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$category_inputs1[0]->value eq 'test-category',
	'Verified that new category was successfully created'
);

# Update category
$t->submit_form_ok({
	form_id => 'edit_category',
	fields => {
		name     => 'Updated Test Category',
		url_name => '',
	}},
	'Submitted form to update shop category'
);
my @category_inputs2 = $t->grep_inputs({ name => qr{^url_name$} });
ok(
	$category_inputs2[0]->value eq 'updated-test-category',
	'Verified that category was successfully updated'
);
$t->submit_form_ok({
	form_id => 'edit_category',
	fields => {
		url_name => 'updated-test-category-with-custom-url-name',
	}},
	'Submitted form to update shop category url_name a bit more'
);
$t->uri->path =~ m{/admin/shop/category/(\d+)/edit};
my $category1_id = $1;

# Create a second category
$t->follow_link_ok(
	{ text => 'Add category' },
	'Click on link to add second new shop category'
);
$t->submit_form_ok({
	form_id => 'add_category',
	fields => {
		name     => 'Second Test Category',
		url_name => 'second-test-category',
		parent   => $category1_id,
	}},
	'Submitted form to add second new shop category'
);
$t->submit_form_ok({
	form_id => 'edit_category',
	fields => {
		parent => undef,
	}},
	'Submitted form to edit second new shop category (remove parent)'
);
$t->submit_form_ok({
	form_id => 'edit_category',
	fields => {
		parent => $category1_id,
	}},
	'Submitted form to edit second new shop category (re-add parent)'
);
$t->uri->path =~ m{/admin/shop/category/(\d+)/edit};
my $category2_id = $1;

# Try to edit a non-existent category
$t->get_ok(
	'/admin/shop/category/999/edit',
	'Try to edit non-existent category'
);
$t->title_is(
	'Shop Categories - ShinyCMS',
	'Got redirected to list of categories instead'
);
$t->text_contains(
	'Specified category not found - please select from the options below',
	'Got a helpful error message about the non-existent category'
);


# Log in as a Template Admin
my $template_admin = create_test_admin(
	'shop_test_template_admin',
	'Shop Admin',
	'CMS Template Admin'
);
$t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as Shop Admin + CMS Template Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Shop Admin' ) && $c->user->has_role( 'CMS Template Admin' ),
	'Logged in as Shop Admin + CMS Template Admin'
);


# Add a product type
$t->follow_link_ok(
	{ text => 'Add product type' },
	'Click on link to add a new product type to the shop'
);
$t->submit_form_ok({
	form_id => 'add_product_type',
	fields => {
		name => 'Test Type'
	}},
	'Submitted form to add new product type'
);
$t->title_is(
	'Edit Product Type - ShinyCMS',
	'Redirected to edit page for product type'
);
my @type_inputs1 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$type_inputs1[0]->value eq 'Test Type',
	'Verified that new product type was successfully created'
);

# Update product type
$t->submit_form_ok({
	form_id => 'edit_product_type',
	fields => {
		name => 'Updated Test Type',
	}},
	'Submitted form to update product type'
);
my @type_inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$type_inputs2[0]->value eq 'Updated Test Type',
	'Verified that product type was successfully updated'
);
# Save product type ID for use when deleting
$t->uri->path =~ m{/admin/shop/product-type/(\d+)/edit};
my $product_type1_id = $1;

# Add element to product type
$t->submit_form_ok({
	form_id => 'add_element',
	fields => {
		new_element => 'test_type_element',
		new_type	=> 'Long Text'
	}},
	'Submitted form to add new element to product type'
);
$t->text_contains(
	'test_type_element',
	'Verified that new element was added'
);

# Add second product type
$t->follow_link_ok(
	{ text => 'Add product type' },
	'Click on link to add a second new product type to the shop'
);
$t->submit_form_ok({
	form_id => 'add_product_type',
	fields => {
		name => 'Second Test Type'
	}},
	'Submitted form to add second new product type'
);
$t->uri->path =~ m{/admin/shop/product-type/(\d+)/edit};
my $product_type2_id = $1;

# Try to view a non-existent product type
$t->get_ok(
	'/admin/shop/product-type/999/edit',
	'Try to edit non-existent product type'
);
$t->title_is(
	'Product Types - ShinyCMS',
	'Got redirected to list of product types instead'
);
$t->text_contains(
	'Specified product type not found - please select from the options below',
	'Got a helpful error message about the non-existent product type'
);


# Log back in as a normal shop admin
$t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Shop Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Shop Admin' ),
	'Logged back in as Shop Admin'
);

# Add a shop item
$t->follow_link_ok(
	{ text => 'Add shop item' },
	'Click on link to add a new item to the shop'
);
$t->submit_form_ok({
	form_id => 'add_item',
	fields => {
		name            => 'Test Item',
		code            => 'test-item',
		tags            => 'test, tests',
		price           => '0',
		stock           => '1',
		hidden          => 'on',
		allow_comments  => 'on',
		postage_options => $postage->id,
		restock_date    => DateTime->now->ymd,
		product_type    => $product_type1_id,
		categories      => $category1_id,
	}},
	'Submitted form to add new item'
);
$t->title_is(
	'Edit Item - ShinyCMS',
	'Redirected to edit page for item'
);
my @item_inputs1 = $t->grep_inputs({ name => qr{^code$} });
ok(
	$item_inputs1[0]->value eq 'test-item',
	'Verified that new item was successfully created'
);

# Update item
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		name            => 'Updated Test Item',
		code            => '',
		tags            => '',
		price           => '',
		stock           => '',
		hidden          => undef,
		allow_comments  => undef,
		postage_options => undef,
		restock_date    => undef,
	}},
	'Submitted form to update item name and wipe a bunch of other stuff'
);
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		tags           => 'test, tests, tags',
		price          => '0',
		stock          => '1',
		hidden         => 'on',
		allow_comments => 'on',
		postage_options => $postage->id,
		restock_date    => DateTime->now->ymd,
		categories     => [ $category1_id, 1 ],
		categories     => [ $category2_id, 2 ],
	}},
	'Submitted form again, re-adding stuff, and adding a second category'
);
my @item_inputs2 = $t->grep_inputs({ name => qr{^code$} });
ok(
	$item_inputs2[0]->value eq 'updated-test-item',
	'Verified that item was successfully updated'
);
# Save item ID so we can delete it later
$t->uri->path =~ m{/admin/shop/item/(\d+)/edit};
my $item1_id = $1;


# Log in as Template Admin
my $edit_form_path = $t->uri->path;
$t = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as Shop Admin + CMS Template Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Shop Admin' ) && $c->user->has_role( 'CMS Template Admin' ),
	'Logged in as Shop Admin + CMS Template Admin'
);
$t->get_ok(
	$edit_form_path,
	'Return to edit item page as Template Admin'
);

# Edit item again, as Template Admin, to go through product-type code
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		tags   => 'test, tags, sort order, tests, so much testing',
		hidden => 'on',
	}},
	'And submit shop edit form again, to change the tags once more'
);
$t->content_contains(
	'so much testing, sort order, tags, test, tests',
	'Tags are stored alphabetically'
);

# Add element to item
$t->submit_form_ok({
	form_id => 'add_element',
	fields => {
		new_element => 'test_item_element',
		new_type	=> 'Long Text'
	}},
	'Submitted form to add new element to item'
);
$t->text_contains(
	'Element added',
	'Verified that new element was added'
);

# Add a second shop item
$t->follow_link_ok(
	{ text => 'Add shop item' },
	'Click on link to add a second new item to the shop'
);
$t->submit_form_ok({
	form_id => 'add_item',
	fields => {
		name           => 'Second Test Item',
		code           => '',
		tags           => '',
		price          => '',
		hidden         => 'on',
		allow_comments => undef,
		product_type   => $product_type1_id,
		categories     => [ $category1_id, 1 ],
		categories     => [ $category2_id, 2 ],
	}},
	'Submitted form to add second new item'
);
my @item2_inputs1 = $t->grep_inputs({ name => qr{^code$} });
ok(
	$item2_inputs1[0]->value eq 'second-test-item',
	'Verified that second new item was successfully created'
);
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		tags           => 'more tags, more tests',
		hidden         => undef,
		price          => '1.00',
		allow_comments => 'on',
		product_type   => $product_type2_id,
	}},
	'Submitted edit item form to enable comments, and try to change product type'
);
$t->submit_form_ok({
	form_id => 'edit_item',
	fields => {
		tags           => '',
		hidden         => undef,
		allow_comments => 'on',
	}},
	'Submitted edit item form a final time to wipe tags'
);
$t->uri->path =~ m{/admin/shop/item/(\d+)/edit};
my $item2_id = $1;

# Try to edit non-existent item
$t->get_ok(
	'/admin/shop/item/999/edit',
	'Try to edit non-existent item'
);
$t->title_is(
	'List Shop Items - ShinyCMS',
	'Got redirected to the list of shop items instead'
);
$t->text_contains(
	'Item not found: 999',
	'Got a semi-helpful error message about the non-existent item'
);

# Preview
$t->post_ok(
	'/shop/item/green-ambi-widget/preview',
	{
		name => 'Test Item',
		code => 'test-item',
		categories => $category1_id,
		product_type => $product_type1_id,
	},
	'Preview a shop item'
);
$t->title_is(
	'Test Item - ShinySite',
	'Previewed a shop item with name overridden'
);


# Create an order, directly in db rather than using demo site
my $shopper = create_test_user( 'test_shopper' );
my $order = $shopper->orders->create({
	email            => $shopper->email,
	billing_address  => '1a Test Street',
	billing_town     => 'Test Town',
	billing_country  => 'Testland',
	billing_postcode => 'A1 1AA',
});
my $order_item = $order->order_items->create({
	item     => $item1_id,
	quantity => '1',
});
my $order_item_id = $order_item->id;

# View the list of orders
$t->get_ok(
	'/admin/shop',
	'Return to shop admin area'
);
$t->follow_link_ok(
	{ text => 'List orders' },
	'Try to view the list of orders'
);
$t->title_is(
	'Shop Orders - ShinyCMS',
	'Loaded list of orders'
);

# Edit an order
$t->follow_link_ok(
	{ text => 'Edit' },
	'Click link to edit an order'
);
$t->submit_form_ok({
	form_id => 'edit_order',
	fields => {
		status => 'Awaiting payment',
		"quantity_$order_item_id" => '42',
		"postage_$order_item_id"  => '1.23',
	}},
	'Submit form to edit order, changing order status and quantity of first item'
);
$t->content_contains(
	'selected="selected">Awaiting payment</option>',
	'Verified that order status was changed'
);
$t->content_contains(
	'<input name="quantity_'.$order_item_id.'" value="42"',
	'Verified that item quantity was changed'
);

# Delete an item
$t->submit_form_ok({
	form_id => 'edit_order',
	fields => {
		"quantity_$order_item_id" => '0',
		"postage_$order_item_id"  => undef,
	}},
	'Submit form to edit order, deleting first item'
);

# TODO

# Try to edit a non-existent order
$t->get_ok(
	'/admin/shop/order/999',
	'Try to edit a non-existent order'
);
$t->title_is(
	'Shop Orders - ShinyCMS',
	'Redirected to list of orders instead'
);
$t->text_contains(
	'Specified order not found - please select from the orders below',
	'Got helpful error message about non-existent order'
);

# Cancel an order (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/shop/order/'.$order->id.'/save',
	{
		cancel => 'Cancel Order'
	},
	'Submitted request to cancel order'
);
$t->title_is(
	'Shop Orders - ShinyCMS',
	'Redirected to list of shop orders'
);
$t->text_contains(
	'Cancelled',
	'Verified that order was cancelled'
);

# Delete order (via db as there's no way to delete orders via site)
$order->order_items->delete;
$order->delete;


# Delete shop items (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/shop/item/'.$item1_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete item'
);
$t->title_is(
	'List Shop Items - ShinyCMS',
	'Redirected to list of shop items'
);
$t->content_lacks(
	'Updated Test Item',
	'Verified that item was deleted'
);
$t->post_ok(
	'/admin/shop/item/'.$item2_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete second item'
);
$t->content_lacks(
	'Second Test Item',
	'Verified that second item was deleted'
);

# Delete element from product type
$t->get_ok(
	'/admin/shop/product-type/'.$product_type1_id.'/edit',
	'Loaded product type edit page'
);
$t->follow_link_ok(
	{ text => 'Delete' },
	'Click button link to delete element from product type'
);

# Delete product types
$t->post_ok(
	'/admin/shop/product-type/'.$product_type1_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete product type'
);
$t->post_ok(
	'/admin/shop/product-type/'.$product_type2_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete product type'
);
$t->title_is(
	'Product Types - ShinyCMS',
	'Redirected to list of product types'
);
$t->content_lacks(
	'Updated Test Type',
	'Verified that product type was deleted'
);
$t->content_lacks(
	'Second Test Type',
	'Verified that second product type was deleted'
);

# Delete categories
$t->post_ok(
	'/admin/shop/category/'.$category2_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete second category (child)'
);
$t->post_ok(
	'/admin/shop/category/'.$category1_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete first category (parent)'
);
$t->title_is(
	'Shop Categories - ShinyCMS',
	'Redirected to list of categories'
);
$t->content_lacks(
	'Updated Test Category',
	'Verified that first category was deleted'
);
$t->content_lacks(
	'Second Test Category',
	'Verified that second category was deleted'
);

# Try to get template filenames when template directory is missing
my $template_dir = $c->path_to( 'root/shop/product-type-templates' );
system( "mv $template_dir $template_dir.test" );
try {
	ShinyCMS::Controller::Admin::Shop->get_template_filenames( $c );
}
catch {
	ok(
		m{Failed to open template directory},
		'Caught die() for get_template_filenames() when template directory is missing.'
	);
};
system( "mv $template_dir.test $template_dir" );


# Log out, then try to access admin area for shop again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of shop admin account'
);
$t->get_ok(
	'/admin/shop',
	'Try to access admin area for shop after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_shop_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/shop',
	'Try to access shop admin area'
);
$t->title_unlike(
	qr{^.*Shop.* - ShinyCMS$},
	'Poll Admin cannot view shop admin area'
);


# Tidy up user accounts
remove_test_admin( $template_admin );
remove_test_admin( $admin          );
remove_test_user(  $shopper        );
remove_test_admin( $poll_admin     );

done_testing();
