use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Forums' }

ok( request( '/forums' )->is_success, 'Request should succeed' );

done_testing();
