# ===================================================================
# File:		t/admin-controllers/controller_Admin-SharedContent.t
# Project:	ShinyCMS
# Purpose:	Tests for shared content admin features
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

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin',
    'Fetch admin area'
);
# Add a new shared content item
$t->follow_link_ok(
    { text => 'Shared content' },
    'Follow link to admin area for shared content'
);
$t->title_is(
	'Shared Content - ShinyCMS',
	'Reached admin area for shared content'
);
$t->submit_form_ok({
    form_id => 'add_shared_content',
    fields => {
        new_element => 'new_shared_item',
        new_type    => 'Long Text'
    }},
    'Submitted form to create new shared content item'
);
$t->title_is(
	'Shared Content - ShinyCMS',
	'Reloaded admin area for editing shared content'
);
my @inputs1 = $t->grep_inputs({ name => qr/^name_\d+$/ });
my $input1 = pop @inputs1;
ok(
    $input1->value eq 'new_shared_item',
    'Verified that new shared content item was created'
);
# Update a shared content item
$input1->name =~ m/name_(\d+)/;
my $id = $1;
$t->submit_form_ok({
    form_id => 'edit_shared_content',
    fields => {
        "content_$id" => 'This is shared content.'
    }},
    'Submitted form to update shared content item'
);
my @inputs2 = $t->grep_inputs({ name => qr/^content_$id$/ });
ok(
    $inputs2[0]->value eq 'This is shared content.',
    'Successfully updated shared content item'
);
my $long_text_is_long = 'I am long! ' x 6_000;  # 66,000 characters
$t->submit_form_ok({
    form_id => 'edit_shared_content',
    fields => {
        "content_$id" => $long_text_is_long
    }},
    'Attempting to update shared content item again, with VERY long value'
);
$t->text_contains(
    'Long field truncated (over 65,000 characters!)',
    'Found error message warning the user that their text was truncated'
);
# TODO: Delete a shared content item (feature doesn't exist yet)
# Reload the shared content admin area to give the index() method some exercise
$t->get_ok(
    '/admin/shared',
    'Fetch shared content admin area directly at /admin/shared'
);
$t->title_is(
	'Shared Content - ShinyCMS',
	'Loaded shared content admin area via index method (yay, test coverage)'
);
remove_test_admin();

# Switch to a user with limited privs and test that some functionality is blocked
create_test_admin( 'CMS Page Editor', 'Shared Content Editor' );
$t = login_test_admin();
$t->get_ok(
    '/admin/shared',
    'Fetch shared content admin area as Shared Content Editor'
);
$t->submit_form_ok({
    form_id => 'edit_shared_content',
    fields => {
        "content_$id" => 'Shorter is better',
        "name_$id"    => 'renamed_new_shared_content',
        "type_$id"    => 'Short Text'
    }},
    'Attempting to update content name and type without Template Admin privs'
);
my @inputs3 = $t->grep_inputs({ name => qr/^content_$id$/ });
my @inputs4 = $t->grep_inputs({ name => qr/^name_$id$/    });
ok(
    $inputs3[0]->value eq 'Shorter is better',
    "Successfully updated the item's content"
);
ok(
    $inputs4[0]->value eq 'new_shared_item', # unchanged
    "Failed to update the item's name"
);
# Now let's fail to add a new piece of shared content
$t->post_ok(
    '/admin/shared/add-element-do',
    {
        new_element => 'not_a_template_admin',
        new_type    => 'Short Text'
    },
    'Attempting to create new shared content item as a non-admin'
);
$t->text_contains(
    'You do not have the ability to add new shared content.',
    'Failed to add new shared content item'
);
remove_test_admin();

# Now try again with no relevant privs and make sure we're totally shut out
create_test_admin( 'CMS Page Editor' );
$t = login_test_admin();
$t->get_ok(
    '/admin/shared',
    'Fetch shared content admin area as CMS Page Editor'
);
$t->title_unlike(
	qr/Shared Content/,
	'Failed to reach Shared Content area without any appropriate roles enabled'
);
remove_test_admin();

done_testing();
