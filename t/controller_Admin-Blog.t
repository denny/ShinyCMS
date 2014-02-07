use strict;
use warnings;
use Test::More;


use Catalyst::Test 'ShinyCMS';
use ShinyCMS::Controller::Admin::Blog;

ok( request('/admin/blog')->is_success, 'Request should succeed' );
done_testing();
