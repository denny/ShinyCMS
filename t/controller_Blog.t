use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Reactant' }
BEGIN { use_ok 'Reactant::Controller::Blog' }

ok( request('/blog')->is_success, 'Request should succeed' );


