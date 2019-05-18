use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/forums',
    'Fetch list of forums in admin area'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of forums'
);

done_testing();
