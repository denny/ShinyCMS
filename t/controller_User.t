use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_user();

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Try to fetch /user while not logged in
$t->get_ok(
    '/user',
    'Try to fetch /user while not logged in'
);
$t->title_is(
    'Home - ShinySite',
    '/user redirects to homepage if not logged in'
);

# Fetch login page, follow link to register, register an account
$t->get_ok(
    '/user/login',
    'Fetch user login page'
);
$t->title_is(
    'Log In - ShinySite',
    'Reached user login page'
);
$t->follow_link_ok(
    { text => 'register a new account' },
    'Click on register link'
);
$t->title_is(
    'Register - ShinySite',
    'Reached user registration page'
);

# ...

$t->get_ok(
    '/user/login',
    'Fetch user login page'
);
$t->title_is(
    'Log In - ShinySite',
    'Reached user login page'
);
$t->submit_form_ok({
    form_id => 'login',
    fields => {
        #username => $test_admin_details->{ username },
        #password => $test_admin_details->{ password }
        username => 'test_user',
        password => 'test user password'
    }},
    'Submitted login form'
);
my $link = $t->find_link( text => 'logout' );
ok( $link, 'Login successful' );
# Try to fetch /user again, after logging in
$t->get_ok(
    '/user',
    'Try to fetch /user while logged in'
);
$t->title_is(
    'test_user - ShinySite',
    "/user redirects to the user's own profile page if they are logged in"
);

remove_test_user();

done_testing();
