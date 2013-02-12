use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Shop::Checkout;

ok( request('/shop/checkout')->is_success, 'Request should succeed' );
done_testing();
