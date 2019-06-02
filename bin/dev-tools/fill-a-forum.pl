#!/usr/bin/env perl

# ===================================================================
# File:     bin/dev-tools/fill-a-forum.pl
# Project:  ShinyCMS
# Purpose:  Populate a ShinyCMS forum with posts and comments
#
# Author:   Denny de la Haye <2019@denny.me>
# Copyright (c) 2009-2019 Denny de la Haye
#
# ShinyCMS is free software; you can redistribute it and/or modify it
# under the terms of either the GPL 2.0 or the Artistic License 2.0
# ===================================================================

use strict;
use warnings;

# Local modules
use FindBin qw( $Bin );
use lib "$Bin/../../lib";
use ShinyCMS;
use ShinyCMS::Schema;


my $debug = 1;	# Display debug output?


# Connect to ShinyCMS database
my $db = ShinyCMS::Schema->connect(
	ShinyCMS->config->{ 'Model::DB' }->{ connect_info }
);

# Start
print "Posting to forum...\n";

# Get a ShinyCMS user
my $user = $db->resultset('User')->first;

# Get a forum
my $forum = $db->resultset('Forum')->first;

# Create forum posts
foreach my $i ( 1 .. 10 ) {
	print "Posting: $i\n" if $debug;

	# Create forum post
	my $post = $forum->forum_posts->create({
		title     => 'Testing: '.$i,
		url_title => 'testing-'.$i,
		author    => $user->id,
		body      => 'ZOMG testing '.$i,
		posted    => DateTime->now,
	});

	# Create a new discussion, attach it to the new forum post
	my $discussion = $db->resultset('Discussion')->create({
		resource_id   => $post->id,
		resource_type => 'ForumPost',
	});
	$post->update({ discussion => $discussion->id });

	my $cid = 0;
	foreach my $j ( 1 .. 5 ) {
		# Create some comments on this post
		$cid++;
		my $comment = $post->discussion->comments->create({
			id        => $cid,
			title     => 'Comment: '.$cid,
			author    => $user->id,
			body      => $cid.' MOAR!',
			posted    => DateTime->now,
			author_type => 'Site User',
		});

		foreach my $k ( 1 .. 2 ) {
			# Create some replies to this comment
			$cid++;
			my $reply = $post->discussion->comments->create({
				id        => $cid,
				parent    => $comment->id,
				title     => 'Comment: '.$cid,
				author    => $user->id,
				body      => $cid.' MOOOAAAARRRR!',
				posted    => DateTime->now,
				author_type => 'Site User',
			});

			foreach my $l ( 1 .. 1 ) {
				# Create some replies to this reply
				$cid++;
				my $reply = $post->discussion->comments->create({
					id        => $cid,
					parent    => $reply->id,
					title     => 'Comment: '.$cid,
					author    => $user->id,
					body      => $cid.' EVEN MOOOAAAARRRR!',
					posted    => DateTime->now,
					author_type => 'Site User',
				});

				foreach my $m ( 1 .. 3 ) {
					# Create some replies to this reply
					$cid++;
					my $reply = $post->discussion->comments->create({
						id        => $cid,
						parent    => $reply->id,
						title     => 'Comment: '.$cid,
						author    => $user->id,
						body      => $cid.' EVEN MOAR MOOOAAAARRRR!',
						posted    => DateTime->now,
						author_type => 'Site User',
					});
				}
			}
		}
	}
}

# Finish
print "Finished posting.\n";

