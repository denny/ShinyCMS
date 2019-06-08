use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Shop::Checkout;

ok( request('/shop/checkout')->is_redirect, 'Redirect should succeed' );
done_testing();
