# ===================================================================
# File:		t/controller_Admin-Users.t
# Project:	ShinyCMS
# Purpose:	Tests for user admin features
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
use Test::WWW::Mechanize::Catalyst;

use lib 't';
require 'login_helpers.pl';  ## no critic

my $test_admin_details = create_test_admin();

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Fetch a page from the admin area
$t->get_ok(
	'/admin',
	'Try to fetch page in admin area'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Admin area requires login'
);
# Submit admin login form
$t->submit_form_ok({
	form_id => 'login',
    fields => {
		username => $test_admin_details->{ username },
    	password => $test_admin_details->{ password },
	}},
	'Submit login form'
);
# Fetch admin user list page
$t->get_ok( 'http://localhost/admin/users' );
$t->title_is(
	'List Users - ShinyCMS',
	'Reached user list'
);

# TODO: test rest of user adminm features

remove_test_admin();

done_testing();
