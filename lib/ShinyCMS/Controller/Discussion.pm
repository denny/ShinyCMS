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


has akismet_flagged => (
	isa     => Str,
	is      => 'ro',
	default => 'Reject',
);

has akismet_inconclusive => (
	isa     => Str,
	is      => 'ro',
	default => 'Reject',
);

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

has use_akismet_for => (
	isa     => Str,
	is      => 'ro',
	default => 'None',
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

	# Check whether discussion is frozen
	if ( $c->stash->{ discussion }->frozen ) {
		$c->flash->{ error_msg } = 'Discussion is frozen; no new comments allowed.';
		$self->build_url_and_redirect( $c );
	}

	# Check whether only logged-in users can comment, and enforce it
	$c->go( 'User', 'login' ) if $self->can_comment eq 'User' and not $c->user_exists;

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

	# Stash the item being replied to
	my $type = $c->stash->{ discussion }->resource_type;
	$c->stash->{ parent } = $c->model( 'DB::'.$type )->find({
		id => $c->stash->{ discussion }->resource_id,
	});
}


=head2 reply_to

Display the form to allow users to post a comment in reply to another comment.

/discussion/2/reply-to/4	# Reply to comment 4 in discussion 2

=cut

sub reply_to : Chained( 'base' ) : PathPart( 'reply-to' ) : Args( 1 ) {
	my ( $self, $c, $parent_id ) = @_;

	# Check whether discussion is frozen
	if ( $c->stash->{ discussion }->frozen ) {
		$c->flash->{ error_msg } = 'Discussion is frozen; no new comments allowed.';
		$self->build_url_and_redirect( $c );
	}

	# Check whether only logged-in users can comment, and enforce it
	$c->go( 'User', 'login' ) if $self->can_comment eq 'User' and not $c->user_exists;

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

	# Stash the comment being replied to
	$c->stash->{ parent } = $c->stash->{ discussion }->comments->find({
		id => $parent_id,
	});

	$c->stash->{ template } = 'discussion/add_comment.tt';
}


=head2 save_comment

Process the form when a user posts a comment.

/discussion/2/save-comment

=cut

sub save_comment : Chained( 'base' ) : PathPart( 'save-comment' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check whether discussion is frozen
	if ( $c->stash->{ discussion }->frozen ) {
		$c->flash->{ error_msg } = 'Discussion is frozen; no new comments allowed.';
		$self->build_url_and_redirect( $c );
	}

	# Check whether current user is allowed to post a comment, bounce if not
	if ( $self->can_comment eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to post a comment.';
			$c->response->redirect( $c->uri_for( '/user/login' ) );
			$c->detach;
		}
	}
	elsif ( $self->can_comment eq 'Pseudonym' ) {
		unless ( $c->request->param( 'author_name' ) or $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must supply a name to post a comment.';
			$self->build_url_and_redirect( $c, $c->request->referer );
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

	unless ( $c->user_exists ) {
		my $recaptcha_result;
		$recaptcha_result = $self->recaptcha_result( $c );

		unless ( $recaptcha_result->{ is_valid } ) {
			# TODO: stash form content and reinstate it at other end of redirect
			$c->flash->{ error_msg } = 'You did not pass the reCaptcha test - please try again.';
			$self->build_url_and_redirect( $c, $c->request->referer );
		}
	}

	# TODO: use the same terms for these concepts everywhere, good lord.
	my $author_level  = 1; # 'Anonymous'
	$author_level     = 2 if $author_type eq 'Unverified';
	$author_level     = 3 if $author_type eq 'Site User';
	$author_level     = 4 if $c->user_exists and $c->user->is_admin;
	my $akismet_level = {
		'None'      => 0,
		'Anonymous' => 1,
		'Pseudonym' => 2,
		'Logged-in' => 3,
		'Admin'     => 4
	};

	my $flagged_by_akismet;
	if ( $author_level <= $akismet_level->{ $self->use_akismet_for } ) {
		my $result = $self->akismet_result( $c );

		if ( ( $result == 1     and uc $self->akismet_flagged      eq 'REJECT' ) or
			 ( $result == undef and uc $self->akismet_inconclusive eq 'REJECT' ) ) {
			die 'COMMENT REJECTED';
		}
		elsif ( ( $result == 1     and uc $self->akismet_flagged      eq 'FLAG' ) or
				( $result == undef and uc $self->akismet_inconclusive eq 'FLAG' ) ) {
			$flagged_by_akismet = 1;
		}
		else {
			$flagged_by_akismet = 0;
		}
	}

	# Save pseudonymous user details in cookie, if any
	if ( $author_type eq 'Unverified' ) {
		my $author = {
			comment_author_name => $c->request->param( 'author_name' ),
		};
		$author->{ comment_author_link } = $c->request->param( 'author_link' )
			if $c->request->param( 'author_link' );
		$author->{ comment_author_email } = $c->request->param( 'author_email' )
			if $c->request->param( 'author_email' );
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
			spam         => $flagged_by_akismet,
		});
	}
	elsif ( $author_type eq 'Unverified' ) {
		$c->stash->{ comment } = $c->stash->{ discussion }->comments->create({
			id           => $next_id,
			parent       => $c->request->param( 'parent_id'    ) || undef,
			author_type  => 'Unverified',
			author_name  => $c->request->param( 'author_name'  ),
			author_email => $c->request->param( 'author_email' ) || undef,
			author_link  => $c->request->param( 'author_link'  ) || undef,
			title        => $c->request->param( 'title'        ) || undef,
			body         => $body,
			spam         => $flagged_by_akismet,
		});
	}
	else {	# Anonymous
		$c->stash->{ comment } = $c->stash->{ discussion }->comments->create({
			id           => $next_id,
			parent       => $c->request->param( 'parent_id' ) || undef,
			author_type  => 'Anonymous',
			title        => $c->request->param( 'title'     ) || undef,
			body         => $body,
			spam         => $flagged_by_akismet,
		});
	}

	# Update commented_on timestamp for forum posts
	if ( $c->stash->{ discussion}->resource_type eq 'ForumPost'
			and not $flagged_by_akismet ) {
		$c->model( 'DB::ForumPost' )->find({
			id => $c->stash->{ discussion}->resource_id,
		})->update({
			commented_on => \'current_timestamp',
		});
	}

	# Send notification emails
	$self->send_emails( $c, $flagged_by_akismet );

	# Bounce back to the discussion location
	$self->build_url_and_redirect( $c );
}


=head2 like_comment

Like (or unlike) a comment.

=cut

sub like_comment : Chained( 'base' ) : PathPart( 'like' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	if ( $self->can_like eq 'User' ) {
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


=head2 mark_comment_as_spam

Explicitly set a comment's spam flag to true

TODO: feed the comment to Akismet as 'spam', to improve their model

=cut

sub mark_comment_as_spam : Chained( 'base' ) : PathPart( 'spam' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	$c->stash->{ comment } = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});

	my $url = $self->build_url( $c );

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'mark a comment as spam',
		role     => 'Discussion Admin',
		redirect => $url
	});

	my $prev   = $c->stash->{ comment }->mark_as_spam;
	my $status = 'not set';
	$status    = 'not spam' if $prev == 0;
	$status    = 'spam'     if $prev == 1;
	$c->flash->{ status_msg } = "Comment marked as 'spam' (previous status: $status)";

	$self->build_url_and_redirect( $c, $url );
}


=head2 mark_comment_as_not_spam

Set a comment's spam flag to false

TODO: feed the comment to Akismet as 'ham', to improve their model

=cut

sub mark_comment_as_not_spam : Chained( 'base' ) : PathPart( 'ham' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;

	my $url = $self->build_url( $c );

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'mark a comment as not spam',
		role     => 'Discussion Admin',
		redirect => $url
	});

	$c->stash->{ comment } = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});

	my $prev   = $c->stash->{ comment }->mark_as_not_spam;
	my $status = 'not set';
	$status    = 'not spam' if $prev == 0;
	$status    = 'spam'     if $prev == 1;
	$c->flash->{ status_msg } = "Comment marked as 'not spam' (previous status: $status)";

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


=head2 freeze_discussion

Freeze the discussion (no new comments allowed)

=cut

sub freeze_discussion : Chained( 'base' ) : PathPart( 'freeze' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $url = $self->build_url( $c );

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'freeze a discussion',
		role     => 'Discussion Admin',
		redirect => $url
	});

	$c->stash->{ discussion }->update({ frozen => 1 });
	$c->flash->{ status_msg } = 'Discussion frozen';

	# Bounce back to the discussion location
	$self->build_url_and_redirect( $c, $url );
}


=head2 unfreeze_discussion

Unfreeze the discussion (new comments allowed)

=cut

sub unfreeze_discussion : Chained( 'base' ) : PathPart( 'unfreeze' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $url = $self->build_url( $c );

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'unfreeze a discussion',
		role     => 'Discussion Admin',
		redirect => $url
	});

	$c->stash->{ discussion }->update({ frozen => 0 });
	$c->flash->{ status_msg } = 'Discussion unfrozen';

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

	# Check the primary parent resource (blog post/shop item/etc) still exists
	my $resource_type = $c->stash->{ discussion }->resource_type;
	my $resource = $c->model( 'DB::'.$resource_type )->find({
		id => $c->stash->{ discussion }->resource_id,
	});
	return unless $resource;

	my $comment = $c->stash->{ comment };
	my $url;
	if ( $resource_type eq 'BlogPost' ) {
		$url  = $c->uri_for( '/blog', $resource->posted->year, $resource->posted->month, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $resource_type eq 'ForumPost' ) {
		$url  = $c->uri_for( '/forums', $resource->forum->section->url_name, $resource->forum->url_name, $resource->id, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $resource_type eq 'NewsItem' ) {
		$url  = $c->uri_for( '/news', $resource->posted->year, $resource->posted->month, $resource->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $resource_type eq 'ShopItem' ) {
		$url  = $c->uri_for( '/shop', 'item', $resource->code );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $resource_type eq 'User' ) {
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

	my $comment = $c->stash->{ comment };

	# If we're replying to a comment, notify the person who wrote it
	my $email1;
	if ( $comment->parent and uc $self->notify_user eq 'YES' and not $comment->spam ) {
		$email1 = $self->get_comment_author_email_address( $c, $comment->parent );
		$self->send_email_to_parent_author( $c, $comment ) if $email1;
	}

	# Notify author of the top-level content (blog post/news post/etc)
	# (unless they're also the author of the parent comment and we already emailed them!)
	my $email2;
	if ( uc $self->notify_author eq 'YES' and not $comment->spam ) {
		$email2 = $self->get_top_level_email_address( $c, $comment->discussion );
		$self->send_email_to_top_level_author( $c, $comment )
									unless ( $email1 and $email1 eq $email2 );
	}

	# Notify site admin
	if ( uc $self->notify_admin eq 'YES' ) {
		# Get site admin email address
		my $email3 = $c->config->{ site_email };

		# Skip this notification if one of the above has already gone to same address
		return if $email1 and $email1 eq $email3;
		return if $email2 and $email2 eq $email3;

		$self->send_email_to_site_admin( $c, $comment );
	}
}


=head2 get_author_name

Get the attribution string (name/username/anon) for a comment

=cut

sub get_author_name : Private {
	my ( $self, $c, $comment ) = @_;

	if ( $comment->author ) {
		return $comment->author->display_name if $comment->author->display_name;
		return $comment->author->username;
	}
	return $comment->author_name if $comment->author_name;
	return 'An anonymous user';
}


=head2 get_comment_author_email_address

Find the email address of the person who posted a comment (if we have it)

=cut

sub get_comment_author_email_address : Private {
	my ( $self, $c, $comment ) = @_;

	return $comment->author->email if $comment->author; # Site User

	return unless $comment->author_type eq 'Unverified';

	my $email = $comment->author_email;
	return unless $email;

	my $valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => $self->email_mxcheck,
		-tldcheck => $self->email_tldcheck,
	);
	return $email if $valid;
}


=head2 send_email_to_parent_author

Send notification email to person who posted the comment being replied to

=cut

sub send_email_to_parent_author : Private {
	my ( $self, $c, $comment ) = @_;

	return unless $comment->parent;

	my $email = $self->get_comment_author_email_address( $c, $comment->parent );
	return unless $email;

	my $site_name   = $c->config->{ site_name };
	my $site_url    = $c->uri_for( '/' );
	my $username    = $self->get_author_name( $c, $comment );
	my $comment_url = $self->build_url( $c );
	my $reply_text  = $comment->body;
	my $body = <<EOT;
$username just replied to your comment on $site_name. They said:

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
		subject => "Your comment on $site_name has a new reply",
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 get_content_type

Pass in the resource_type column from a discussion, get back a string (suitable
for use in e.g. a notification email) describing that piece of content.

=cut

sub get_content_type : Private {
	my ( $self, $c, $discussion ) = @_;

	my $content_type = $discussion->resource_type;
	$content_type =~ s{(a..z)(A..Z)}{$1 $2}g;
	return lc $content_type;
}


=head2 get_top_level_email_address

Find the email address of the person who posted the top-level content
(blog post/forum post/etc) that a discussion is attached to.

=cut

sub get_top_level_email_address : Private {
	my ( $self, $c, $discussion ) = @_;

	my $resource_type = $discussion->resource_type;
	my $resource_id   = $discussion->resource_id;

	my $resource = $c->model( "DB::$resource_type" )->find({ id => $resource_id });

	# TODO: handle any cases where the relationship name isn't 'author'
	return $resource->author->email;
}


=head2 send_email_to_top_level_author

Send notification email to person who posted the top-level content that the
discussion is attached to.

=cut

sub send_email_to_top_level_author : Private {
	my ( $self, $c, $comment ) = @_;

	my $site_name    = $c->config->{ site_name };
	my $site_url     = $c->uri_for( '/' );
	my $username     = $self->get_author_name( $c, $comment );
	my $reply_text   = $comment->body;
	my $content_type = $self->get_content_type( $c, $comment->discussion );
	my $comment_url  = $self->build_url( $c );
	my $email = $self->get_top_level_email_address( $c, $comment->discussion );
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
		subject => "Your $content_type on $site_name has a new comment",
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 send_email_to_site_admin

Send comment notification email to the site admin.

=cut

sub send_email_to_site_admin : Private {
	my ( $self, $c, $comment ) = @_;

	# Add spam flag to subject and ham link to body if the comment is flagged as spam
	my $spam_title = '';
	my $spam_block = '';
	if ( $comment->spam ) {
		my $ham_link = $c->uri_for( '/discussion', $comment->discussion->id, 'ham', $comment->id );
		$spam_title = '[SPAM?] ';
		$spam_block = <<EOT;
This comment was flagged as spam by Akismet. It is currently not visible on
your site, and it may be deleted automatically. If the comment is not spam,
you should click this link to remove the spam flag:
$ham_link


EOT
	}

	my $site_name   = $c->config->{ site_name };
	my $site_url    = $c->uri_for( '/' );
	my $username    = $self->get_author_name( $c, $comment );
	my $comment_url = $self->build_url( $c );
	my $reply_text  = $comment->body;
	my $body        = $spam_block;
	$body          .= <<EOT;
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
		to      => $c->config->{ site_email },
		subject => $spam_title .'Comment posted on '. $site_name,
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
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
