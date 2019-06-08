# ===================================================================
# File:		t/controllers/controller-Root.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS root controller (/, search, etc)
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
	'/',
	'Fetch /'
);
$t->title_is(
	'Home - ShinySite',
	'Loaded homepage (default CMS page+section, from Pages controller)'
);
$t->submit_form_ok({
	form_id => 'header-search',
	fields => {
		search => 'test'
	}},
	'Submitted search form in header'
);

done_testing();
