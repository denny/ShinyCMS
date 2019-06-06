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
    'Anybody hitting /form directly gets a sensible redirect (to site homepage)'
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
        email_from      => 'form-tests@shinycms.org',
        email_subject   => 'Submitted via form on contact page',
        message_body    => 'Insert message body here...',
        'g-recaptcha-response' => 'fake'
    }},
    'Submitted first contact form'
);
$t->title_is(
    'Feature List - ShinySite',
    "Redirected to 'features' page after submitting first contact form"
);
$t->post_ok(
    '/form/contact',
    {
        email_from_name => 'Test Suite',
        email_from      => 'form-tests@shinycms.org',
        email_subject   => 'Submitted via form on contact page',
        message_body    => 'Insert message body here...',
    },
    'Submitted second contact form'
);
$t->title_is(
    'Home - ShinySite',
    "Redirected back to homepage after submitting second contact form"
);

# ...

done_testing();
