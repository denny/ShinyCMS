use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/filemanager',
    'Fetch list of CMS-uploaded files in admin area'
);
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of files'
);

done_testing();
