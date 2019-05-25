use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

# Get list of shared content items
$t->get_ok(
    '/admin/shared/edit',
    'Fetch shared content in admin area'
);
$t->title_is(
	'Edit Shared Content - ShinyCMS',
	'Reached admin page for shared content'
);
# TODO: Update a shared content item
# TODO: Delete a shared content item

remove_test_admin();

done_testing();
