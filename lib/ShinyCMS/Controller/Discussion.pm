package ShinyCMS::Controller::Discussion;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use Captcha::reCAPTCHA;
	

=head1 NAME

ShinyCMS::Controller::Discussion

=head1 DESCRIPTION

Controller for ShinyCMS discussion threads.

=head1 METHODS

=cut


=head2 base

Set up the base path, fetch the discussion details.

=cut

sub base : Chained( '/base' ) : PathPart( 'discussion' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $discussion_id ) = @_;
	
	# Stash the discussion
	$c->stash->{ discussion } = $c->model( 'DB::Discussion' )->find({
		id => $discussion_id,
	});

	# Stash the controller name
	$c->stash->{ controller } = 'Discussion';
}


=head2 index

People aren't supposed to be here...  bounce them back to the homepage.

=cut

sub index : Path : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->response->redirect( '/' );
}


=head2 add_comment

Display the form to allow users to post comments.

=cut

sub add_comment : Chained( 'base' ) : PathPart( 'add-comment' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $level = $c->config->{ Discussion }->{ can_comment };
	
	if ( $level eq 'User' and not $c->user_exists ) {
		# check for logged-in user
		$c->go( 'User', 'login' );
	}
	
	$c->forward( 'Root', 'build_menu' );
	
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

Display the form to allow users to post comments in reply to other comments.

=cut

sub reply_to : Chained( 'base' ) : PathPart( 'reply-to' ) : Args( 1 ) {
	my ( $self, $c, $parent_id ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
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

=cut

sub add_comment_do : Chained( 'base' ) : PathPart( 'add-comment-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $level = $c->config->{ Discussion }->{ can_comment };
	
	if ( $level eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->stash->{ error_msg } = 'You must be logged in to post a comment.';
			$c->response->redirect( $c->request->referer );
			return;
		}
	}
	elsif ( $level eq 'Pseudonym' ) {
		unless ( $c->request->param( 'author_name' ) or $c->user_exists ) {
			$c->stash->{ error_msg } = 'You must supply a name to post a comment.';
			$c->response->redirect( $c->request->referer );
			return;
		}
	}
	
	# Find the next available comment ID for this discussion thread
	my $next_id = $c->stash->{ discussion }->comments->get_column('id')->max;
	$next_id++;
	
	# Find/set the author type
	my $author_type = $c->request->param( 'author_type' ) || 'Anonymous';
	if ( $author_type eq 'Site User' ) {
		$author_type = 'Anonymous' unless $c->user_exists;
	}
	elsif ( $author_type eq 'Unverified' ) {
		$author_type = 'Anonymous' unless $c->request->param( 'author_name' );
	}
	
	my $result;
	unless ( $c->user_exists ) {
		# Check if they passed the reCaptcha test
		my $rc = Captcha::reCAPTCHA->new;
		
		$result = $rc->check_answer(
			$c->stash->{ 'recaptcha_private_key' },
			$c->request->address,
			$c->request->param( 'recaptcha_challenge_field' ),
			$c->request->param( 'recaptcha_response_field'  ),
		);
	}
	
	my $comment;
	if ( $c->user_exists or $result->{ is_valid } ) {
		# Save pseudonymous user details in cookie, if any
		if ( $author_type eq 'Unverified' ) {
			$c->response->cookies->{ comment_author_info } = {
				value => {
					comment_author_name  => $c->request->param( 'author_name'  ),
					comment_author_link  => $c->request->param( 'author_link'  ) || undef,
					comment_author_email => $c->request->param( 'author_email' ) || undef,
				},
			};
		}
		
		# Filter the body text
		my $body = $c->request->param( 'body' );
		$body    = $c->model( 'FilterHTML' )->filter( $body );
		
		# Add the comment
		if ( $author_type eq 'Site User' ) {
			$comment = $c->stash->{ discussion }->comments->create({
				id           => $next_id,
				parent       => $c->request->param( 'parent_id' ) || undef,
				author_type  => 'Site User',
				author       => $c->user->id,
				title        => $c->request->param( 'title'     ) || undef,
				body         => $body,
			});
		}
		elsif ( $author_type eq 'Unverified' ) {
			$comment = $c->stash->{ discussion }->comments->create({
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
			$comment = $c->stash->{ discussion }->comments->create({
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
	}
	else {
		# Failed reCaptcha
		$c->flash->{ error_msg } = 'You did not enter the correct two words.';
	}
	
	# Bounce back to the discussion location
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ForumPost' ) {
		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/forums', $post->forum->section->url_name, $post->forum->url_name, $post->id, $post->url_title );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ShopItem' ) {
		my $item = $c->model( 'DB::ShopItem' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/shop', 'item', $item->id );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'User' ) {
		my $user = $c->model( 'DB::User' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/user', $user->username );
		$url .= '#comment-'. $comment->id if $comment;
	}
	$c->response->redirect( $url );
}


=head2 like_comment

Like (or unlike) a comment.

=cut

sub like_comment : Chained( 'base' ) : PathPart( 'like' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;
	
	my $level = $c->config->{ Discussion }->{ can_like };
	
	if ( $level eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to like a comment.';
			$c->response->redirect( $c->request->referer );
			return;
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
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title ) .'#comment-'. $comment->id;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ForumPost' ) {
		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/forums', $post->forum->section->url_name, $post->forum->url_name, $post->id, $post->url_title ) .'#comment-'. $comment->id;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ShopItem' ) {
		my $item = $c->model( 'DB::ShopItem' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/shop', 'item', $item->id );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'User' ) {
		my $user = $c->model( 'DB::User' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/user', $user->username );
		$url .= '#comment-'. $comment->id if $comment;
	}
	$c->response->redirect( $url );
}


=head2 hide_comment

Hide (or unhide) a comment.

=cut

sub hide_comment : Chained( 'base' ) : PathPart( 'hide' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'hide a comment', 
		role     => 'Comment Moderator',
		# TODO: redirect => 'parent resource'
	});
	
	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});
	
	if ( $comment->hidden eq 'YES' ) {
		# Reveal the comment
		$comment->update({ hidden => undef });
	}
	else {
		# Hide the comment
		$comment->update({ hidden => 'YES' });
	}
	
	# Bounce back to the discussion location
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title ) .'#comment-'. $comment->id;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ForumPost' ) {
		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/forums', $post->forum->section->url_name, $post->forum->url_name, $post->id, $post->url_title ) .'#comment-'. $comment->id;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ShopItem' ) {
		my $item = $c->model( 'DB::ShopItem' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/shop', 'item', $item->id );
		$url .= '#comment-'. $comment->id if $comment;
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'User' ) {
		my $user = $c->model( 'DB::User' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/user', $user->username );
		$url .= '#comment-'. $comment->id if $comment;
	}
	$c->response->redirect( $url );
}


=head2 delete_comment

Delete a comment.

=cut

sub delete_comment : Chained( 'base' ) : PathPart( 'delete' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'delete a comment', 
		role     => 'Comment Moderator',
		# TODO: redirect => 'parent resource'
	});
	
	# Fetch the comment
	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});
	
	# Delete any child comments, then the comment itself
	$self->delete_comment_tree( $c, $comment_id );
	$comment->delete;
	
	# Bounce back to the discussion location
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title );
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ForumPost' ) {
		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/forums', $post->forum->section->url_name, $post->forum->url_name, $post->id, $post->url_title );
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'ShopItem' ) {
		my $item = $c->model( 'DB::ShopItem' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/shop', 'item', $item->id );
	}
	elsif ( $c->stash->{ discussion }->resource_type eq 'User' ) {
		my $user = $c->model( 'DB::User' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/user', $user->username );
	}
	$c->response->redirect( $url );
}


=head2 delete_comment_tree

Delete all of a comment's children.

=cut

sub delete_comment_tree {
	my( $self, $c, $comment_id ) = @_;
	
	# Check for child comments
	my $comments = $c->stash->{ discussion }->comments->search({
		parent => $comment_id,
	});
	while ( my $comment = $comments->next ) {
		$self->delete_comment_tree( $c, $comment->id );
		$comments->delete;
	}
}

=head2 search

Search the discussions.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $comments = [];
		my @results = $c->model( 'DB::Comment' )->search({
			-and => [
				posted    => { '<=' => \'current_timestamp' },
				-or => [
					title => { 'LIKE', '%'.$search.'%'},
					body  => { 'LIKE', '%'.$search.'%'},
				],
			],
		});
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
			my $link;
			if ( $result->discussion->resource_type eq 'ForumPost' ) {
				my $post = $c->model( 'DB::ForumPost' )->find({
					id => $result->discussion->resource_id,
				});
				$link = $c->uri_for(
					'/forums',
					$post->forum->section->url_name,
					$post->forum->url_name,
					$post->id,
					$post->url_title,
				);
				$link .= '#comment-'. $result->id;
			}
			elsif ( $result->discussion->resource_type eq 'BlogPost' ) {
				my $post = $c->model( 'DB::BlogPost' )->find({
					id => $result->discussion->resource_id,
				});
				$link = $c->uri_for(
					'/blog',
					$post->posted->year,
					$post->posted->month,
					$post->url_title,
				);
				$link .= '#comment-'. $result->id;
			}
			elsif ( $result->discussion->resource_type eq 'NewsItem' ) {
				my $post = $c->model( 'DB::NewsItem' )->find({
					id => $result->discussion->resource_id,
				});
				$link = $c->uri_for(
					'/news',
					$post->posted->year,
					$post->posted->month,
					$post->url_title,
				);
				$link .= '#comment-'. $result->id;
			}
			elsif ( $result->discussion->resource_type eq 'ShopItem' ) {
				my $item = $c->model( 'DB::ShopItem' )->find({
					id => $result->discussion->resource_id,
				});
				$link = $c->uri_for(
					'/shop',
					'item',
					$item->url_title,
				);
				$link .= '#comment-'. $result->id;
			}
			elsif ( $result->discussion->resource_type eq 'User' ) {
				my $user = $c->model( 'DB::User' )->find({
					id => $result->discussion->resource_id,
				});
				$link = $c->uri_for(
					'/user',
					$user->username,
				);
				$link .= '#comment-'. $result->id;
			}
			$result->{ link } = $link;
			
			# Push the result onto the results array
			push @$comments, $result;
		}
		$c->stash->{ discussion_results } = $comments;
	}
}


=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

