use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Admin::Form;

ok( request('/admin/form')->is_success, 'Request should succeed' );

done_testing();

