use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/dashboard',
    'Fetch admin dashboard'
);
$t->title_is(
	'Site Stats - ShinyCMS',
	'Reached admin dashboard'
);

done_testing();
