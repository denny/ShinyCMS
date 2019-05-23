use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/fileserver',
    'Fetch list of restricted files'
);
$t->title_is(
	'File Access Logs - ShinyCMS',
	'Reached list of files'
);
$t->follow_link_ok(
    { text => 'Access Logs' },
    'Follow link to view access logs for first file listed'
);
$t->title_is(
	'Access logs for: catalyst_logo.png - ShinyCMS',
	'Reached access logs for specific file'
);



remove_test_admin();

done_testing();
