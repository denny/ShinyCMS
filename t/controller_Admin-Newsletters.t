use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/newsletters',
    'Fetch list of newsletters in admin area'
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Reached list of newsletters'
);

done_testing();
