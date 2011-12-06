package ShinyCMS::Controller::Forums;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Forums

=head1 DESCRIPTION

Controller for ShinyCMS forums.

=head1 METHODS

=cut


=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/' ) : PathPart( 'forums' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the current date
	$c->stash->{ now } = DateTime->now;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Forums';
}


=head2 get_posts

Get a page's worth of posts (excludes sticky posts)

=cut

sub get_posts {
	my ( $self, $c, $section, $forum, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 20;
	
	my @posts = $forum->forum_posts->search(
		{
			posted        => { '<=' => \'current_timestamp' },
			display_order => undef,
		},
		{
			order_by => [ { -desc => 'commented_on' }, { -desc => 'posted' } ],
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = [];
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 get_sticky_posts

Get a page's worth of sticky posts

=cut

sub get_sticky_posts {
	my ( $self, $c, $section, $forum, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 20;
	
	my @posts = $forum->forum_posts->search(
		{
			posted        => { '<=' => \'current_timestamp' },
			display_order => { '!=' => undef },
		},
		{
			order_by => 'display_order',
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = [];
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 get_post

=cut

sub get_post {
	my ( $self, $c, $post_id ) = @_;
	
	return $c->model( 'DB::ForumPost' )->find({
		id => $post_id,
	});
}


=head2 get_tags

Get the tags for a post

=cut

sub get_tags {
	my ( $self, $c, $post_id ) = @_;
	
	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $post_id,
		resource_type => 'ForumPost',
	});
	
	return $tagset->tag_list if $tagset;
	return;
}


=head2 get_tagged_posts

Get a page's worth of posts with a particular tag

=cut

sub get_tagged_posts {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 20;
	
	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'ForumPost';
		push @tagged, $tagset->get_column( 'resource_id' ),
	}
	
	my @posts = $c->model( 'DB::ForumPost' )->search(
		{
			id       => { 'in' => \@tagged },
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 get_posts_by_author

Get a page's worth of posts by a particular author

=cut

sub get_posts_by_author {
	my ( $self, $c, $username, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 20;
	
	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});
	
	my @posts = $c->model( 'DB::ForumPost' )->search(
		{
			author   => $author->id,
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	
	return $tagged_posts;
}


=head2 view_tag

Display a page of forum posts with a particular tag.

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->go( 'view_recent' ) unless $tag;
	
	# TODO: Make pagination work
	$page  ||= 1;
	$count ||= $c->config->{ Forums }->{ posts_per_page };
	
	my $posts = $self->get_tagged_posts( $c, $tag, $page, $count );
	
	$c->stash->{ tag        } = $tag;
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ forum_posts } = $posts;
	
	$c->stash->{ template   } = 'forums/view_forum.tt';
}


=head2 view_forums

Display all sections and forums.

=cut

sub view_forums : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	#my @sections = $c->model( 'DB::ForumSection' )->all;
	my @sections = $c->model( 'DB::ForumSection' )->search(
		{},
		{
			order_by => 'display_order',
		},
	);
	
	$c->stash->{ forum_sections } = \@sections;
}


=head2 view_section

Display the list of forums in a specified section.

=cut

sub view_section : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $section ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ section } = $c->model( 'DB::ForumSection' )->find({
		url_name => $section,
	});
	my @forums = $c->stash->{ section }->sorted_forums;
	
	$c->stash->{ forum_sections } = \@forums;
}


=head2 stash_forum

Stash details of a forum

=cut

sub stash_forum {
	my ( $self, $c, $section_name, $forum_name ) = @_;
	
	$c->stash->{ section } = $c->model( 'DB::ForumSection' )->find({
		url_name => $section_name,
	});
	$c->stash->{ forum } = $c->stash->{ section }->forums->find({
		url_name => $forum_name,
	});
}

	
=head2 view_forum

Display first page of posts in a specified forum.

=cut

sub view_forum : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $section_name, $forum_name ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$self->stash_forum( $c, $section_name, $forum_name );
	
	my $post_count = $c->config->{ Forums }->{ posts_per_page };
	
	my $forum_posts  = $self->get_posts( 
		$c, $c->stash->{ section }, $c->stash->{ forum }, 1, $post_count,
	);
	my $sticky_posts = $self->get_sticky_posts(
		$c, $c->stash->{ section }, $c->stash->{ forum }
	);
	
	$c->stash->{ page_num     } = 1;
	$c->stash->{ post_count   } = $post_count;
	$c->stash->{ forum_posts  } = $forum_posts;
	$c->stash->{ sticky_posts } = $sticky_posts;
}


=head2 view_forum_page

Display specified page of posts in a specified forum.

=cut

sub view_forum_page : Chained( 'base' ) : PathPart( 'page' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $section_name, $forum_name, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$self->stash_forum( $c, $section_name, $forum_name );
	
	$page  ||= 1;
	$count ||= $c->config->{ Forums }->{ posts_per_page };
	
	my $forum_posts  = $self->get_posts(
		$c, $c->stash->{ section }, $c->stash->{ forum }, $page, $count
	);
	
	$c->stash->{ page_num     } = $page;
	$c->stash->{ post_count   } = $count;
	
	$c->stash->{ forum_posts  } = $forum_posts;
	
	$c->stash->{ template     } = 'forums/view_forum.tt';
}


=head2 view_posts_by_author

Display a page of forum posts by a particular author.

=cut

sub view_posts_by_author : Chained( 'base' ) : PathPart( 'author' ) : OptionalArgs( 3 ) {
	my ( $self, $c, $author, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Forums }->{ posts_per_page };
	
	my $posts = $self->get_posts_by_author( $c, $author, $page, $count );
	
	$c->stash->{ author     } = $author;
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ forum_posts } = $posts;
	
	$c->stash->{ template   } = 'forums/view_posts.tt';
}


=head2 view_post

View a specified forum post.

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 4 ) {
	my ( $self, $c, $section_name, $forum_name, $post_id, $url_title ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my $post = $self->get_post( $c, $post_id );
	
	# Make sure we found the specified post
	unless ( $post ) {
		$c->stash->{ error_msg } = 'Failed to find specified forum post.';
		$c->go( 'view_forums' );
	}
	
	# Check url_title matches post, if it doesn't then redirect to correct URL
	unless ( $post->url_title eq $url_title ) {
		$c->response->redirect( $c->uri_for( 
			$post->forum->section->url_name, $post->forum->url_name, 
			$post->id, $post->url_title 
		) );
	}
	
	# Stash the post
	$c->stash->{ forum_post } = $post;
	
	# Stash the tags
	$c->stash->{ forum_post }->{ tags } = $self->get_tags( $c, $c->stash->{ forum_post }->id );
}


=head2 add_post

Start a new thread.

=cut

sub add_post : Chained( 'base' ) : PathPart( 'post' ) : Args( 2 ) {
	my ( $self, $c, $section_name, $forum_name ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	# Check to make sure we have a logged-in user
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to post on the forums.';
		$c->go( '/login' );
	}
	
	my $section = $c->model( 'DB::ForumSection' )->find({
		url_name => $section_name,
	});
	$c->stash->{ forum } = $section->forums->find({
		url_name => $forum_name,
	});
	
	$c->stash->{ template } = 'forums/edit_post.tt';
}

	
=head2 add_post_do

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'add-post-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure we have a logged-in user
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to post on the forums.';
		$c->go( '/login' );
	}
	
	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =~ s/-+/-/g;
	$url_title   =  lc $url_title;
	
	# Filter the body text
	my $body = $c->request->param( 'body' );
	$body    = $c->model( 'FilterHTML' )->filter( $body );
	
	# Add the post
	my $post = $c->model( 'DB::ForumPost' )->create({
		author    => $c->user->id,
		title     => $c->request->param( 'title' ),
		url_title => $url_title || undef,
		body      => $body      || undef,
		forum     => $c->request->param( 'forum' ),
	});
	
	# Create a related discussion thread
	my $discussion = $c->model( 'DB::Discussion' )->create({
		resource_id   => $post->id,
		resource_type => 'ForumPost',
	});
	$post->update({ discussion => $discussion->id });
	
	# Process the tags
	if ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'ForumPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'New thread added';
	
	# Bounce to the newly-posted item
	$c->response->redirect( $c->uri_for( $post->forum->section->url_name, 
		$post->forum->url_name, $post->id, $post->url_title ) );
}


=head2 most_recent_comment

Return most recent comment posted in the forums.

=cut

sub most_recent_comment {
	my( $self, $c ) = @_;
	
	# Find the most recent comment
	my $comment = $c->model( 'DB::Comment' )->search(
		{
			'discussion.resource_type' => 'ForumPost',
		},
		{
			order_by => { -desc => 'posted' },
			rows     => 1,
			join     => 'discussion',
		}
	)->first;
	
	return unless $comment;
	
	my $post = $c->model( 'DB::ForumPost' )->find({
		id => $comment->discussion->resource_id,
	});
	$comment->{ post } = $post;
	
	return $comment;
}


=head2 most_popular_comment

Return most popular comment in specified forum section.

=cut

sub most_popular_comment {
	my( $self, $c, $section_id ) = @_;
	
	if ( $section_id ) {
		# Find the most popular comment in this section
		my $likes = $c->model( 'DB::CommentLike' )->search(
			{},
			{
				'+select' => [
					
					{ count => 'id', -as => 'rowcount' }
				],
				group_by => 'comment',
				order_by => { -desc => 'rowcount' },
			},
		);
		
		while ( my $like = $likes->next ) {
			my $comment = $like->comment;
			
			my $post = $c->model( 'DB::ForumPost' )->find({
				id => $comment->discussion->resource_id,
			});
				
			if ( $post->forum->section->id == $section_id ) {
				$comment->{ post } = $post;
				return $comment;
			}
		}
		return;		# no popular comments in this section
	}
	else {
		# Find the most popular comment in any section
		my $result = $c->model( 'DB::CommentLike' )->search(
			{},
			{
				'+select' => [
					
					{ count => 'id', -as => 'rowcount' }
				],
				group_by => 'comment, id, user, ip_address',
				order_by => { -desc => 'rowcount' },
				rows     => 1,
			},
		)->first;
		
		return unless $result;	# no popular comments
		
		my $comment = $result->comment;
		
		my $post = $c->model( 'DB::ForumPost' )->find({
			id => $comment->discussion->resource_id,
		});
		$comment->{ post } = $post;
		
		return $comment;
	}
}


=head2 get_top_posters

Return specified number of most prolific posters.

=cut

sub get_top_posters {
	my( $self, $c, $count ) = @_;
	
	$count ||= 10;
	
	# Get the user details from the db
#	my @users = $c->model( 'DB::User' )->search(
#		{},
#		{
#			order_by => 'forum_post_and_comment_count',
#			rows => $count,
#		},
#	);
#	
#	return @users;
	
	my @users = $c->model( 'DB::User' )->all;
	
	@users = sort {
		$b->forum_post_and_comment_count <=> $a->forum_post_and_comment_count
	} @users;
	
	return @users[ 0 .. $count-1 ];
}


=head2 search

Search the forums.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $forum_posts = [];
		my @results = $c->model( 'DB::ForumPost' )->search({
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
			if ( $result->title =~ m/(.{0,50}$search.{0,50})/is ) {
				$match = $1;
			}
			elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/is ) {
				$match = $1;
			}
			# Tidy up and mark the truncation
			unless ( $match eq $result->title or $match eq $result->body ) {
				$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
				$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
			}
			if ( $match eq $result->title ) {
				$match = substr $result->body, 0, 100;
				$match =~ s/\s\S+\s?$/ .../;
			}
			# Add the match string to the result
			$result->{ match } = $match;
			
			# Push the result onto the results array
			push @$forum_posts, $result;
		}
		$c->stash->{ forum_results } = $forum_posts;
	}
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

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

