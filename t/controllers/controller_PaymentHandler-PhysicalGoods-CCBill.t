use strict;
use warnings;

use Test::More;
use Catalyst::Test 'ShinyCMS';

use ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill;

ok(
    request('/payment-handler/physical-goods/ccbill')->is_redirect,
    'Redirect should succeed'
);

done_testing();
