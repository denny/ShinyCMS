#!/usr/bin/env perl

# ===================================================================
# File:     bin/dev-tools/wordpress-to-shinyblog.pl
# Project:  ShinyCMS
# Purpose:  Import Wordpress blog into ShinyCMS blog
#
# Author:	Denny de la Haye <2019@denny.me>
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
use Wordpress::DB;


# Config
my $sc_username = 'Admin';		# ShinyCMS username to attribute blog posts to
my $wp_database = 'wordpress';	# Name of Wordpress database
my $wp_user     = 'wordpress';	# Wordpress database username
my $wp_pass     = 'wordpress';	# Wordpress database password

my $debug = 1;	# Display debug output?


# Connect to ShinyCMS database
my $sc_db = ShinyCMS::Schema->connect(
	ShinyCMS->config->{ 'Model::DB' }->{ connect_info }
);

# Connect to Wordpress database
my $wp_db = Wordpress::DB->connect({
	dsn        => 'dbi:mysql:'.$wp_database,
	user       => $wp_user,
	password   => $wp_pass,
	quote_char => '`',
	on_connect_call => 'set_strict_mode',
});


# Start
print "Starting import...\n";

# Get ShinyCMS blog
my $sc_blog = $sc_db->resultset('Blog')->search->first;

# Get ShinyCMS user
my $sc_user = $sc_db->resultset('User')->find({ username => $sc_username });

# Get Wordpress posts
my @posts = $wp_db->resultset('WpPost')->search({
	post_status => 'publish',
})->all;

# Loop through posts inserting them and their comments into ShinyCMS database
foreach my $wp_post ( @posts ) {
	print 'Processing next post: ', $wp_post->post_title, "\n" if $debug;

	# Get post URL title, or create one
	my $url_title = $wp_post->post_name;
	$url_title = make_url_title( $wp_post->post_title ) unless $url_title;

	# Tidy up post body
	my $body = $wp_post->post_content;
	# Replace newlines (possibly DOS-format) with HTML paragraph tags
	$body =~ s{\r?\n\r?\n}{</p>\n\n<p>}g;
	$body = '<p>'.$body.'</p>';
	# Remove double-spacing special characters
	$body =~ s{[^[:word:]|[:punct:]|[:space:]]}{}g;
	# Put a newline between back-to-back links, otherwise it gets confused (?)
	$body =~ s{</a><a}{</a>\n<a}g;
	# Fix link href URLs
	$body =~ s{href="https?://[\w\.-]+/blogs/wp-content/uploads/\d\d\d\d/\d\d/(.+)"}{href="/static/cms-uploads/images/$1"}g;
	# Fix img src URLs
	$body =~ s{src="https?://[\w\.-]+/blogs/wp-content/uploads/\d\d\d\d/\d\d/(.+)"}{src="/static/cms-uploads/images/$1"}g;

	# Create ShinyCMS blog post
	my $sc_post = $sc_blog->blog_posts->create({
		title     => $wp_post->post_title,
		url_title => $url_title,
		author    => $sc_user->id,
		body      => $body,
		posted    => $wp_post->post_date,
	});

	# Create a new discussion, attach it to the new blog post
	my $discussion = $sc_db->resultset('Discussion')->create({
		resource_id   => $sc_post->id,
		resource_type => 'BlogPost',
	});
	$sc_post->update({ discussion => $discussion->id });

	# Get the top-level Wordpress comments for this post
	my @wp_comments = $wp_db->resultset('WpComment')->search({
		comment_post_id  => $wp_post->id,
		comment_approved => 1,
		comment_parent   => 0,
	})->all;

	my $id = 0;
	foreach my $wp_comment ( @wp_comments ) {
		# Recurse into each thread to do nested comments
		$id = add_comment_thread( $discussion, $wp_db, $wp_post, $wp_comment, undef, $id );
	}

	my $s = 's'; $s = '' if $id == 1;
	print "Found $id comment$s.\n";
}

# Finish
print "Finished.\n";



# ========== ( Supporting functions ) ==========

sub add_comment_thread {
	my( $discussion, $wp_db, $wp_post, $wp_comment, $sc_parent_id, $id ) = @_;

	$id++;
	my $sc_comment = $discussion->comments->create({
		id           => $id,
		body         => $wp_comment->comment_content,
		posted       => $wp_comment->comment_date,
		author_type  => 'Unverified',
		author_name  => $wp_comment->comment_author,
		author_email => $wp_comment->comment_author_email,
		author_link  => $wp_comment->comment_author_url,
		parent       => $sc_parent_id,
	});

	my @wp_comments = $wp_db->resultset('WpComment')->search({
		comment_post_id  => $wp_post->id,
		comment_approved => 1,
		comment_parent   => $wp_comment->comment_id,
	})->all;

	foreach my $wp_comment ( @wp_comments ) {
		# Recurse into each thread to do nested comments
		add_comment_thread( $discussion, $wp_db, $wp_post, $wp_comment, $sc_comment->id, $id );
	}

	return $id;
}


sub make_url_title {
	my( $url_title ) = @_;

	$url_title =~ s/s+/-/g;		# Change spaces into hyphens
	$url_title =~ s/[^-\w]//g;	# Remove anything that's not in: A-Z, a-z, 0-9, _ or -
	$url_title =~ s/-+/-/g;		# Change multiple hyphens to single hyphens
	$url_title =~ s/^-//;		# Remove hyphen at start, if any
	$url_title =~ s/-$//;		# Remove hyphen at end, if any

	return lc $url_title;
}

