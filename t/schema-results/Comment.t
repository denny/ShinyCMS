# ===================================================================
# File:     t/schema-results/Comment.t
# Project:  ShinyCMS
# Purpose:  Tests for Comment model
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

my $test_user = create_test_user( 'test_comment_model' );

my $news_item = $test_user->news_items->create({
  title => 'Test post',
  url_title => 'test-post',
  body => 'This is a test post.'
});

my $discussion = $schema->resultset( 'Discussion' )->create({
  resource_type => 'NewsItem',
  resource_id   => $news_item->id,
});

my $comment1 = $discussion->comments->create({
  id => 1,
  author_type => 'anonymous'
});
my $comment2 = $discussion->comments->create({
  id => 2,
  author_type => 'anonymous'
});

ok(
  $schema->resultset( 'Comment' )->count({ spam => 1 }) == 0,
  'Zero spam comments before $comment1->mark_as_spam'
);

$comment1->mark_as_spam;

ok(
  $schema->resultset( 'Comment' )->count({ spam => 1 }) == 1,
  'One spam comment after $comment1->mark_as_spam'
);

$comment1->mark_as_not_spam,

ok(
  $schema->resultset( 'Comment' )->count({ spam => 1 }) == 0,
  'And back to zero again after $comment1->mark_as_not_spam'
);

$comment1->delete;
$comment2->delete;
$discussion->delete;
$news_item->delete;
$test_user->delete;

done_testing();
