# ===================================================================
# File:		t/controller_Admin-News.t
# Project:	ShinyCMS
# Purpose:	Tests for news admin features
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

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin',
    'Fetch admin area'
);
# Add a news item
$t->follow_link_ok(
    { text => 'Add news item' },
    'Follow link to add a news item'
);
$t->title_is(
	'Add News Item - ShinyCMS',
	'Reached page for adding news item'
);
$t->submit_form_ok({
    form_id => 'add_item',
    fields => {
        title => 'This is some test news'
    }},
    'Submitted form to create news item'
);
$t->title_is(
	'Edit News Item - ShinyCMS',
	'Redirected to edit page for newly created news item'
);
my @inputs1 = $t->grep_inputs({ name => qr/url_title$/ });
ok(
    $inputs1[0]->value eq 'this-is-some-test-news',
    'Verified that news item was created'
);
# Update news item
$t->submit_form_ok({
    form_id => 'edit_item',
    fields => {
        title => 'News item updated by test suite'
    }},
    'Submitted form to update news item'
);
my @inputs2 = $t->grep_inputs({ name => qr/title$/ });
ok(
    $inputs2[0]->value eq 'News item updated by test suite',
    'Verified that form handler was updated'
);
# Delete news item (can't use submit_form_ok due to javascript confirmation)
my @inputs3 = $t->grep_inputs({ name => qr/^item_id$/ });
my $id = $inputs3[0]->value;
$t->post_ok(
    '/admin/news/edit-do/'.$id,
    {
        item_id => $id,
        delete  => 'Delete'
    }
);
# View list of news items
$t->title_is(
    'List News Items - ShinyCMS',
    'Reached list of news items'
);
$t->content_lacks(
    'News item updated by test suite',
    'Verified that news item was deleted'
);

remove_test_admin();

done_testing();
