use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/forums',
    'Fetch list of forums in admin area'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of forums'
);

remove_test_admin();

done_testing();
