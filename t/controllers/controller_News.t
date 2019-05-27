use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/news',
    'Fetch list of news'
);
$t->title_is(
    'News - ShinySite',
    'Loaded list of news'
);

done_testing();
