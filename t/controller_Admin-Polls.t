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

remove_test_admin();

done_testing();
