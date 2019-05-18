use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/news',
    'Fetch list of news items in admin area'
);
$t->title_is(
	'List News Items - ShinyCMS',
	'Reached list of news items'
);

done_testing();
