use strict;
use warnings;

use Test::More;

plan skip_all => 'Set TEST_POD to enable this test' unless $ENV{TEST_POD};

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

all_pod_coverage_ok();

done_testing();
