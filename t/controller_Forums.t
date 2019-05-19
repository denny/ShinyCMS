use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/forums',
    'Fetch list of forums'
);
$t->title_is(
    'Forums - ShinySite',
    'Loaded list of forums'
);

done_testing();
