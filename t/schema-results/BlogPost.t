# ===================================================================
# File:		t/schema-results/BlogPost.t
# Project:	ShinyCMS
# Purpose:	Tests for BlogPost model
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


# Get a schema object
my $schema = get_schema();

# Create a blog, create a blog post
my $blog = $schema->resultset( 'Blog' )->find_or_create({
	title => 'Test Blog',
});
my $post = $blog->blog_posts->find_or_create({
	title     => 'Comments Disabled',
	url_title => 'comments-disabled',
	body      => 'Post for testing comment count with comments disabled',
});

# Test the comment count method for a post without a discussion
ok(
	$post->comment_count == 0,
	'Comment count for post with comments disabled is zero'
);

# Tidy up
$post->delete;
$blog->delete;

done_testing();
