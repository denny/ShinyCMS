use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok( '/user' );
$t->title_is(
    'Log In - ShinySite',
    'User area requires login to view'
);
$t->follow_link_ok(
    { text => 'register a new account' },
    'Click on register link'
);
$t->title_is(
    'Register - ShinySite',
    'Reached user registration page'
);

done_testing();
