use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/newsletters',
    'Fetch list of newsletters in admin area'
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Reached list of newsletters'
);

remove_test_admin();

done_testing();
