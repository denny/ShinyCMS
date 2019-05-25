# ===================================================================
# File:		t/controller_Admin-Events.t
# Project:	ShinyCMS
# Purpose:	Tests for event admin features
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

use lib 't';
require 'login_helpers.pl';  ## no critic

create_test_admin();

my $t = login_test_admin() or die 'Failed to log in as admin';

$t->get_ok(
    '/admin/events',
    'Fetch list of events in admin area'
);
$t->title_is(
	'List Events - ShinyCMS',
	'Reached list of events'
);

remove_test_admin();

done_testing();
