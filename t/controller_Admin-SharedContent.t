use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/shared/edit',
    'Fetch shared content in admin area'
);
$t->title_is(
	'Edit Shared Content - ShinyCMS',
	'Reached admin page for shared content'
);

remove_test_admin();

done_testing();
