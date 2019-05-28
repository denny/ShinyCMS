use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/tag',
    'Fetch list of tags'
);
$t->title_is(
    'Tag List - ShinySite',
    'Loaded list of tags'
);

done_testing();
