# ===================================================================
# File:		t/controller_Admin-SharedContent.t
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

use lib 't';
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
        new_element => 'new_shared_item'
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
my @inputs2 = $t->grep_inputs({ name => qr/^content_\d+$/ });
my $input2 = pop @inputs2;
ok(
    $input2->value eq 'This is shared content.',
    'Successfully updated shared content item'
);
# TODO: Delete a shared content item (feature doesn't exist yet)
# Reload the shared content admin area to give the index() method some exercise
$t->get_ok(
    '/admin/shared',
    'Fetch shared content admin area one last time'
);
$t->title_is(
	'Shared Content - ShinyCMS',
	'Reloaded shared content admin area via index method (yay, test coverage)'
);

remove_test_admin();

done_testing();
