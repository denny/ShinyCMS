use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

# Log in as a Forums Admin
my $admin = create_test_admin( 'forums_test_admin', 'Forums Admin' );

my $t = login_test_admin( $admin->username, $admin->username )
    or die 'Failed to log in as Forums Admin';

my $c = $t->ctx;
ok(
    $c->user->has_role( 'Forums Admin' ),
    'Logged in as Forums Admin'
);

# Try to access the admin area for forums
$t->get_ok(
    '/admin/forums',
    'Fetch list of forums in admin area'
);
$t->title_is(
	'List Forums - ShinyCMS',
	'Reached list of forums'
);

remove_test_admin( $admin );

done_testing();
