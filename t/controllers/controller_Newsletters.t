use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/newsletters',
    'Fetch list of newsletters'
);
$t->title_is(
    'Newsletters - ShinySite',
    'Loaded list of newsletters'
);

done_testing();
