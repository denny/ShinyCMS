use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/events',
    'Fetch list of events'
);
$t->title_is(
    'Events - ShinySite',
    'Loaded list of events'
);

done_testing();
