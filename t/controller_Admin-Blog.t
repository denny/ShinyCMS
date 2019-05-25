use strict;
use warnings;

use Test::More;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/blog',
    'Fetch list of posts in blog admin area'
);
$t->title_is(
	'Blog Posts - ShinyCMS',
	'Reached list of blog posts'
);

remove_test_admin();

done_testing();
