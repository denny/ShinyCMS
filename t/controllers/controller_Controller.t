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

use Test::MockObject;
use Test::More;
use Test::WWW::Mechanize::Catalyst::WithContext;
use Try::Tiny;

use ShinyCMS::Controller;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

# ->user_exists_and_can( $c, $attempted_action, $required_role, $redirect_path )
# Checks whether a user has the required role to perform the specified action

# Not logged in
my $t = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'ShinyCMS' );

$t->get_ok(
	'/admin/pages/add',
	'Attempt to go directly to an admin page without logging in first'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Got redirected to admin login page'
);
# Log in as a Poll Admin, for rest of tests
my $poll_admin = create_test_admin( 'test_controller_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to login as a Poll Admin';
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as a Poll Admin'
);
# Missing action
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
# Missing role
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
# Invalid role
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
# Default redirect
ShinyCMS::Controller->user_exists_and_can( $c, {
	action   => 'go somewhere they should not, with default redirect',
	role	 => 'CMS Page Editor',
});
ok(
	$c->response->redirect =~ m{/$},
	'->user_exists_and_can() set default redirect for unauthorised user'
);
# Specified redirect
ShinyCMS::Controller->user_exists_and_can( $c, {
	action   => 'go somewhere they should not, specified redirect',
	role	 => 'CMS Page Editor',
	redirect => '/pages/home'
});
ok(
	$c->response->redirect =~ m{/pages/home$},
	'->user_exists_and_can() set specified redirect for unauthorised user'
);


# ->recaptcha_result( $c )
# Checks whether the user passed a recaptcha test

my $on_off = $ENV{ RECAPTCHA_OFF };

# ENV override set
$ENV{ RECAPTCHA_OFF } = 1;
my $captcha_result = ShinyCMS::Controller->recaptcha_result( $c );
ok(
	$captcha_result->{ is_valid } == 1,
	'Got positive result from Recaptcha code with RECAPTCHA_OFF set'
);

# ENV override not set
$ENV{ RECAPTCHA_OFF } = undef;
$captcha_result = ShinyCMS::Controller->recaptcha_result( $c );
ok(
$captcha_result->{ is_valid } == 0,
	'Got negative result from Recaptcha code with RECAPTCHA_OFF unset'
);

$ENV{ RECAPTCHA_OFF } = $on_off;


# ->make_url_slug( $input_string )
# Converts the input string into a URL slug

my $input  = "This isn't the 1st test! :-)";
my $wanted = 'this-isnt-the-1st-test';
my $output = ShinyCMS::Controller->make_url_slug( $input );
ok(
	$output eq $wanted,
	'"'.$input.'" became "'.$wanted.'"'
);


# Supporting methods for ->akismet_result()

my $fat_controller = ShinyCMS::Controller->new( $c );

my $client = $fat_controller->akismet_client( $c );

ok(
	( not defined $client ),
	'->akismet_client returned undef because no key is set'
);

# # TODO: Set a key (without exposing it?!)
# ok(
# 	$client->isa( 'Net::Akismet' ),
# 	'->akismet_client returned a Net::Akismet object'
# );

my $param_obj = Test::MockObject->new;
$param_obj->set_always( 'body', 'ShinyCMS Test Suite' );

my $request = Test::MockObject->new;
$request->set_always( 'address',    '123.45.67.89'        );
$request->set_always( 'referer',    'http://example.com/' );
$request->set_always( 'user_agent', 'shinycms-tests-21.3' );
$request->set_always( 'param',       $param_obj           );

my $details = $fat_controller->comment_details( $request );
ok(
	$details->{ 'USER_IP' } eq '123.45.67.89',
	'->comment_details returns a hash with the expected content'
);

my $params = {
	author_name => 'tests',
	author_type => 'Site User'
};

$details = $fat_controller->add_author_details( $details, $params );
ok(
	$details->{ 'COMMENT_AUTHOR' } eq 'tests',
	'->add_author_details adds the name and email from the form to the data'
);

$details = $fat_controller->add_user_details( $details, $poll_admin );
ok(
	$details->{ 'COMMENT_AUTHOR_EMAIL' } eq $poll_admin->email,
	'->add_user_details adds details of the logged-in user to the data'
);

# Exercise other side of ||= in add_user_details and guard clause in add_author_details
my $params2 = {
	author_email => 'tests@example.com',
	author_type  => 'Site User'
};
my $details2 = $fat_controller->comment_details( $request );
$details2 = $fat_controller->add_author_details( $details2, { author_type => 'Anonymous' } );
$details2 = $fat_controller->add_author_details( $details2, $params2 );
$details2 = $fat_controller->add_user_details( $details2, $poll_admin );


ok(
	( not defined $fat_controller->log_no_response( $c ) ),
	'->log_no_response returns undef'
);
ok(
	$fat_controller->log_spam_comment( $c, 'Spam, spam, egg, chips, and spam.' ) == 1,
	'->log_spam_comment returns 1'
);

my $full_text = <<EOT;
ShinyCMS is an open source CMS. This version is built with Perl and Catalyst.
EOT

my $truncated_text = 'ShinyCMS is an open source CMS. This version ...';

ok(
	$fat_controller->excerpt( $full_text ) eq $truncated_text,
	'->excerpt returns truncated version of longer text'
);

ok(
	$fat_controller->excerpt( $truncated_text ) eq $truncated_text,
	'->excerpt leaves text alone if it is already short enough'
);



# Tidy up
remove_test_admin( $poll_admin );

done_testing();
