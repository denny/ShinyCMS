package ShinyCMS::Controller::Discussion;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Discussion

=head1 DESCRIPTION

Controller for ShinyCMS discussion threads.

=head1 METHODS

=cut


=head2 base

Set up the base path, fetch the discussion details.

=cut

sub base : Chained( '/' ) : PathPart( 'discussion' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $discussion_id ) = @_;
	
	# Stash the discussion
	$c->stash->{ discussion } = $c->model( 'DB::Discussion' )->find({
		id => $discussion_id,
	});
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = ShinyCMS->config->{ upload_dir };
	
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
	
	$c->forward( 'Root', 'build_menu' );
	
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		$c->stash->{ parent } = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
	}
	
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
	
	$c->forward( 'Root', 'build_menu' );
	
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
	
	# Add the comment
	my $comment;
	if ( $author_type eq 'Site User' ) {
		$comment = $c->stash->{ discussion }->comments->create({
			id           => $next_id,
			parent       => $c->request->param( 'parent_id' ) || undef,
			author_type  => 'Site User',
			author       => $c->user->id,
			title        => $c->request->param( 'title'     ) || undef,
			body         => $c->request->param( 'body'      ) || undef,
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
			body         => $c->request->param( 'body'         ) || undef,
		});
	}
	else {	# Anonymous
		$comment = $c->stash->{ discussion }->comments->create({
			id           => $next_id,
			parent       => $c->request->param( 'parent_id' ) || undef,
			author_type  => 'Anonymous',
			title        => $c->request->param( 'title'     ) || undef,
			body         => $c->request->param( 'body'      ) || undef,
		});
	}
	
	# Bounce back to the discussion location
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title );
		$url .= '#comment-'. $comment->id;
	}
	$c->response->redirect( $url );
}


=head2 delete_comment

Delete a comment.

=cut

sub delete_comment : Chained( 'base' ) : PathPart( 'delete' ) : Args( 1 ) {
	my ( $self, $c, $comment_id ) = @_;
	
	my $comment = $c->stash->{ discussion }->comments->find({
		id => $comment_id,
	});
	
	# TODO: Delete children?  Or re-parent?
	
	# Delete comment
	$comment->delete;
	
	# Bounce back to the discussion location
	my $url = '/';
	if ( $c->stash->{ discussion }->resource_type eq 'BlogPost' ) {
		my $post = $c->model( 'DB::BlogPost' )->find({
			id => $c->stash->{ discussion }->resource_id,
		});
		$url  = $c->uri_for( '/blog', $post->posted->year, $post->posted->month, $post->url_title );
		$url .= '#comment-'. $comment->id;
	}
	$c->response->redirect( $url );
}



=head1 AUTHOR

Denny de la Haye <2010@denny.me>

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

