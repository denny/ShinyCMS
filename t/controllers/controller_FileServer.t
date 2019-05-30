use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/fileserver',
    'Fetch /fileserver with no params'
);
$t->title_is(
    'Home - ShinySite',
    '/filesever with no params redirects to homepage'
);
# Attempt to fetch a restricted file without logging in first
$t->get( '/fileserver/auth/Group1/dir-one/empty-file.txt' );
ok(
    $t->status == 403,
    'User is forbidden to access restricted files without logging in first'
);
# Log in as a user from demo data, with permission to view restricted files
$t = login_test_user( 'viewer', 'changeme' );
ok(
    $t,
    'Logged in as user with restricted file access'
);
# Attempt to fetch the file again
$t->get( '/fileserver/auth/Group1/dir-one/empty-file.txt' );
ok(
    $t->status == 200,
    'User is allowed to access restricted files after logging in'
);
# Attempt to fetch a restricted file from another access group
$t->get( '/fileserver/auth/Group2/dir-two/also-empty.txt' );
ok(
    $t->status == 403,
    'User is forbidden to access restricted files from other access groups'
);

done_testing();
