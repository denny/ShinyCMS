use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Admin::User' }

ok( request('/admin/user')->is_success, 'Request should succeed' );
done_testing();
