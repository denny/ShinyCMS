use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/events',
    'Fetch list of events in admin area'
);
$t->title_is(
	'List Events - ShinyCMS',
	'Reached list of events'
);

remove_test_admin();

done_testing();
