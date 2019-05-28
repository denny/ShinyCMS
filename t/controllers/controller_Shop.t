use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/shop',
    'Fetch shop homepage'
);
$t->title_is(
    'Shop Categories - ShinySite',
    'Loaded shop homepage'
);

done_testing();
