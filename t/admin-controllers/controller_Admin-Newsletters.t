# ===================================================================
# File:		t/admin-controllers/controller_Admin-Newsletters.t
# Project:	ShinyCMS
# Purpose:	Tests for newsletter admin features
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


# First, create and log in as a newsletter template admin
my $template_admin = create_test_admin(
	'test_admin_newsletters_template_admin',
	'Newsletter Admin',
	'Newsletter Template Admin'
);
my $t_ta = login_test_admin( $template_admin->username, $template_admin->username )
	or die 'Failed to log in as Newsletter Template Admin';
# Check login was successful
my $c = $t_ta->ctx;
ok(
	$c->user->has_role( 'Newsletter Template Admin' ),
	'Logged in as Newsletter Template Admin'
);
# Check we get sent to correct admin area by default
$t_ta->title_is(
	'List Newsletters - ShinyCMS',
	'Redirected to admin area for newsletters'
);


# ========== ( Newsletter Templates ) ==========

# Add a newsletter template
$t_ta->follow_link_ok(
	{ text => 'Add template' },
	'Follow link to add a new newsletter'
);
$t_ta->title_is(
	'Add Template - ShinyCMS',
	'Reached page for adding newsletter template'
);
$t_ta->submit_form_ok({
	form_id => 'add_template',
	fields => {
		name => 'This is a test template'
	}},
	'Submitted form to create template'
);
$t_ta->title_is(
	'Edit Template - ShinyCMS',
	'Redirected to edit page for newly created template'
);
my @template_inputs1 = $t_ta->grep_inputs({ name => qr{^name$} });
ok(
	$template_inputs1[0]->value eq 'This is a test template',
	'Verified that template was created'
);

# Update template
$t_ta->submit_form_ok({
	form_id => 'edit_template',
	fields => {
		name => 'Template updated by test suite',
	}},
	'Submitted form to update template name'
);
my @template_inputs2 = $t_ta->grep_inputs({ name => qr{^name$} });
ok(
	$template_inputs2[0]->value eq 'Template updated by test suite',
	'Verified that template was updated'
);
my @template_inputs3 = $t_ta->grep_inputs({ name => qr{^template_id$} });
my $template_id = $template_inputs3[0]->value;

# Add an element to the template
$t_ta->submit_form_ok({
	form_id => 'add_element',
	fields => {
		new_element => 'foo',
		new_type	=> 'Short Text'
	}},
	'Submitted form to add template element'
);
$t_ta->text_contains(
	'foo - Short Text',
	'Verified that new element was added'
);


# Now, log in as standard newsletter admin
my $admin = create_test_admin(
	'test_admin_newsletters',
	'Newsletter Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Newsletter Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Newsletter Admin' ),
	'Logged in as Newsletter Admin'
);
# Check we get sent to correct admin area by default
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Redirected to admin area for newsletters'
);


# ========== ( Mailing Lists ) ==========

# Add a mailing list
$t->follow_link_ok(
	{ text => 'Add mailing list' },
	'Follow link to add a new mailing list'
);
$t->title_is(
	'Add Mailing List - ShinyCMS',
	'Reached page for adding mailing list'
);
$t->submit_form_ok({
	form_id => 'add_list',
	fields => {
		name => 'This is a test list'
	}},
	'Submitted form to create list'
);
$t->title_is(
	'Edit Mailing List - ShinyCMS',
	'Redirected to edit page for newly created list'
);
my @list_inputs1 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$list_inputs1[0]->value eq 'This is a test list',
	'Verified that list was created'
);

# Update the list
$t->submit_form_ok({
	form_id => 'edit_list',
	fields => {
		name => 'List updated by test suite',
	}},
	'Submitted form to update list name'
);
my @list_inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$list_inputs2[0]->value eq 'List updated by test suite',
	'Verified that list was updated'
);
$t->uri->path =~ m{/admin/newsletters/list/(\d+)/edit$};
my $list_id = $1;

# Subscribe someone to the list
my $list_subscriber = 'test-list-subscriber@shinycms.org';
$t->submit_form_ok({
	form_id => 'subscribe',
	fields => {
		name  => 'Testsubscriber Forlist',
		email => $list_subscriber,
	}},
	'Submitted form to subscribe someone to mailing list'
);
$t->text_contains(
	$list_subscriber,
	'Verified that our test subscriber was added to our test list'
);


# ========== ( Newsletters ) ==========

# Add a new newsletter
$t->follow_link_ok(
	{ text => 'Add newsletter' },
	'Follow link to add a new newsletter'
);
$t->title_is(
	'Add Newsletter - ShinyCMS',
	'Reached page for adding newsletter'
);
$t->submit_form_ok({
	form_id => 'add_newsletter',
	fields => {
		title => 'This is some test news'
	}},
	'Submitted form to create newsletter'
);
$t->title_is(
	'Edit Newsletter - ShinyCMS',
	'Redirected to edit page for newly created newsletter'
);
my @inputs1 = $t->grep_inputs({ name => qr{^url_title$} });
ok(
	$inputs1[0]->value eq 'this-is-some-test-news',
	'Verified that newsletter was created'
);

# Update newsletter
my $now = DateTime->now;
$t->submit_form_ok({
	form_id => 'edit_newsletter',
	fields => {
		title	  => 'Newsletter updated by test suite',
		url_title => '',
	}},
	'Submitted form to update title and regenerate url_title'
);
$t->submit_form_ok({
	form_id => 'edit_newsletter',
	fields => {
		sent_pick => $now,
		sent_date => $now->ymd,
		sent_time => $now->hms,
		hidden	  => 'on',
	}},
	'Submitted form to update newsletter sent time, and set to hidden'
);
my @inputs2 = $t->grep_inputs({ name => qr{url_title$} });
ok(
	$inputs2[0]->value eq 'newsletter-updated-by-test-suite',
	'Verified that newsletter was updated'
);
$t->uri->path =~ m{/admin/newsletters/edit/(\d+)$};
my $newsletter1_id = $1;
$t->submit_form_ok({
	form_id => 'edit_newsletter',
	fields => {
		template => $template_id,
		send_pick => '1',
		send_time => '23:59',
		send_date => '2099-12-31',
	}},
	'Submitted form again, to update newsletter template and send time'
);

# Add a second newsletter
$t->follow_link_ok(
	{ text => 'Add newsletter' },
	'Follow link to add a second newsletter'
);
$t->submit_form_ok({
	form_id => 'add_newsletter',
	fields => {
		title     => 'Second Test Newsletter',
		url_title => 'second-test',
	}},
	'Submitted form to create second newsletter'
);
$t->uri->path =~ m{/admin/newsletters/edit/(\d+)$};
my $newsletter2_id = $1;

# Preview the first newsletter
$t->post_ok(
	"/admin/newsletters/preview/$newsletter1_id",
	{
		title     => 'Testing Preview',
		name_1    => 'body',
		content_1 => 'Overriding newsletter body for preview test',
	},
	'Post form to preview a newsletter'
);
$t->content_contains(
	"<h1>\n\tTesting Preview\n</h1>",
	'Previewed a newsletter with title and body overridden'
);

$t->get( '/admin/newsletters' );
# Queue for sending
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/queue/$newsletter1_id$} },
	'Go to list of newsletters, click on link to send'
);
$t->text_contains(
	'Newsletter queued for sending',
	'Verified that send was queued'
);
# Unqueue
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/unqueue/$newsletter1_id$} },
	'Go to list of newsletters, click on link to cancel the send'
);
$t->text_contains(
	'Newsletter removed from delivery queue',
	'Verified that send was removed from queue'
);
# Queue a test send
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/test/$newsletter1_id$} },
	'Go to list of newsletters, click on link/button to send a test'
);
$t->text_contains(
	'Test newsletter queued',
	'Verified that test send was queued'
);
# Mark it as sent
my $schema = get_schema();
my $nl = $schema->resultset( 'Newsletter' )->find({	id => $newsletter1_id });
$nl->update({ status => 'Sent' });
ok(
	$nl->status eq 'Sent',
	"Mark newsletter as 'Sent' in database"
);
# Attempt to edit it again
$t->get_ok(
	"/admin/newsletters/edit/$newsletter1_id",
	"Attempt to edit 'sent' newsletter"
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Got bounced to list of newsletters instead of reaching edit page'
);
$t->text_contains(
	'Cannot edit newsletter after sending',
	'Got helpful error message about not editing after sending'
);
# Attempt to queue it for sending again
$t->get_ok(
	"/admin/newsletters/queue/$newsletter1_id",
	"Attempt to edit 'sent' newsletter"
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Got bounced to list of newsletters'
);
$t->text_contains(
	'Newsletter already sent.',
	'Got error message saying that the newsletter has already been sent'
);
# Attempt to remove it from the send queue
$t->get_ok(
	"/admin/newsletters/unqueue/$newsletter1_id",
	"Attempt to cancel delivery of already 'sent' newsletter"
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Got bounced to list of newsletters'
);
$t->text_contains(
	'Newsletter not in queue.',
	'Got error message saying that the newsletter has already been sent'
);
# Attempt a test send
$t->get_ok(
	"/admin/newsletters/test/$newsletter1_id",
	"Attempt to send a test copy of 'sent' newsletter"
);
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Got bounced to list of newsletters'
);
$t->text_contains(
	'Newsletter already sent.',
	'Got error message saying that the newsletter has already been sent'
);


# ========== ( Autoresponders ) ==========

# Add an autoresponder
$t->follow_link_ok(
	{ text => 'Add autoresponder' },
	'Follow link to add a new autoresponder'
);
$t->title_is(
	'Add Autoresponder - ShinyCMS',
	'Reached page for adding new autoresponder'
);
$t->submit_form_ok({
	form_id => 'add_autoresponder',
	fields => {
		description => 'This is a test autoresponder without a name set'
	}},
	'Submitted form to try to create autoresponder without a name set'
);
$t->title_is(
	'Add Autoresponder - ShinyCMS',
	'Bounced back to page for adding new autoresponder'
);
$t->text_contains(
	'You must set a name.',
	'Got helpful error message'
);
$t->submit_form_ok({
	form_id => 'add_autoresponder',
	fields => {
		name => 'This is a test autoresponder'
	}},
	'Submitted form to create autoresponder again, with a name this time'
);
$t->title_is(
	'Edit Autoresponder - ShinyCMS',
	'Redirected to edit page for newly created autoresponder'
);
my @autoresponder_inputs1 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$autoresponder_inputs1[0]->value eq 'This is a test autoresponder',
	'Verified that autoresponder was created'
);

# Update the autoresponder, foolishly wiping the name field blank
$t->submit_form_ok({
	form_id => 'edit_autoresponder',
	fields => {
		name => '',
	}},
	'Submit form to edit the new newsletter, wiping the name blank so that it fails'
);
$t->text_contains(
	'You must set a name.',
	'Got appropriate error message'
);
# Update the autoresponder, with a name this time
$t->submit_form_ok({
	form_id => 'edit_autoresponder',
	fields => {
		name => 'Autoresponder updated by test suite',
	}},
	'Submitted form to update autoresponder name'
);
my @autoresponder_inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$autoresponder_inputs2[0]->value eq 'Autoresponder updated by test suite',
	'Verified that autoresponder was updated'
);
$t->uri->path =~ m{/admin/newsletters/autoresponder/(\d+)/edit$};
my $autoresponder_id = $1;

# Add an email to the autoresponder
$t->follow_link_ok(
	{ text => 'Add new email' },
	'Click on link to add new email to autoresponder'
);
$t->title_is(
	'Add Autoresponder Email - ShinyCMS',
	'Reached form for adding new email'
);
$t->submit_form_ok({
	form_id => 'add_autoresponder_email',
	fields => {
		subject => 'First email in test sequence',
	}},
	'Submit form to add an email to autoresponder'
);

# Edit an autoresponder email
$t->submit_form_ok({
	form_id => 'edit_autoresponder_email',
	fields => {
	 	plaintext => 'This is a test autoresponder email',
	}},
	'Submit form to edit the new email, adding a plain text body'
);
my @autoresponder_inputs3 = $t->grep_inputs({ name => qr{^plaintext$} });
ok(
	$autoresponder_inputs3[0]->value eq 'This is a test autoresponder email',
	'Verified that autoresponder email was updated'
);
$t->uri->path =~ m{/admin/newsletters/autoresponder/\d+/email/(\d+)/edit$};
my $ar_email_id = $1;

# Preview an autoresponder email
$t->post_ok(
	"/admin/newsletters/autoresponder/$autoresponder_id/email/$ar_email_id/preview",
	{
		subject => 'Preview Title',
	},
	"Click on 'Preview' button"
);
$t->text_contains(
	'Preview Title',
	'Successfully generated preview'
);

# Subscribe somebody to autoresponder
my $subscriber_email = 'test-autoresponder-subscriber@shinycms.org';
$t->get_ok(
	"/admin/newsletters/autoresponder/$autoresponder_id/edit",
	'Return to edit page for our autoresponder'
);
$t->form_id( 'subscribe' );
$t->submit_form_ok({
	form_id => 'subscribe',
	fields => {
		name  => 'Autoresponder Testsubscriber',
		email => $subscriber_email,
	}},
	'Submit form to add subscriber to autoresponder'
);

# View the list of autoresponders
$t->follow_link_ok(
	{ text => 'List autoresponders' },
	'Click on link to view list of autoresponders'
);
$t->title_is(
	'Autoresponders - ShinyCMS',
	'Reached list of autoresponders'
);
# View the list of subscribers to our autoresponder
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/autoresponder/$autoresponder_id/subscribers} },
	'Click on link to view list of subscribers to our test autoresponder'
);
$t->title_is(
	'Autoresponder Subscribers - ShinyCMS',
	'Reached list of autoresponder subscribers'
);
$t->text_contains(
	$subscriber_email,
	'Verified that our test subscriber was added to our test autoresponder'
);
# Try to edit a non-existent autoresponder
$t->get_ok(
	'/admin/newsletters/autoresponder/999/edit',
	'Attempt to load the edit page for a non-existent autoresponder'
);
$t->title_is(
	'Autoresponders - ShinyCMS',
	'Reached list of autoresponders instead'
);
$t->text_contains(
	'Failed to find details of specified autoresponder.',
	'Got helpful error message'
);
# Try to edit a non-existent autoresponder email
$t->get_ok(
	"/admin/newsletters/autoresponder/$autoresponder_id/email/999/edit",
	'Attempt to load the edit page for a non-existent autoresponder email'
);
$t->title_is(
	'Edit Autoresponder - ShinyCMS',
	'Bounced back to autoresponder edit page instead'
);
$t->text_contains(
	'Failed to find details of specified autoresponder email.',
	'Got helpful error message'
);


# ========== ( Paid Lists ) ==========

# Add a paid list
$t->follow_link_ok(
	{ text => 'Add paid list' },
	'Follow link to add a new paid list'
);
$t->title_is(
	'Add Paid List - ShinyCMS',
	'Reached page for adding new paid list'
);
$t->submit_form_ok({
	form_id => 'add_paid_list',
	fields => {
		name => 'This is a test list'
	}},
	'Submitted form to create list'
);
$t->title_is(
	'Edit Paid List - ShinyCMS',
	'Redirected to edit page for newly created list'
);
my @paid_inputs1 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$paid_inputs1[0]->value eq 'This is a test list',
	'Verified that list was created'
);

# Update the paid list
$t->submit_form_ok({
	form_id => 'edit_paid_list',
	fields => {
		name => 'List updated by test suite',
	}},
	'Submitted form to update list name'
);
my @paid_inputs2 = $t->grep_inputs({ name => qr{^name$} });
ok(
	$paid_inputs2[0]->value eq 'List updated by test suite',
	'Verified that list was updated'
);
$t->uri->path =~ m{/admin/newsletters/paid-list/(\d+)/edit$};
my $paid_list_id = $1;

# Add an email to the paid list
$t->follow_link_ok(
	{ text => 'Add new email' },
	'Click on link to add new email to paid list'
);
$t->title_is(
	'Add Paid List Email - ShinyCMS',
	'Reached form for adding new email'
);
$t->submit_form_ok({
	form_id => 'add_paid_list_email',
	fields => {
		subject => 'First email in test sequence',
	}},
	'Submit form to add an email to paid list'
);

# Edit a paid list email
$t->submit_form_ok({
	form_id => 'edit_paid_list_email',
	fields => {
		plaintext => 'This is a test paid list email',
	}},
	'Submit form to edit the new email, adding a plain text body'
);
my @paid_list_inputs3 = $t->grep_inputs({ name => qr{^plaintext$} });
ok(
	$paid_list_inputs3[0]->value eq 'This is a test paid list email',
	'Verified that paid list email was updated'
);
$t->uri->path =~ m{/admin/newsletters/paid-list/\d+/email/(\d+)/edit$};
my $pl_email_id = $1;

# Preview a paid list email
$t->post_ok(
	"/admin/newsletters/paid-list/$paid_list_id/email/$pl_email_id/preview",
	{
		subject => 'Preview Title',
	},
	"Click on 'Preview' button"
);
$t->text_contains(
	'Preview Title',
	'Successfully generated preview'
);


# ========== ( Deletions ) ==========

# Delete newsletters (can't use submit_form_ok due to javascript confirmation)
$t->post_ok(
	'/admin/newsletters/save',
	{
		newsletter_id => $newsletter1_id,
		delete        => 'Delete'
	},
	'Submitted request to delete first test newsletter'
);
$t->post_ok(
	'/admin/newsletters/save',
	{
		newsletter_id => $newsletter2_id,
		delete        => 'Delete'
	},
	'Submitted request to delete second test newsletter'
);
# Check deleted item is no longer on list page
$t->title_is(
	'List Newsletters - ShinyCMS',
	'Reached list of newsletters'
);
$t->content_lacks(
	'Newsletter updated by test suite',
	'Verified that first newsletter was deleted'
);
$t->content_lacks(
	'Second Test Newsletter',
	'Verified that second newsletter was deleted'
);

# Delete mailing list subscriber
$t->follow_link_ok(
	{ text => 'List mailing lists' },
	'Return to list of mailing lists'
);
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/list/$list_id/edit} },
	'Click through to test list'
);
$t->follow_link_ok(
	{ text => 'Unsubscribe' },
	'Click on link to unsubscribe the test subscriber'
);
$t->text_lacks(
	$list_subscriber,
	'Verified that the test subscriber was unsubscribed from our test list'
);

# Delete mailing list
$t->post_ok(
	'/admin/newsletters/list/save',
	{
		list_id => $list_id,
		delete  => 'Delete'
	},
	'Submitted request to delete mailing list'
);
$t->title_is(
	'Mailing Lists - ShinyCMS',
	'Reached list of mailing lists'
);
$t->content_lacks(
	'List updated by test suite',
	'Verified that mailing list was deleted'
);

# Delete paid list
$t->post_ok(
	'/admin/newsletters/paid-list/'.$paid_list_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete mailing list'
);
$t->title_is(
	'Paid Lists - ShinyCMS',
	'Reached list of paid lists'
);
$t->content_lacks(
	'List updated by test suite',
	'Verified that paid list was deleted'
);

# Delete autoresponder subscriber
$t->follow_link_ok(
	{ text => 'List autoresponders' },
	'Click on link to list autoresponders'
);
$t->follow_link_ok(
	{ url_regex => qr{/admin/newsletters/autoresponder/$autoresponder_id/subscribers$} },
	'Click on link to list autoresponder subscribers'
);
$t->follow_link_ok(
	{ text => 'Delete' },
	'Click on link to delete subscriber'
);
$t->title_is(
	'Autoresponder Subscribers - ShinyCMS',
	'Reloaded list of subscribers'
);
$t->text_lacks(
	$subscriber_email,
	'Verified that subscriber was deleted'
);

# Delete autoresponder email
$t->post_ok(
	"/admin/newsletters/autoresponder/$autoresponder_id/email/$ar_email_id/save",
	{
		delete => 'Delete'
	},
	'Submitted request to delete autoresponder email'
);
$t->title_is(
	'Edit Autoresponder - ShinyCMS',
	'Redirected back to autoresponder edit page'
);
$t->text_lacks(
	'First email in test sequence',
	'Verified that email was deleted'
);

# Delete autoresponder
$t->post_ok(
	'/admin/newsletters/autoresponder/'.$autoresponder_id.'/save',
	{
		delete => 'Delete'
	},
	'Submitted request to delete autoresponder'
);
$t->title_is(
	'Autoresponders - ShinyCMS',
	'Reached list of autoresponders'
);
$t->content_lacks(
	'Autoresponder updated by test suite',
	'Verified that autoresponder was deleted'
);

# Delete template
$c = $t_ta->ctx;
ok(
	$c->user->has_role( 'Newsletter Template Admin' ),
	'Logged back in as Newsletter Template Admin'
);
$t_ta->post_ok(
	'/admin/newsletters/template/save',
	{
		template_id => $template_id,
		delete      => 'Delete'
	},
	'Submitted request to delete newsletter template'
);
$t_ta->title_is(
	'Newsletter Templates - ShinyCMS',
	'Reached list of templates'
);
$t_ta->content_lacks(
	'Template updated by test suite',
	'Verified that template was deleted'
);


# Log out, then try to access admin area for newsletters again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of newsletter admin account'
);
$t->get_ok(
	'/admin/newsletters',
	'Try to access admin area for newsletters after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_newsletters_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$c = $t->ctx;
ok(
	$c->user->has_role( 'Poll Admin' ),
	'Logged in as Poll Admin'
);
$t->get_ok(
	'/admin/newsletters',
	'Try to access admin area for newsletters'
);
$t->title_unlike(
	qr{^.*Newsletter.* - ShinyCMS$},
	'Poll Admin cannot access admin area for newsletters'
);


# Tidy up user accounts
remove_test_admin( $template_admin );
remove_test_admin( $admin          );
remove_test_admin( $poll_admin     );

done_testing();
