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
$t->submit_form_ok({
    form_id => 'upload_file',
    fields => {
        upload => 'README.md'
    }},
    'Submitted file upload form'
);
# View list of CMS-uploaded files
$t->title_is(
	'File Manager - ShinyCMS',
	'Reached list of CMS-uploaded files in admin area'
);
$t->content_contains(
    'README.md',
    'Verified that file was uploaded'
);
# TODO: Delete a CMS-uploaded file (feature not implemented yet!)

remove_test_admin();

done_testing();
