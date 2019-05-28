use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/fileserver',
    'Fetch /fileserver with no params'
);
$t->title_is(
    'Home - ShinySite',
    '/filesever with no params redirects to homepage'
);

done_testing();
