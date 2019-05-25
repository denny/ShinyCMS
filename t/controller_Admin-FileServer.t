use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin',
    'Fetch admin area'
);
# Get a list of all files which have access log data
$t->follow_link_ok(
    { text => 'Fileserver logs' },
    'Follow link to view access logs for all files'
);
$t->title_is(
	'Access logs for all files - ShinyCMS',
	'Reached list of files'
);
# View access logs for specific file
$t->follow_link_ok(
    { text => 'Access Logs' },
    'Follow link to view access logs for first file listed'
);
$t->title_is(
	'Access logs for: catalyst_logo.png - ShinyCMS',
	'Reached access logs for specific file'
);
$t->text_contains(
	'10.20.30.40',
	'Found expected IP address'
);
# Get list of files in specified path which have access data
$t->get_ok(
    '/admin/fileserver/access-logs/testdir',
    "Fetch list of restricted files in 'testdir' directory"
);
$t->title_is(
	'Access logs for: testdir - ShinyCMS',
	'Reached list of files in specific directory'
);

remove_test_admin();

done_testing();
