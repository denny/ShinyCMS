use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Fetch site homepage a few different ways, to test default section/page code
$t->get_ok(
    '/',
    'Fetch /'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded default CMS page (via Root.pm index action)'
);
$t->get_ok(
    '/pages',
    'Fetch /pages'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded default CMS page again (specified controller but not section or page)'
);
$t->get_ok(
    '/pages/home',
    'Fetch /pages/home'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded default CMS page again (specified controller and section but not page)'
);
$t->get_ok(
    '/pages/home/home',
    'Fetch /pages/home/home'
);
$t->title_is(
    'Home - ShinySite',
    'Loaded default CMS page again (specified controller, section, and page)'
);
# Load a different CMS page in a different section
$t->follow_link_ok(
    { text => 'About ShinyCMS' },
    "Follow link to 'about' page"
);
$t->title_is(
    'About ShinyCMS - ShinySite',
    'Loaded about page'
);
# Test a form handler
$t->follow_link_ok(
    { text => 'Contact Us' },
    'Follow link to page with contact form'
);
$t->title_is(
    'Contact Us - ShinySite',
    'Loaded contact page'
);



done_testing();
