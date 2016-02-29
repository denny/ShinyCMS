use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Admin::Shop' }

ok( request('/admin/shop')->is_success, 'Request should succeed' );

done_testing();

