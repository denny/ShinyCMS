use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Tag' }

ok( request('/tag')->is_success, 'Request should succeed' );

done_testing();

