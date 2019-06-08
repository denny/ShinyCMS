# ===================================================================
# File:		t/controllers/controller-Tag.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS tag controller
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

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
	'/tag',
	'Fetch list of tags'
);
$t->title_is(
	'Tag List - ShinySite',
	'Loaded list of tags'
);

done_testing();
