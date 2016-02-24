use strict;
use warnings;
use Test::More;

eval { require Test::Perl::Critic::Progressive };
plan skip_all => 'T::P::C::Progressive required for this test' if $@;

Test::Perl::Critic::Progressive::progressive_critic_ok();


