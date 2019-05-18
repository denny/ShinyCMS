use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'ShinyCMS::Model::DB' }
BEGIN { use_ok 'ShinyCMS::Schema'    }

my $connect_info = ShinyCMS::Model::DB->config->{ connect_info };
my $schema = ShinyCMS::Schema->connect(	$connect_info );

my @sources = $schema->sources();
ok( scalar @sources > 0, 'Found schema sources:  ' . join( ', ', @sources ) );

done_testing();
