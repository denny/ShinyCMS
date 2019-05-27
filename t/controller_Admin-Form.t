# ===================================================================
# File:		t/controller_Admin-Form.t
# Project:	ShinyCMS
# Purpose:	Tests for form handler admin features
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
# Add a new form handler
$t->follow_link_ok(
    { text => 'Add form handler' },
    'Follow link to add a new form handler'
);
$t->title_is(
	'Add Form Handler - ShinyCMS',
	'Reached page for adding new form handler'
);
$t->submit_form_ok({
    form_id => 'edit_form',
    fields => {
        name => 'New Form Handler'
    }},
    'Submitted form to create new form handler'
);
$t->title_is(
	'Edit Form Handler - ShinyCMS',
	'Redirected to edit page for new form handler'
);
my @inputs1 = $t->grep_inputs({ name => qr/url_name$/ });
ok(
    $inputs1[0]->value eq 'new-form-handler',
    'Verified that new form handler was created'
);
# Edit form handler
$t->submit_form_ok({
    form_id => 'edit_form',
    fields => {
        name => 'Updated form handler!'
    }},
    'Submitted form to update form handler'
);
my @inputs2 = $t->grep_inputs({ name => qr/name$/ });
ok(
    $inputs2[0]->value eq 'Updated form handler!',
    'Verified that form handler was updated'
);
# Delete form Handler (can't use submit_form_ok due to javascript confirmation)
my @inputs3 = $t->grep_inputs({ name => qr/^form_id$/ });
my $id = $inputs3[0]->value;
$t->post_ok(
    '/admin/form/edit-form-do',
    {
        form_id => $id,
        delete  => 'Delete'
    },
    'Submitted request to delete form handler'
);
# View list of form handlers
$t->title_is(
	'Form Handlers - ShinyCMS',
	'Redirected to list of form handlers'
);
$t->content_lacks(
    'Updated form handler!',
    'Verified that form handler was deleted'
);

remove_test_admin();

done_testing();
