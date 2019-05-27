# ===================================================================
# File:		t/controllers/Controller.t
# Project:	ShinyCMS
# Purpose:	Tests for methods in Controller.pm
# 
# Author:	Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
# 
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

use Try::Tiny;
use Test::More;
use Test::WWW::Mechanize::Catalyst;

use ShinyCMS::Controller;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Exercise the $c->user_exists_and_can() method's 'not logged in' branch
$t->get_ok(
    '/admin/pages/add',
    'Attempt to go directly to an admin page without logging in first'
);
$t->title_is(
    'Log In - ShinyCMS',
    'Got redirected to admin login page'
);
#$t->text_contains(
#    'You must be logged in to ',
#    'Informative error message found in page content'
#);
# Now test the guard clauses for no action or no role
my $c;
create_test_user();
$t = login_test_user() or die 'Failed to login as test user';

try {
    ShinyCMS::Controller->user_exists_and_can( $c, { role => 'News Admin' } );
}
catch {
    ok( 1, 'Caught die() for user_exists_and_can() with no action specified' );
};
try {
    ShinyCMS::Controller->user_exists_and_can( $c, { action => 'Testing' } );
}
catch {
    ok( 1, 'Caught die() for user_exists_and_can() with no role specified' );
};
try {
    ShinyCMS::Controller->user_exists_and_can( $c, { role => 'Bad Role' } );
}
catch {
    ok( 1, 'Caught die() for user_exists_and_can() with invalid role specified' );
};

remove_test_user();

done_testing();
