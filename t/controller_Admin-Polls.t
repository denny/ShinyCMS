use strict;
use warnings;

use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Admin::Polls;

ok( request('/admin/polls')->is_success, 'Request should succeed' );
done_testing();

