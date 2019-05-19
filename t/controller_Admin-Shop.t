use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/shop',
    'Fetch list of shop items in admin area'
);
$t->title_is(
	'List Shop Items - ShinyCMS',
	'Reached list of shop items'
);

remove_test_admin();

done_testing();
