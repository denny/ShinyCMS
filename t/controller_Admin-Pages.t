use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/pages',
    'Fetch list of CMS pages in admin area'
);
$t->title_is(
	'List Pages - ShinyCMS',
	'Reached list of CMS pages'
);

done_testing();
