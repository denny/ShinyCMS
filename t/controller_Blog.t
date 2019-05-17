use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok( '/blog' );
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
    { text => '0 comments', n => 2 },
    'Click on link to second blog post'
);
$t->title_is(
    'Nothing to hide, nothing to fear - ShinySite',
    'Reached blog post'
);
$t->follow_link_ok(
    { text => 'Add a new comment' },
    "Click 'add new comment' link"
);
$t->title_is(
    'Reply to: Nothing to hide, nothing to fear - ShinySite',
    'Reached top-level comment page'
);

done_testing();
