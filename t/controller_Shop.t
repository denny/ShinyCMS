use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Shop' }

ok( request('/shop')->is_success, 'Request should succeed' );


