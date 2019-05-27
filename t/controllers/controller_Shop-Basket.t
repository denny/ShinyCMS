use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Shop::Basket;

ok( request('/shop/basket')->is_success, 'Request should succeed' );
done_testing();
