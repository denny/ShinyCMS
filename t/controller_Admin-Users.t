use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Get admin login page
$t->get_ok( 'http://localhost/admin' );
$t->title_is(
	'Log In - ShinyCMS',
	'Admin area requires login'
);

# Submit admin login form
$t->submit_form_ok({
	form_id => 'login',
    fields => {
		username => 'admin',
    	password => 'changeme'
	}},
	'Submit login form'
);

# Fetch admin user list page
$t->get_ok( 'http://localhost/admin/users' );
$t->title_is(
	'List Users - ShinyCMS',
	'Reached user list'
);

done_testing();
