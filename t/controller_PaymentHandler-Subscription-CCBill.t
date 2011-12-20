use strict;
use warnings;
use Test::More;

use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::PaymentHandler::Subscription::CCBill;

ok( request('/paymenthandler/subscription/ccbill')->is_redirect, 'Redirect should succeed' );

done_testing();

