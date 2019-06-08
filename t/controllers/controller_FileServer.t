# ===================================================================
# File:		t/controllers/controller_FileServer.t
# Project:	ShinyCMS
# Purpose:	Tests for fileserver user-facing features
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
use Test::WWW::Mechanize::Catalyst::WithContext;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
	'/fileserver',
	'Fetch /fileserver with no params'
);
$t->title_is(
	'Home - ShinySite',
	'/filesever with no params redirects to homepage'
);
# Attempt to fetch a restricted file without logging in first
$t->get( '/fileserver/auth/Eternal/dir-one/empty-file.txt' );
ok(
	$t->status == 403,
	'User is forbidden to access restricted files without logging in first'
);
# Log in as a user from demo data, with permission to view restricted files
$t = login_test_user( 'viewer', 'changeme' );
ok(
	$t,
	'Logged in as user with restricted file access'
);
# Attempt to fetch the file again
$t->get( '/fileserver/auth/Eternal/dir-one/empty-file.txt' );
ok(
	$t->status == 200,
	'User is allowed to access restricted files after logging in'
);
# Attempt to fetch restricted files from some other access groups
$t->get( '/fileserver/auth/Expired/dir-two/also-empty.txt' );
ok(
	$t->status == 403,
	'User cannot reach files if their access expired last year'
);
$t->get( '/fileserver/auth/Unexpired/sub/sub/sub/dir/empty-too.txt' );
ok(
	$t->status == 200,
	'User can reach files if their access expires next year'
);
$t->get( '/fileserver/auth/Exclusive/and-empty.txt' );
ok(
	$t->status == 403,
	'User cannot reach files from access groups they are not in'
);
# Attempt to fetch a non-existent file
$t->get( '/fileserver/auth/Eternal/dir-one/no-such-file.txt' );
ok(
	$t->status == 404,
	'Attempting to fetch a non-existent file results in a 404 page'
);

done_testing();
