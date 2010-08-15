package ShinyCMS::Controller::Blog;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Blog

=head1 DESCRIPTION

Controller for ShinyCMS blogs.

=head1 METHODS

=cut


=head2 base

=cut

sub base : Chained( '/' ) : PathPart( 'blog' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ controller } = 'Blog';
}


=head2 get_posts

=cut

sub get_posts {
	my ( $self, $c, $count, $page ) = @_;
	
	$count ||= 10;
	$page  ||= 1;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{},
		{
			order_by => 'posted desc',
			rows     => $count,
			page     => $page,
		},
	);
	return \@posts;
}


=head2 get_post

=cut

sub get_post {
	my ( $self, $c, $post_id ) = @_;
	
	return $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
}


=head2 view_posts

Display recent blog posts.

=cut

sub view_posts : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $posts = $self->get_posts( $c );
	
	$c->stash->{ blog_posts } = $posts;
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 view_month

Display blog posts from a specified month.

=cut

sub view_month : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $year, $month ) = @_;
	
	my @blog_posts = $c->model( 'DB::BlogPost' )->search(
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	);
	$c->stash->{ blog_posts } = \@blog_posts;
	
	my $one_month = DateTime::Duration->new( months => 1 );
	my $date = DateTime->new( year => $year, month => $month );
	my $prev = $date - $one_month;
	my $next = $date + $one_month;
	
	$c->stash->{ date      } = $date;
	$c->stash->{ prev      } = $prev;
	$c->stash->{ next      } = $next;
	$c->stash->{ prev_link } = $c->uri_for( $prev->year, $prev->month );
	$c->stash->{ next_link } = $c->uri_for( $next->year, $next->month );
	
	$c->stash->{ template } = 'blog/view_posts.tt';
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 view_year

TODO: Display summary of blog posts in a year.

Currently, this bounces the reader to the current month in the requested year.

=cut

sub view_year : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $year ) = @_;
	
	$c->response->redirect( $c->uri_for( $year, DateTime->now->month ) );
}


=head2 view_post

View a specified blog post.

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->search(
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	)->first;
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 list_posts

Lists all blog posts, for use in admin area.

=cut

sub list_posts : Chained( 'base' ) : PathPart( 'list-posts' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $posts = $self->get_posts( $c, 100 );
	
	$c->stash->{ blog_posts } = $posts;
}


=head2 add_post

Add a new blog post.

=cut

sub add_post : Chained( 'base' ) : PathPart( 'add-post' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to post to a blog.';
		$c->go( '/user/login' );
	}
	
	# Bounce if user isn't a blog author
	unless ( $c->user->has_role( 'Blog Author' ) ) {
		$c->stash->{ error_msg } = 'You do not have the ability to post to a blog.';
		$c->response->redirect( '/blog' );
	}
	
	$c->stash->{ template } = 'blog/edit_post.tt';
}


=head2 add_post_do

Process adding a blog post.

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'add-post-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check user privs
	die unless $c->user->has_role( 'Blog Author' );	# TODO
	
	# Add the post
	my $post = $c->model( 'DB::BlogPost' )->create({
		author    => $c->user->id,
		title     => $c->request->param( 'title'     ),
		url_title => $c->request->param( 'url_title' ),
		body      => $c->request->param( 'body'      ),
		blog      => 1,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $post->id ) );
}


=head2 edit_post

Edit an existing blog post.

=cut

sub edit_post : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $post_id ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit blog posts.';
		$c->go( '/user/login' );
	}
	
	# Bounce if user isn't a blog author
	unless ( $c->user->has_role( 'Blog Author' ) ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit blog posts.';
		$c->response->redirect( '/blog' );
	}
	
	# Stash the blog post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
}


=head2 edit_post_do

Process an update.

=cut

sub edit_post_do : Chained( 'base' ) : PathPart( 'edit-post-do' ) : Args( 1 ) {
	my ( $self, $c, $post_id ) = @_;
	
	# Check user privs
	die unless $c->user->has_role( 'Blog Author' );	# TODO
	
	# Perform the update
	my $post = $c->model( 'DB::BlogPost' )->find( {
		id => $post_id,
	} )->update({
		title     => $c->request->param( 'title'     ),
		url_title => $c->request->param( 'url_title' ),
		body      => $c->request->param( 'body'      ),
	} );
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $post_id ) );
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

