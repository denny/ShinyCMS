use strict;
use warnings;

use Test::More;
use Catalyst::Test 'ShinyCMS';

use ShinyCMS::Controller::PaymentHandler::AccessSubscription::CCBill;

ok(
    request('/payment-handler/access-subscription/ccbill')->is_redirect,
    'Redirect should succeed'
);

done_testing();
