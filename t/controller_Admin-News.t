use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/news',
    'Fetch list of news items in admin area'
);
$t->title_is(
	'List News Items - ShinyCMS',
	'Reached list of news items'
);

remove_test_admin();

done_testing();
