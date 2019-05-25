use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/filemanager',
    'Fetch list of CMS-uploaded files in admin area'
);
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of files'
);

remove_test_admin();

done_testing();
