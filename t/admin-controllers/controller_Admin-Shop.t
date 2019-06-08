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


# TODO: add, edit, list, and delete shop categories


# TODO: add, edit, list, and delete shop items


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
