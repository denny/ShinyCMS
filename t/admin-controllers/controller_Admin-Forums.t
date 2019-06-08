# ===================================================================
# File:		t/admin-controllers/controller_Admin-Forums.t
# Project:	ShinyCMS
# Purpose:	Tests for forum admin features
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

# Log in as a Forums Admin
my $admin = create_test_admin( 'forums_test_admin', 'Forums Admin' );

my $t = login_test_admin( $admin->username, $admin->username )
    or die 'Failed to log in as Forums Admin';

my $c = $t->ctx;
ok(
    $c->user->has_role( 'Forums Admin' ),
    'Logged in as Forums Admin'
);

# Try to access the admin area for forums
$t->get_ok(
    '/admin/forums',
    'Try to access admin area for forums'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of all forums'
);

# Add a new forum section
$t->follow_link_ok(
    { text => 'Add new section' },
    'Follow link to add a new forum section'
);
$t->title_is(
	'Add Section - ShinyCMS',
	'Reached page for adding new section'
);
$t->submit_form_ok({
    form_id => 'add_section',
    fields => {
        name => 'Test Section',
    }},
    'Submitted form to create new forum section'
);
$t->title_is(
	'Edit Section - ShinyCMS',
	'Redirected to edit page for newly created section'
);
my @section_inputs1 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
    $section_inputs1[0]->value eq 'test-section',
    'Verified that new forum section was created'
);





remove_test_admin( $admin );

done_testing();
