use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/shop',
    'Fetch list of shop items in admin area'
);
$t->title_is(
	'List Shop Items - ShinyCMS',
	'Reached list of shop items'
);

done_testing();
