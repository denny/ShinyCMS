use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/polls',
    'Fetch list of polls in admin area'
);
$t->title_is(
	'List Polls - ShinyCMS',
	'Reached list of polls'
);
$t->follow_link_ok(
    { text => 'Edit' },
    'Click to Edit first poll'
);
$t->title_is(
    "Edit Poll - ShinyCMS",
    'Reached poll edit page'
);
my @inputs = $t->grep_inputs({
    type => 'text',
    name => 'question'
});
ok(
    $inputs[0]->value eq 'Poll goes where?',
    'Found expected poll question'
);

=begin # TODO: Save feature not implemented!!
$t->submit_form_ok({
    form_id => 'edit_poll',
    fields => {
        question => 'Poll goes where??',
        answer_1 => 'Here and there.',
        answer_2 => 'Everywhere!'
    }},
    'Submitted form to save edited poll'
);
my @edited_question_input = $t->grep_inputs({
    type => 'text',
    name => 'question'
});
ok(
    $edited_question_input[0]->value eq 'Poll goes where??',
    'Found updated poll question'
);
my @edited_answer2_input = $t->grep_inputs({
    type => 'text',
    name => 'answer_2'
});
ok(
    $edited_answer2_input[0]->value eq 'Everywhere!',
    'Found updated poll answer'
);
=end
=cut

remove_test_admin();

done_testing();
