# ===================================================================
# File:		t/schema-results/User.t
# Project:	ShinyCMS
# Purpose:	Tests for user model
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
require 'login_helpers.pl';  ## no critic

# Get a schema object
my $schema = get_schema();

# Create a test user
my $user = create_test_user( 'test_user_model' );

# Test for access
ok(
	not ( defined $user->access_expires( 'Test' ) ),
	"User does not have 'Test' access"
);

# Give the test user some access
my $eternal_access = $schema->resultset( 'Access' )->search({
	access => 'Eternal'
})->single;
$user->user_accesses->find_or_create({ access => $eternal_access->id });
my $current_access = $schema->resultset( 'Access' )->search({
	access => 'Unexpired'
})->single;
$user->user_accesses->find_or_create({ access => $current_access->id });
# Test again
ok(
	$user->access_expires( 'Eternal' ),
	"User has 'Eternal' access"
);
ok(
	$user->access_expires( 'Unexpired' ),
	"User has 'Unexpired' access"
);

done_testing();
