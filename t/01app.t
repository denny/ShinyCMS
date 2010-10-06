use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }

ok( request('/user/login')->is_success, 'Request should succeed' );
done_testing();

