use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/',
    'Fetch site homepage'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded homepage (default CMS page+section)'
);

done_testing();
