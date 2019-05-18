use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/events',
    'Fetch list of events in admin area'
);
$t->title_is(
	'List Events - ShinyCMS',
	'Reached list of events'
);

done_testing();
