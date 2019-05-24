use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

# Get list of polls
$t->get_ok(
    '/admin/polls',
    'Fetch list of polls in admin area'
);
$t->title_is(
	'List Polls - ShinyCMS',
	'Reached list of polls'
);
# Edit a poll
$t->follow_link_ok(
    { text => 'Edit' },
    'Follow link to edit most recent poll'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Reached poll editing page'
);
my @inputs1 = $t->grep_inputs({ name => qr/question/ });
ok(
    $inputs1[0]->value eq 'Poll goes where?',
    'Found expected poll question text'
);
# Update the question
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        question => 'Poll question goes where?'
    }},
    'Submitted form to save poll with altered question text'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Reloaded poll editing page'
);
my @inputs2 = $t->grep_inputs({ name => qr/^question$/ });
ok(
    $inputs2[0]->value eq 'Poll question goes where?',
    'Found updated poll question text'
);
# Add a new answer
$t->submit_form_ok({
    form_id => 'add_answer',
    fields => {
        new_answer => 'I am the answer to all your questions.'
    }},
    'Submitted form to add new answer to poll'
);
my @inputs3 = $t->grep_inputs({ name => qr/^answer_\d+$/ });
ok(
    $inputs3[2]->value eq 'I am the answer to all your questions.',
    'New poll answer was successfully added'
);
# TODO: Alter vote counts (feature doesn't exist yet!)
# TODO: Delete a poll (test fails - presumably because of the js confirm stage)
#$t->submit_form_ok({
#    form_id => 'edit_poll',
#    fields => {
#        delete => 'Delete'
#    }},
#    'Submitted form to delete poll'
#);
#$t->title_is(
#	'List Polls - ShinyCMS',
#	'Returned to list of polls'
#);
#$t->content_contains(
#    'Poll question goes where?',
#    'Poll was deleted'
#);
# Add a new poll
$t->follow_link_ok(
    { text => 'Add poll' },
    'Follow link to add a new poll'
);
$t->title_is(
	'Add Poll - ShinyCMS',
	'Reached page for adding new poll'
);
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        question => 'Can we create new polls?'
    }},
    'Submitted form to create poll'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Reloaded poll editing page'
);
my @inputs5 = $t->grep_inputs({ name => qr/question/ });
ok(
    $inputs5[0]->value eq 'Can we create new polls?',
    'New poll successfully created'
);

remove_test_admin();

done_testing();
