use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/form',
    'Fetch list of forms in admin area'
);
$t->title_is(
	'Form Handlers - ShinyCMS',
	'Reached list of forms'
);

done_testing();
