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
# Upload a new file
$t->follow_link_ok(
    { text => 'Upload file' },
    'Follow link to file upload page'
);
$t->title_is(
	'Upload a file - ShinyCMS',
	'Reached file upload page'
);

# View list of CMS-uploaded files
$t->follow_link_ok(
    { text => 'View files' },
    'View list of CMS-uploaded files in admin area'
);
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of files'
);
# TODO ... ?

remove_test_admin();

done_testing();
