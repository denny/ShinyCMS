use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok( '/blog', 'Get recent blog posts page' );
$t->title_is(
    'Recent posts - ShinySite',
    'Reached recent posts page'
);
$t->follow_link_ok(
    { text => '0 comments' },
    'Click on link to first blog post'
);
$t->title_is(
    'A nondescript white 18-wheeler - ShinySite',
    'Reached first blog post'
);
$t->follow_link_ok(
    { text => 'truck' },
    'Click on truck tag'
);
$t->title_is(
    "Posts tagged 'truck' - ShinySite",
    'Reached list of tagged blog posts'
);
$t->follow_link_ok(
    { text => 'Blog' },
    'Click on menu link for blog'
);
$t->follow_link_ok(
    { text_regex => qr/Older$/ },
    'Click on link to older posts'
);
$t->follow_link_ok(
    { text => '5 comments' },
    'Click on link to third post on this page'
);
$t->title_is(
    'w1n5t0n - ShinySite',
    'Reached blog post'
);
$t->follow_link_ok(
    { text => 'Add a new comment' },
    "Click 'add new comment' link"
);
$t->title_is(
    'Reply to: w1n5t0n - ShinySite',
    'Reached top-level comment page'
);

done_testing();
