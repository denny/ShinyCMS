use strict;
use warnings;

use Test::More;

use lib 't';
require 'admin_login.pl';

my $t = admin_login() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/blog',
    'Fetch list of posts in blog admin area'
);
$t->title_is(
	'Blog Posts - ShinyCMS',
	'Reached list of blog posts'
);

done_testing();
