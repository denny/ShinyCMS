# ===================================================================
# File:		t/meta/10_database.t
# Project:	ShinyCMS
# Purpose:	Tests for the database connection lib
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
require 'database.pl';  ## no critic

my $schema = get_schema();
ok(
    ref $schema eq 'ShinyCMS::Schema',
    'Got a ShinyCMS::Schema object'
);

done_testing();
