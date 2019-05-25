use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/form',
    'Fetch list of forms in admin area'
);
$t->title_is(
	'Form Handlers - ShinyCMS',
	'Reached list of forms'
);

remove_test_admin();

done_testing();
