# ===================================================================
# File:		t/admin-controllers/controller_Admin-Spam.t
# Project:	ShinyCMS
# Purpose:	Tests for spam comment moderation features
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

my $schema = get_schema();


# Insert some test data

my $news_item  = $schema->resultset( 'NewsItem' )->update_or_create({
	title     => 'Testing comment moderation',
	url_title => 'spam-tests',
	body      => 'If you build it, they will come.',
	author    => 1,
});
my $discussion = $schema->resultset( 'Discussion' )->update_or_create({
	resource_type => 'NewsItem',
	resource_id   => $news_item->id,
});
my $spam1 = $discussion->comments->update_or_create({
	id          => 1,
	spam        => 1,
	author_type => 'Anonymous',
	title       => 'Spam, spam, spam, egg, and spam',
});
my $spam2 = $discussion->comments->update_or_create({
	id          => 2,
	spam        => 1,
	author_type => 'Anonymous',
	title       => 'Have you got any spam?',
});
my $spam3 = $discussion->comments->update_or_create({
	id          => 3,
	spam        => 1,
	author_type => 'Unverified',
	author_name => 'Random Opera Singers',
	title       => 'Spam, lovely Spam, wonderful Spam',
});
my $spam4 = $discussion->comments->update_or_create({
	id          => 4,
	spam        => 1,
	author_type => 'Anonymous',
	title       => 'Lobster thermidor',
	body        => 'Lobster thermidor aux crevettes with a Mornay sauce garnished '.
					'with truffle pâté, brandy and with a fried egg on top and spam',
});

# Create and log in as a Discussion Admin
my $admin = create_test_admin(
	'test_admin_spam',
	'Discussion Admin',
	'News Admin'
);
my $t = login_test_admin( $admin->username, $admin->username )
	or die 'Failed to log in as Discussion Admin';
# Check login was successful
my $c = $t->ctx;
ok(
	$c->user->has_role( 'Discussion Admin' ),
	'Logged in as Discussion Admin'
);

# Load spam comment moderation form/list
$t->get_ok(
	'/admin/spam',
	'Fetch spam admin area'
);
$t->title_is(
	'Spam Comments - ShinyCMS',
	'Loaded spam moderation area'
);
$t->content_contains(
	'Lobster thermidor',
	'Our spam comment data is here'
);

# Confirm that a comment is spam
$t->submit_form_ok({
	form_id => 'spam_moderation_form',
	fields => {
		comment_uid => [ $spam3->uid ],
		action => 'delete'
	}},
	'Submitted form to confirm spam flag on opera singers'
);
$t->title_is(
	'Spam Comments - ShinyCMS',
	'Returned to list of spam'
);
$t->content_lacks(
	'Spam, lovely Spam, wonderful Spam',
	'Verified that the opera singers have been deleted'
);
my $gone = 0;
$gone = 1 unless $schema->resultset( 'Comment' )->find({ uid => $spam3->uid });
ok( $gone, 'Verified that comment is no longer in database' );

# Mark a comment as not-spam
$t->submit_form_ok({
	form_id => 'spam_moderation_form',
	fields => {
		comment_uid => [ $spam2->uid ],
		action => 'not-spam'
	}},
	'Submitted form to confirm that asking about spam is not spam'
);
$t->title_is(
	'Spam Comments - ShinyCMS',
	'Returned to list of spam'
);
$t->content_lacks(
	'Have you got any spam?',
	'Verified that enquiry about spam is not longer in moderation queue'
);
my $ham = 0;
$ham = 1 if $schema->resultset( 'Comment' )->find({ uid => $spam2->uid })->spam == 0;
ok( $ham, 'Verified that comment is no longer marked as spam' );


# Log out, then try to access admin area for spam again
$t->follow_link_ok(
	{ text => 'Logout' },
	'Log out of discussion admin account'
);
$t->get_ok(
	'/admin/spam',
	'Try to access admin area for spam comments after logging out'
);
$t->title_is(
	'Log In - ShinyCMS',
	'Redirected to admin login page instead'
);

# Log in as the wrong sort of admin, and make sure we're still blocked
my $poll_admin = create_test_admin( 'test_admin_spam_poll_admin', 'Poll Admin' );
$t = login_test_admin( $poll_admin->username, $poll_admin->username )
	or die 'Failed to log in as Poll Admin';
$t->get_ok(
	'/admin/spam',
	'Attempt to fetch spam moderation area as Poll Admin'
);
$t->title_unlike(
	qr{^.*Spam.* - ShinyCMS$},
	'Failed to reach spam moderation area without any appropriate roles enabled'
);


# Tidy up user accounts and leftover data
$discussion->comments->delete;
$discussion->delete;
$news_item->delete;

remove_test_admin( $poll_admin );
remove_test_admin( $admin      );

done_testing();
