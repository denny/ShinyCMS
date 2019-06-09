use strict;
use warnings;

use Test::More;
use Catalyst::Test 'ShinyCMS';

use ShinyCMS::Controller::PaymentHandler::PaidListSubscription::CCBill;

ok(
	request('/payment-handler/paid-list-subscription/ccbill')->is_redirect,
	'Redirect should succeed'
);

done_testing();
