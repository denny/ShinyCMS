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
}


=head2 get_posts

=cut

sub get_posts {
	my ( $self, $c, $count ) = @_;
	warn $count;
	$count ||= 10;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{},
		{
			order_by => 'posted desc',
			rows     => $count,
		},
	);
	return \@posts;
}


=head2 view_posts

=cut

sub view_posts : Chained( 'base' ) : PathPart( '' ) : OptionalArgs( 1 ) {
	my ( $self, $c, $count ) = @_;
	
	my $posts = $self->get_posts( $c, $count );
	
	$c->stash->{ blog_posts } = $posts;
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 view_post

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ blog_post } = $c->model('DB::BlogPost')->search(
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	)->first;
}


=head2 list_posts

=cut

sub list_posts : Chained( 'base' ) : PathPart( 'list-posts' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $posts = $self->get_posts( $c, 100 );
	
	$c->stash->{ blog_posts } = $posts;
}


=head2 add_post

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

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'add-post-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check user privs
	die unless $c->user->has_role( 'Blog Author' );	# TODO
	
	# Add the post
	my $post = $c->model('DB::BlogPost')->create({
		author    => $c->user->id,
		title     => $c->request->param( 'title'     ),
		url_title => $c->request->param( 'url_title' ),
		body      => $c->request->param( 'body'      ),
		blog      => 1,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Blog post added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $post->id ) );
}


=head2 edit_post

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


# EOF
__PACKAGE__->meta->make_immutable;
1;

