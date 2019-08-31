package ShinyCMS::Controller::Discussion;

use Moose;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Discussion

=head1 DESCRIPTION

Controller for ShinyCMS discussion threads.

=cut


has can_comment => (
	isa     => Str,
	is      => 'ro',
	default => 'Anonymous',
);

has can_like => (
	isa     => Str,
	is      => 'ro',
	default => 'Anonymous',
);

has email_mxcheck => (
	isa     => Int,
	is      => 'ro',
	default => 1,
);

has email_tldcheck => (
	isa     => Int,
	is      => 'ro',
	default => 1,
);

has notify_user => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has notify_author => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has notify_admin => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);


=head1 METHODS

=head2 base

Set up the base path, fetch the discussion details.

=cut

sub base : Chained( '/base' ) : PathPart( 'discussion' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $discussion_id ) = @_;

	# Stash the discussion
	$c->stash->{ discussion } = $c->model( 'DB::Discussion' )->find({
		id => $discussion_id,
	});

	unless ( $c->stash->{ discussion } ) {
		$c->flash->{ error_msg } = 'Discussion not found.';
		$c->response->redirect( $c->uri_for( '/' ) );
		$c->detach;
	}

	# Stash 'can_comment' and 'can_like' config settings
	$c->stash->{ can_comment } = $self->can_comment;
	$c->stash->{ can_like    } = $self->can_like;

	# Stash the controller name
	$c->stash->{ controller  } = 'Discussion';
}


=head2 index

People aren't supposed to be here...  bounce them back to the homepage.

/discussion

=cut

sub index : Path : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->response->redirect( $c->uri_for( '/' ) );
	$c->detach;
}


=head2 view_discussion

People aren't supposed to be here either, for now; redirect to parent resource.

/discussion/1

=cut

sub view_discussion : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$self->build_url_and_redirect( $c );
}


=head2 add_comment

Display the form to allow users to post a comment in reply to top-level content.

/discussion/2/add-comment	# Post a top-level comment in discussion 2

=cut

sub add_comment : Chained( 'base' ) : PathPart( 'add-comment' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $level = $self->can_comment;

	if ( $level eq 'User' and not $c->user_exists ) {
		# check for logged-in user
		$c->go( 'User', 'login' );
	}

	# Stash the item being replied to
	my $type = $c->stash->{ discussion }->resource_type;
	$c->stash->{ parent } = $c->model( 'DB::'.$type )->find({
		id => $c->stash->{ discussion }->resource_id,
	});

	# Find pseudonymous user details in cookie, if any, and stash them
	my $cookie = $c->request->cookies->{ comment_author_info };
	if ( $cookie ) {
		my %val = $cookie->value;
		$c->stash(
			comment_author_name  => $val{ comment_author_name  },
			comment_author_link  => $val{ comment_author_link  } || undef,
			comment_author_email => $val{ comment_author_email } || undef,
		);
	}
}


=head2 reply_to

Display the form to allow users to post a comment in reply to another comment.

/discussion/2/reply-to/4	# Reply to comment 4 in discussion 2

=cut

sub reply_to : Chained( 'base' ) : PathPart( 'reply-to' ) : Args( 1 ) {
	my ( $self, $c, $parent_id ) = @_;

	# Stash the comment being replied to
	$c->stash->{ parent } = $c->stash->{ discussion }->comments->find({
		id => $parent_id,
	});

	# Find pseudonymous user details in cookie, if any, and stash them
	my $cookie = $c->request->cookies->{ comment_author_info };
	if ( $cookie ) {
		my %val = $cookie->value;
		$c->stash(
			comment_author_name  => $val{ comment_author_name  },
			comment_author_link  => $val{ comment_author_link  } || undef,
			comment_author_email => $val{ comment_author_email } || undef,
		);
	}

	$c->stash->{ template } = 'discussion/add_comment.tt';
}


=head2 add_comment_do

Process the form when a user posts a comment.

/discussion/2/add-comment-do

=cut

sub add_comment_do : Chained( 'base' ) : PathPart( 'add-comment-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $level = $self->can_comment;

	if ( $level eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to post a comment.';
			$c->response->redirect( $c->request->referer );
			$c->detach;
		}
	}
	elsif ( $level eq 'Pseudonym' ) {
		unless ( $c->request->param( 'author_name' ) or $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must supply a name to post a comment.';
			$c->response->redirect( $c->request->referer );
			$c->detach;
		}
	}

	# Find/set the author type
	my $author_type = $c->request->param( 'author_type' ) || 'Anonymous';
	if ( $author_type eq 'Site User' ) {
		$author_type = 'Anonymous' unless $c->user_exists;
	}
	elsif ( $author_type eq 'Unverified' ) {
		$author_type = 'Anonymous' unless $c->request->param( 'author_name' );
	}

	my $result;
	$result = $self->recaptcha_result( $c ) unless $c->user_exists;

	if ( $c->user_exists or $result->{ is_valid } ) {
		# Save pseudonymous user details in cookie, if any
		my $author = {
			comment_author_name  => $c->request->param( 'author_name'  ),
		};
		$author->{ comment_author_link } = $c->request->param( 'author_link'  )
			if $c->request->param( 'author_link'  );
		$author->{ comment_author_email } = $c->request->param( 'author_email' )
			if $c->request->param( 'author_email' );
		if ( $author_type eq 'Unverified' ) {
			$c->response->cookies->{ comment_author_info } = {
				value => $author,
			};
		}

		# Filter the body text
		my $body = $c->request->param( 'body' );
		$body    = $c->model( 'FilterHTML' )->filter( $body );

		# Find the next available comment ID for this discussion thread
		my $next_id = $c->stash->{ discussion }->comments->get_column('id')->max;
		$next_id++;

		# Add the comment, send email notifications
		if ( $author_type eq 'Site User' ) {
			$c->stash->{ comment } = $c->stash->{ discussion }->comments->create({
				id           => $next_id,
				parent       => $c->request->param( 'parent_id' ) || undef,
				author_type  => 'Site User',
				author       => $c->user->id,
				title        => $c->request->param( 'title'     ) || undef,
				body         => $body,
			});
		}
		elsif ( $author_type eq 'Unverified' ) {
			$c->stash->{ comment } = $c->stash->{ discussion }->comments->create({
				id           => $next_id,
				parent       => $c->request->param( 'parent_id'    ) || undef,
				author_type  => 'Unverified',
				author_name  => $c->request->param( 'author_name'  ) || undef,
				author_email => $c->request->param( 'author_email' ) || undef,
				author_link  => $c->request->param( 'author_link'  ) || undef,
				title        => $c->request->param( 'title'        ) || undef,
				body         => $body,
			});
		}
		else {	# Anonymous
			$c->stash->{ comment } = $c->stash->{ discussion }->comments->create({
				id           => $next_id,
				parent       => $c->request->param( 'parent_id' ) || undef,
				author_type  => 'Anonymous',
				title        => $c->request->param( 'title'     ) || undef,
				body         => $body,
			});
		}

		# Update commented_on timestamp for forum posts
		if ( $c->stash->{ discussion}->resource_type eq 'ForumPost' ) {
			my $now = DateTime->now;
			my $post = $c->model( 'DB::ForumPost' )->find({
				id => $c->stash->{ discussion}->resource_id,
			});
			$post->update({
				commented_on => $now,
			});
		}

		# Send notication emails
		$self->send_emails( $c );
	}
	else {
		# Failed reCaptcha
		$c->flash->{ error_msg } = 'You did not pass the recaptcha test - please try again.';
	}

	# Bounce back to the discussion location
	$self->build_url_and_redirect( $c );
}


=head2 like_comment

Like (or unlike) a comment.

=cut

sub like_comment : Chained( 'base' ) : PathPart( 'like' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	my $level = $self->can_like;

	if ( $level eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to like a comment.';
			$c->response->redirect( $c->request->referer );
			$c->detach;
		}
	}

	# Get the comment
	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});

	my $ip_address = $c->request->address;

	# Find out if this user or IP address has already liked this comment
	if ( $c->user_exists and $comment->liked_by_user( $c->user->id ) ) {
		# Undo like by logged-in user
		$c->user->comments_like->search({
			comment => $comment->uid,
		})->delete;
	}
	elsif ( $comment->liked_by_anon( $ip_address ) and not $c->user_exists ) {
		# Undo like by anon user
		$c->model( 'DB::CommentLike' )->search({
			user       => undef,
			comment    => $comment->uid,
			ip_address => $ip_address,
		})->delete;
	}
	else {
		# No existing 'like' for this user/IP
		if ( $c->user_exists ) {
			# Set like by logged-in user
			$c->user->comments_like->create({
				comment    => $comment->uid,
				ip_address => $ip_address,
			});
		}
		else {
			# Set like by anon user
			$c->model( 'DB::CommentLike' )->create({
				comment    => $comment->uid,
				ip_address => $ip_address,
			});
		}
	}

	# Bounce back to the discussion location
	$c->stash->{ comment } = $comment;
	$self->build_url_and_redirect( $c );
}


=head2 hide_comment

Hide (or unhide) a comment.

=cut

sub hide_comment : Chained( 'base' ) : PathPart( 'hide' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	my $url = $self->build_url( $c );

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'hide a comment',
		role     => 'Comment Moderator',
		redirect => $url
	});

	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});

	if ( $comment->hidden ) {
		# Reveal the comment
		$comment->update({ hidden => 0 });
		$c->stash->{ comment } = $comment;
		$url = $self->build_url( $c );
		$c->flash->{ status_msg } = 'Comment un-hidden';
	}
	else {
		# Hide the comment
		$comment->update({ hidden => 1 });
		$c->flash->{ status_msg } = 'Comment hidden';
	}

	# Bounce back to the discussion location
	$self->build_url_and_redirect( $c, $url );
}


=head2 delete_comment

Delete a comment.

=cut

sub delete_comment : Chained( 'base' ) : PathPart( 'delete' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	my $url = $self->build_url( $c );

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'delete a comment',
		role     => 'Comment Moderator',
		redirect => $url
	});

	# Fetch the comment
	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});

	# Delete any child comments, then the comment itself
	$self->delete_comment_tree( $c, $comment_id );
	$comment->comments_like->delete;
	$comment->delete;
	$c->flash->{ status_msg } = 'Comment deleted';

	# Bounce back to the discussion location
	$self->build_url_and_redirect( $c, $url );
}


# ========== ( utility methods ) ==========

=head2 delete_comment_tree

Delete all of a comment's children.

=cut

sub delete_comment_tree : Private {
	my( $self, $c, $comment_id ) = @_;

	# Check for child comments
	my $comments = $c->stash->{ discussion }->comments->search({
		parent => $comment_id,
	});
	while ( my $comment = $comments->next ) {
		$self->delete_comment_tree( $c, $comment->id );
		$comment->comments_like->delete;
		$comment->delete;
	}
}


=head2 build_url

Build URL for stashed content (and comment, if any)

=cut

sub build_url : Private {
	my ( $self, $c ) = @_;

	my $discussion = $c->stash->{ discussion };
	my $comment    = $c->stash->{ comment    };

	my $resource = $c->model( 'DB::'.$discussion->resource_type )->find({
		id => $discussion->resource_id,
	});
	return unless $resource;

	my $url;
	if ( $discussion->resource_type eq 'BlogPost' ) {
		$url  = $c->uri_for( '/blog', $resource->posted->year, $resource->posted->month, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $discussion->resource_type eq 'ForumPost' ) {
		$url  = $c->uri_for( '/forums', $resource->forum->section->url_name, $resource->forum->url_name, $resource->id, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $discussion->resource_type eq 'NewsItem' ) {
		$url  = $c->uri_for( '/news', $resource->posted->year, $resource->posted->month, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $discussion->resource_type eq 'ShopItem' ) {
		$url  = $c->uri_for( '/shop', 'item', $resource->code );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $discussion->resource_type eq 'User' ) {
		$url  = $c->uri_for( '/user', $resource->username );
		$url .= '#comment-'. $comment->id if $comment;
	}
	return $url;
}


=head2 build_url_and_redirect

Build URL for stashed content (and comment) and redirect there

=cut

sub build_url_and_redirect : Private {
	my ( $self, $c, $url ) = @_;

	$url = $self->build_url( $c ) unless $url;
	$url = $c->uri_for( '/' )     unless $url;

	$c->response->redirect( $url );
	$c->detach;
}


=head2 send_emails

Send notification emails

=cut

sub send_emails : Private {
	my ( $self, $c ) = @_;

	my $comment  = $c->stash->{ comment };
	my $username = $comment->author_name || 'An anonymous user';
	$username = $comment->author->username if $comment->author;
	$username = $comment->author->display_name
		if $comment->author and $comment->author->display_name;

	my $parent;
	my $email;

	# If we're replying to a comment, notify the person who wrote it
	if ( $comment->parent and uc $self->notify_user eq 'YES' ) {
		# Send email notification to author of comment being replied to
		my $parent = $c->stash->{ discussion }->comments->find({
			id => $comment->parent,
		});

		# Get email address to reply to, skip if there isn't one
		my $email_valid = 0;
		if ( $parent->author_type eq 'Site User' ) {
			$email = $parent->author->email;
			$email_valid = 1;
		}
		elsif ( $parent->author_type eq 'Unverified' ) {
			$email = $parent->author_email;

			# Check the email address for validity
			$email_valid = Email::Valid->address(
				-address  => $email,
				-mxcheck  => $self->email_mxcheck,
				-tldcheck => $self->email_tldcheck,
			) if $email;
		}

		if ( $email_valid ) {
			# Send out the email
			my $site_name   = $c->config->{ site_name };
			my $site_url    = $c->uri_for( '/' );
			my $comment_url = $self->build_url( $c );
			my $reply_text  = $comment->body;
			my $body = <<EOT;
$username just replied to your comment on $site_name.  They said:

	$reply_text


Click here to view online and reply:
$comment_url

--
$site_name
$site_url
EOT
			$c->stash->{ email_data } = {
				from    => $site_name .' <'. $c->config->{ site_email } .'>',
				to      => $email,
				subject => 'Reply received on '. $site_name,
				body    => $body,
			};
			$c->forward( $c->view( 'Email' ) );
		}
	}

	# Notify author of top-level content (blog post, etc)
	if ( uc $self->notify_author eq 'YES' ) {
		my $email2;
		my $resource_type = $comment->discussion->resource_type;
		my $content_type;
		if ( $resource_type eq 'BlogPost'  ) {
			my $post = $c->model('DB::BlogPost')->find({
				id => $comment->discussion->resource_id,
			});
			$content_type = 'blog post';
			$email2 = $post->author->email;
		}
		if ( $resource_type eq 'ForumPost'  ) {
			my $post = $c->model('DB::ForumPost')->find({
				id => $comment->discussion->resource_id,
			});
			$content_type = 'forum post';
			$email2 = $post->author->email;
		}
		# TODO: other resource types?

		# Check to make sure that we have an email address, and that we
		# didn't already email it in the 'reply to comment' block above
		if ( $email2 and $email and $email2 ne $email ) {
			$email = $email2;
			# Send out the email
			my $site_name   = $c->config->{ site_name };
			my $site_url    = $c->uri_for( '/' );
			my $comment_url = $self->build_url( $c );
			my $reply_text  = $comment->body;
			my $body = <<EOT;
$username just commented on your $content_type on $site_name.  They said:

	$reply_text


Click here to view online and reply:
$comment_url

--
$site_name
$site_url
EOT
			$c->stash->{ email_data } = {
				from    => $site_name .' <'. $c->config->{ site_email } .'>',
				to      => $email,
				subject => 'Reply received on '. $site_name,
				body    => $body,
			};
			$c->forward( $c->view( 'Email' ) );
		}
	}

	# Notify site admin
	if ( uc $self->notify_admin eq 'YES' ) {
		# Skip this notification if one of the above has already gone to same address
		return unless $email;
		return if $email eq $c->config->{ site_email };

		# Get site admin email address
		$email = $c->config->{ site_email };

		# Send out the email
		my $site_name   = $c->config->{ site_name };
		my $site_url    = $c->uri_for( '/' );
		my $comment_url = $self->build_url( $c );
		my $reply_text  = $comment->body;
		my $body = <<EOT;
$username just posted a comment on $site_name.  They said:

	$reply_text


Click here to view online and reply:
$comment_url

--
$site_name
$site_url
EOT
		$c->stash->{ email_data } = {
			from    => $site_name .' <'. $c->config->{ site_email } .'>',
			to      => $email,
			subject => 'Comment posted on '. $site_name,
			body    => $body,
		};
		$c->forward( $c->view( 'Email' ) );
	}
}


# ========== ( search method used by site-wide search feature ) ==========

=head2 search

Search the discussions.

=cut

sub search {
	my ( $self, $c ) = @_;

	return unless my $search = $c->request->param( 'search' );

	my @results = $c->model( 'DB::Comment' )->search({
		-and => [
			posted    => { '<=' => \'current_timestamp' },
			-or => [
				title => { 'LIKE', '%'.$search.'%'},
				body  => { 'LIKE', '%'.$search.'%'},
			],
		],
	})->all;

	my $comments = [];
	foreach my $result ( @results ) {
		# Pull out the matching search term and its immediate context
		my $match = '';
		if ( $result->title and $result->title =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		# Tidy up and mark the truncation
		unless ( ( $result->title and $match eq $result->title )
				or $match eq $result->body ) {
			$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
			$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
		}
		if ( $result->title and $match eq $result->title ) {
			$match = substr $result->body, 0, 100;
			$match =~ s/\s\S+\s?$/ .../;
		}
		# Add the match string to the result
		$result->{ match } = $match;

		# Construct the appropriate link and add to result
		$c->stash->{ discussion } = $result->discussion;
		$c->stash->{ comment    } = $result;

		$result->{ link } = $self->build_url( $c );

		# Don't stash this result if the parent resource is missing or hidden
		next unless $result->{ link };

		# Push the result onto the results array
		push @$comments, $result;
	}

	$c->stash->{ discussion_results } = $comments;
	return $comments;
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
