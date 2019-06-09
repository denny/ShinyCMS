# ===================================================================
# File:		t/meta/10_helpers.t
# Project:	ShinyCMS
# Purpose:	Tests for the database and config helper methods for tests
#
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'helpers.pl';  ## no critic

# We call these twice here to test the early return at the start of each method

my $on_off = $ENV{ SHINYCMS_TEST };  # Save state of test mode
$ENV{ SHINYCMS_TEST } = undef;  # not in test mode
my $config = get_config();
$ENV{ SHINYCMS_TEST } = 1;  # in test mode
$config = get_config();
$ENV{ SHINYCMS_TEST } = $on_off;  # Restore previous state of test mode
ok(
    ref $config eq 'HASH' && $config->{ name } eq 'ShinyCMS',
    'Got a ShinyCMS config hashref'
);

my $schema = get_schema();
$schema = get_schema();
ok(
    ref $schema eq 'ShinyCMS::Schema',
    'Got a ShinyCMS::Schema object'
);

done_testing();
