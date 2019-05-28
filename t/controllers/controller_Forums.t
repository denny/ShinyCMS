use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
    '/forums',
    'Fetch list of forums'
);
$t->title_is(
    'Forums - ShinySite',
    'Loaded list of forums'
);
$t->follow_link_ok(
    { text => 'Laptops' },
    'Follow link to view a single forum and its posts/threads'
);
$t->title_is(
	'Laptops - Hardware - Forums - ShinySite',
	'Reached laptops forum'
);

done_testing();
