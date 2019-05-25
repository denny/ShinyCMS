use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::Catalyst;

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Fetch a page from the admin area
$t->get_ok(
	'/admin',
	'Try to fetch page in admin area'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Admin area requires login'
);

# Submit admin login form
$t->submit_form_ok({
	form_id => 'login',
    fields => {
		#username => $test_admin_details->{ username },	# TODO
    	#password => $test_admin_details->{ password },	# TODO
		username => 'test_admin',
    	password => 'test admin password',
	}},
	'Submit login form'
);

# Fetch admin user list page
$t->get_ok(
	'/admin/users',
	'Fetch user list in admin area'
);
$t->title_is(
	'List Users - ShinyCMS',
	'Reached user list'
);

remove_test_admin();

done_testing();
