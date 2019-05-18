use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/polls',
    'Fetch list of polls in admin area'
);
$t->title_is(
	'List Polls - ShinyCMS',
	'Reached list of polls'
);

done_testing();
