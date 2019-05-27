use strict;
use warnings;

use Test::More;

use lib 't/support';
require 'login_helpers.pl';  ## no critic

my( $test_user, $pw ) = create_test_user();

my $t = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'ShinyCMS' );

# Check that hand-munged/malformed URLs do something sensible
$t->get_ok(
    '/discussion',
    'Try to fetch /discussion with no params'
);
$t->title_is(
    'Home - ShinySite',
    '/discussion (with no params) redirects to /'
);
$t->get_ok(
    '/discussion/1',
    'Try to view a discussion without context'
);
$t->title_is(
    'w1n5t0n - ShinySite',
    '/discussion/1 redirects to parent blog post'
);
# Fetch the 'add comment' page for a discussion thread
$t->get_ok(
    '/discussion/1/add-comment',
    "Fetch the 'add comment' page for a discusion thread"
);
$t->submit_form_ok({
    form_id => 'add_comment',
    with_fields => {
        author_type => 'Unverified',
        author_name => 'Test Suite',
        title       => 'First Test Comment',
        body        => 'This is a test comment, posted by a pseudonymous user.',
    }},
    'Posting a pseudonymous comment'
);
$t->content_contains(
    'This is a test comment, posted by a pseudonymous user.',
    'Comment posted successfully (pseudonymous)'
);

$t->follow_link_ok(
    { text => 'Add a new comment' },
    "Click 'Add a new comment' link"
);
$t->submit_form_ok({
    form_id => 'add_comment',
    fields => {
        author_type => 'Anonymous',
        title       => 'Second Test Comment',
        body        => 'This is a test comment, posted by an anonymous user.',
    }},
    'Posting an anonymous comment'
);
$t->content_contains(
    'This is a test comment, posted by an anonymous user.',
    'Comment posted successfully (anonymous)'
);

# Log in
$t = login_test_user() or die 'Failed to log in as non-admin test user';

$t->get_ok(
    '/discussion/1/add-comment',
    'Fetch the add-comment page again'
);
$t->submit_form_ok({
    form_id => 'add_comment',
    fields => {
        author_type => 'Site User',
        title       => 'Third Test Comment',
        body        => 'This is a test comment, posted by a logged-in user.',
    }},
    'Posting a logged-in comment'
);
$t->content_contains(
    'This is a test comment, posted by a logged-in user.',
    'Comment posted successfully (logged-in user)'
);

# Tidy up
$test_user->comments->delete;

remove_test_user();

done_testing();
