use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Admin::Events;

ok( request('/admin/events')->is_success, 'Request should succeed' );
done_testing();
