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

use lib 't/support';
require 'login_helpers.pl';  ## no critic

# Log in as a Shop Admin
my $admin = create_test_admin( 'shop_test_admin', 'Shop Admin' );

my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Shop Admin';

my $c = $t->ctx;
ok(
	$c->user->has_role( 'Shop Admin' ),
	'Logged in as Shop Admin'
);

# Try to access the shop admin area
$t->get_ok(
	'/admin/shop',
	'Try to access shop admin area'
);
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
		name => 'Test Category'
	}},
	'Submitted form to add new shop category'
);
$t->title_is(
	'Edit Category - ShinyCMS',
	'Redirected to category edit page'
);
my @category_inputs1 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$category_inputs1[0]->value eq 'test-category',
	'Verified that new category was successfully created'
);
# Edit category
$t->submit_form_ok({
	form_id => 'edit_category',
	fields => {
		name => 'Updated Test Category',
		url_name => '',
	}},
	'Submitted form to update shop category'
);
my @category_inputs2 = $t->grep_inputs({ name => qr/^url_name$/ });
ok(
	$category_inputs2[0]->value eq 'updated-test-category',
	'Verified that category was successfully updated'
);
$t->uri->path =~ m{/admin/shop/category/(\d+)/edit};
my $category_id = $1;


# TODO: add, edit, list, and delete product types


# TODO: add, edit, list, and delete shop items


# Delete category (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/shop/category/'.$category_id.'/save',
	{
		delete   => 'Delete'
	},
	'Submitted request to delete category'
);
# View list of events
$t->title_is(
	'Shop Categories - ShinyCMS',
	'Reached list of categories'
);
$t->content_lacks(
	'Updated Test Category',
	'Verified that category was deleted'
);
remove_test_admin( $admin );

# Log in as the wrong sort of admin, and make sure we're blocked
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
	qr/Shop.* - ShinyCMS/,
	'Poll Admin cannot view shop admin area'
);
remove_test_admin( $poll_admin );

done_testing();
