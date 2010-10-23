use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'ShinyCMS' }
BEGIN { use_ok 'ShinyCMS::Controller::Pages' }

use ShinyCMS;
use ShinyCMS::Schema;

use Data::Dumper;
use HTTP::Request::Common;


my $schema = ShinyCMS::Schema->connect(	
	ShinyCMS->config->{ 'Model::DB' }->{ connect_info }
);


my $user = $schema->resultset( 'User' )->create({
	username => 'testadmin2',
	password => 'goldenfleece',
	email    => 'nonsuch@example.com'
});

$user->user_roles->create({ role => 1 });
$user->user_roles->create({ role => 3 });
$user->user_roles->create({ role => 4 });


my $response = request POST '/user/login', [
	username => 'testadmin2',
	password => 'goldenfleece',
	login    => 'Log In',
];


#$response = request('/pages/list');
#warn $response->content;


$user->user_roles->delete;
$user->delete;

ok(1);

done_testing();

