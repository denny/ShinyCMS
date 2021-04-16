# ===================================================================
# File:		t/admin-controllers/controller_Admin-Dashboard.t
# Project:	ShinyCMS
# Purpose:	Tests for admin dashboard
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

my $admin = create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->follow_link_ok(
    { text => 'Dashboard' },
    'Click link to view admin dashboard'
);
$t->title_is(
    'Site Stats - ShinyCMS',
    'Reached dashboard, showing stats for this week'
);
$t->follow_link_ok(
    { text_regex => qr{ Previous week$} },
    "Click 'previous week' link"
);
$t->title_like(
	qr{^Site Stats \(w/c \d\d? \w\w\w \d\d\d\d\) - ShinyCMS$},
	'Loaded dashboard with stats for previous week'
);
my $url_with_date = $t->uri;
$t->follow_link_ok(
    { text_regex => qr{^Next week } },
    "Click 'next week' link"
);
$t->title_is(
    'Site Stats - ShinyCMS',
    'Loaded dashboard, showing stats for the current week'
);
$t->follow_link_ok(
    { text_regex => qr{ Previous week$} },
    'Click link for previous week again'
);
$t->follow_link_ok(
    { text_regex => qr{^Current } },
    "Click 'current' link"
);
$t->title_is(
    'Site Stats - ShinyCMS',
    'Loaded dashboard, showing stats for the current week'
);
my $url_with_malformed_date = substr( $url_with_date, 0, -2 );
$t->get_ok(
    $url_with_malformed_date,
    'Attempt to fetch page with malformed date in query string'
);
$t->title_is(
    'Site Stats - ShinyCMS',
    'Shows stats for the current week'
);

# Log out, then try to access admin area for events again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of event admin account'
);
$t->get_ok(
	'/admin/events',
	'Try to access admin area for events after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_dashboard_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/dashboard',
	'Attempt to fetch dashboard without the Dashboard Admin role'
);
$t->title_unlike(
	qr{^.*Site Stats.* - ShinyCMS$},
	'Failed to view admin dashboard without the appropriate role enabled'
);


# Tidy up user accounts
remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
