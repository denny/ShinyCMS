# ===================================================================
# File:		t/controllers/controller-Form.t
# Project:	ShinyCMS
# Purpose:	Tests for ShinyCMS form handling features
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

# Hand-munged URLs get sent somewhere sensible
$t->get_ok(
	'/form',
	'Try to load /form directly'
);
$t->title_is(
	'Home - ShinySite',
	'Attempting to visit /form directly gets redirected to site homepage'
);
# Fetch and submit both types of form (HTML / plain text)
$t->get_ok(
	'/pages/home/contact-us',
	'Try to fetch the first contact form'
);
$t->title_is(
	'Contact Us - ShinySite',
	'Loaded first contact form'
);
$t->submit_form_ok({
	form_id => 'contact',
	fields => {
		email_from_name => 'Test Suite',
		email_from	  => 'form-tests@shinycms.org',
		email_subject   => 'Submitted contact form to HTML form handler',
		message_body	=> 'Insert message body here...',
	}},
	'Submitted first contact form with name'
);
$t->post_ok(
	'/form/contact-html',
	{
		email_from	=> 'form-tests@shinycms.org',
		email_subject => 'Posted directly to HTML form handler',
		message_body  => 'Insert message body here...',
	},
	'Submitted first contact form without name'
);
$t->title_is(
	'Feature List - ShinySite',
	"Redirected to 'features' page after submitting first contact form"
);
$t->add_header( Referer => undef );
$t->post_ok(
	'/form/contact',
	{
		email_from_name => 'Test Suite',
		email_from	  => 'form-tests@shinycms.org',
		email_subject   => 'Posted directly to plain text form handler',
		message_body	=> 'Insert message body here...',
		'g-recaptcha-response' => 'fake'
	},
	'Submitted second contact form with name'
);
$t->post_ok(
	'/form/contact',
	{
		email_from	=> 'form-tests@shinycms.org',
		email_subject => 'Posted directly to plain text form handler',
		message_body  => 'Insert message body here...',
		'g-recaptcha-response' => 'fake'
	},
	'Submitted second contact form without name'
);
$t->title_is(
	'Home - ShinySite',
	"Redirected back to homepage after submitting second contact form"
);
$t->post_ok(
	'/form/contact',
	{
		email_from	=> 'form-tests@shinycms.org',
		email_subject => 'Posted directly to HTML form handler',
		message_body  => 'Insert message body here...',
	},
	'Submitted second contact form without recaptcha field'
);
$t->text_contains(
	'You must fill in the reCaptcha.',
	'Got error message for not sending recaptcha response when form requires it'
);
$t->post_ok(
	'/form/no-such-form',
	{
		no_such_field => 'no such value',
	},
	'Attempting to post to non-existent form handler is handled gracefully'
);
ok(
	$t->uri->path eq '/',
	'Bounced back to site homepage'
);
$t->text_contains(
	'Could not find form handler for no-such-form',
	'Got error message for trying to post form data to a non-existent form'
);

done_testing();
