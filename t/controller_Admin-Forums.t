use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Admin::Forums' }

ok( request('/admin/forums')->is_success, 'Request should succeed' );
done_testing();
