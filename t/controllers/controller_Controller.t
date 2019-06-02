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
use Test::WWW::Mechanize::Catalyst::WithContext;

use ShinyCMS::Controller;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

# Exercise the $c->user_exists_and_can() method's 'not logged in' branch
$t->get_ok(
    '/admin/pages/add',
    'Attempt to go directly to an admin page without logging in first'
);
$t->title_is(
    'Log In - ShinyCMS',
    'Got redirected to admin login page'
);

# Now test the guard clauses for no action or no/invalid role
my $controller_test = create_test_admin( 'controller_test', 'Poll Admin' );
$t = login_test_admin( 'controller_test', 'controller_test' )
    or die 'Failed to login as controller_test';
my $c = $t->ctx;

try {
    ShinyCMS::Controller->user_exists_and_can( $c, {
        role => 'News Admin'
    });
}
catch {
    ok(
        m{^Attempted authorisation check without action.},
        'Caught die() for user_exists_and_can() with no action specified'
    )
};

try {
    ShinyCMS::Controller->user_exists_and_can( $c, {
        action => 'test this branch'
    });
}
catch {
    ok(
        m{^Attempted authorisation check without role.},
        'Caught die() for user_exists_and_can() with no role specified'
    );
};

try {
    ShinyCMS::Controller->user_exists_and_can( $c, {
        action => 'specific an invalid role',
        role   => 'Bad Role'
    });
}
catch {
    ok(
        m{^Attempted authorisation check with invalid role \(Bad Role\).},
        'Caught die() for user_exists_and_can() with invalid role specified'
    );
};

ShinyCMS::Controller->user_exists_and_can( $c, {
    action   => 'go somewhere they should not, with default redirect',
    role     => 'CMS Page Editor',
});
ok(
    $c->response->redirect =~ m{/$},
    '->user_exists_and_can() set default redirect for unauthorised user'
);

ShinyCMS::Controller->user_exists_and_can( $c, {
    action   => 'go somewhere they should not, specified redirect',
    role     => 'CMS Page Editor',
    redirect => '/pages/home'
});
ok(
    $c->response->redirect =~ m{/pages/home$},
    '->user_exists_and_can() set specified redirect for unauthorised user'
);

my $captcha_result = ShinyCMS::Controller->_recaptcha_result( $c );
ok(
    defined $captcha_result->{ is_valid },
    'Got a result from Recaptcha code'
);

remove_test_admin( $controller_test );

done_testing();
