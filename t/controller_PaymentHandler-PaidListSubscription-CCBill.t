use strict;
use warnings;
use Test::More;

use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::PaymentHandler::PaidListSubscription::CCBill;

ok( request('/paymenthandler/paidlistsubscription/ccbill')->is_redirect, 'Redirect should succeed' );

done_testing();

