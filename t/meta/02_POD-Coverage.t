use strict;
use warnings;

use Test::More;

plan skip_all => 'Set TEST_POD to enable this test' unless $ENV{TEST_POD};

eval { use Test::Pod::Coverage };
plan skip_all => 'Test::Pod::Coverage required' if $@;

all_pod_coverage_ok();

done_testing();
