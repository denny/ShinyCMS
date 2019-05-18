use strict;
use warnings;

use Test::More;

plan skip_all => 'Set TEST_CRITIC to enable this test' unless $ENV{TEST_CRITIC};

eval 'use Test::Perl::Critic';
plan skip_all => 'Test::Perl::Critic is required for this test' if $@;

all_critic_ok( 'lib' );
