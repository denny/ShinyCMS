use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Root' }

ok( request('/')->is_redirect, 'Redirect should succeed' );

done_testing();

