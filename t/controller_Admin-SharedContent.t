use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/shared/edit',
    'Fetch shared content in admin area'
);
$t->title_is(
	'Edit Shared Content - ShinyCMS',
	'Reached admin page for shared content'
);

done_testing();
