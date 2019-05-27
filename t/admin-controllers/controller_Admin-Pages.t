use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/pages',
    'Fetch list of CMS pages in admin area'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Reached list of CMS pages'
);

remove_test_admin();

done_testing();
