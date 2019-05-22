use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/fileserver',
    'Fetch list of restricted files'
);
$t->title_is(
	'Fileserver - ShinyCMS',
	'Reached list of files'
);

remove_test_admin();

done_testing();
