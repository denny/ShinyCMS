use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::PaymentHandler::PhysicalGoods::CCBill;

ok( request('/paymenthandler/physicalgoods/ccbill')->is_success, 'Request should succeed' );
done_testing();
