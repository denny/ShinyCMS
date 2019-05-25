use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

# Add a new poll
$t->get_ok(
    '/admin',
    'Fetch admin area'
);
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
	'Loaded poll editing page'
);
my @inputs1 = $t->grep_inputs({ name => qr/^question$/ });
ok(
    $inputs1[0]->value eq 'Can we create new polls?',
    'New poll successfully created'
);
# Update the question
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        question => 'What can we do with polls?'
    }},
    'Submitted form to save poll with altered question text'
);
$t->title_is(
	'Edit Poll - ShinyCMS',
	'Reloaded poll editing page'
);
my @inputs2 = $t->grep_inputs({ name => qr/^question$/ });
ok(
    $inputs2[0]->value eq 'What can we do with polls?',
    'Found updated poll question text'
);
# Add a new answer
$t->submit_form_ok({
    form_id => 'add_answer',
    fields => {
        new_answer => 'We can add answers.'
    }},
    'Submitted form to add new answer to poll'
);
my @inputs3 = $t->grep_inputs({ name => qr/^answer_\d+$/ });
ok(
    $inputs3[0]->value eq 'We can add answers.',
    'New poll answer was successfully added'
);
# TODO: Alter vote counts (feature doesn't exist yet!)
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        answer_1_votes => '100',
    }},
    'Submitted form to save poll with altered votes'
);
my @inputs4 = $t->grep_inputs({ name => qr/^answer_\d+_votes$/ });
#ok(
#    $inputs4[0]->value eq '100',
#    'Vote counts were successfully updated'
#);
# TODO: Delete a poll (test fails - presumably because of the js confirm stage)
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        delete => 'Delete'
    }},
    'Submitted form to delete poll'
);
# View list of polls
$t->get( '/admin/polls' );  # TODO: remove this once deletion is working
$t->title_is(
	'List Polls - ShinyCMS',
	'Viewing list of polls in admin area'
);
#$t->content_lacks(
#    'What can we do with polls?',
#    'Poll was deleted'
#);

remove_test_admin();

done_testing();
