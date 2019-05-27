use strict;
use warnings;
use Test::More;

use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::PaymentHandler::AccessSubscription::CCBill;

ok( request('/paymenthandler/accesssubscription/ccbill')->is_redirect, 'Redirect should succeed' );

done_testing();

