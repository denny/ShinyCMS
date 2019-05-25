use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

# Add a new form handler
$t->get_ok(
    '/admin',
    'Fetch admin area'
);
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
    'Submitted form to create new form handler'
);
my @inputs2 = $t->grep_inputs({ name => qr/name$/ });
ok(
    $inputs2[0]->value eq 'Updated form handler!',
    'Verified that form handler was updated'
);
# TODO: Delete form Handler (won't work without js confirmation)
$t->submit_form_ok({
    form_id => 'edit_form',
    fields => {
        delete => 'Delete'
    }},
    'Submitted form to delete form handler'
);
# View list of form handlers
$t->get( '/admin/form' ); # TODO: get rid of this once the deletion is working
$t->title_is(
	'Form Handlers - ShinyCMS',
	'Redirected to list of form handlers'
);
#$t->content_lacks(
#    'Updated form handler!',
#    'Verified that form handler was deleted'
#);

remove_test_admin();

done_testing();
