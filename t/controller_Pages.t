use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/pages',
    'Fetch default CMS page'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded default CMS page'
);

done_testing();
