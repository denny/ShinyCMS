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
my @inputs2 = $t->grep_inputs({ name => qr/question/ });
ok(
    $inputs2[0]->value eq 'Poll question goes where?',
    'Found updated poll question text'
);



remove_test_admin();

done_testing();
