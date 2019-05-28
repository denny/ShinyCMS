use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/polls',
    'Fetch list of polls'
);
$t->title_is(
    'Polls - ShinySite',
    'Loaded list of polls'
);

done_testing();
