use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Reactant' }
BEGIN { use_ok 'Reactant::Controller::User' }

ok( request('/user')->is_success, 'Request should succeed' );


