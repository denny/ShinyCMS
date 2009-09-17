package Reactant::Controller::Blog;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

Reactant::Controller::Blog

=head1 DESCRIPTION

Main controller for Reactant's blog features.

=head1 METHODS

=cut


=head2 index

=cut


sub user_is_author : Private {
	my ( $self, $c ) = @_;
	
	unless ( $c->user_exists and $c->user->username eq $c->stash->{ author } ) {
		$c->response->redirect( $c->uri_for('/user/login') );
	}
}


sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
	
	$c->go( 'recent' );
}


sub base : Chained('/') : PathPart('blog') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Check for an author
	# TODO: make this less crap
	my $author = undef;
	my $uri = $c->req->uri;
	$uri =~ m!//(\w+)\.!;
	$author = $1 if $1 and $1 ne 'www';
	
	# If we've got an author, put the name in the stash and set up a where clause
	my $where = undef;
	if ( $author ) {
		my $author_id = $c->model('DB::User')->find( { username => $author } )->id;
		$c->stash->{ author_id } = $author_id;
		$c->stash->{ author    } = $author;
		$where = { author => $author_id };
	}
	
	# Put the blog/blogs into the stash
	$c->stash->{ blog } = $c->model('DB::Blog')->search(
		$where,
	);
	
	if ( $author ) {
		$c->stash->{ blog_title } = $c->stash->{ blog }->first->title;
	}
	else {
		$c->stash->{ blog_title } = 'All Blogs';
	}
}


sub recent : Chained('base') : PathPart('recent') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ posts } = [
		$c->stash->{ blog }->search_related('blog_posts')->search(
			{ },
			{ order_by => 'posted desc' },
		)
	];
}


sub update : Chained('base') : PathPart('update') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure the logged in user is the author of this blog
	$self->user_is_author( $c );
	
	$c->stash->{ now } = DateTime->now;
}


sub get_post : Chained('base') : PathPart('post') : CaptureArgs(1) {
	my ( $self, $c, $post_id ) = @_;
	
	$c->stash->{ post } = $c->model('DB::BlogPost')->find( { id => $post_id } );
	
	die "Post $post_id not found" unless $c->stash->{ post };
}


sub read : Chained('get_post') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
}


sub edit : Chained('get_post') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure the logged in user is the author of this blog
	$self->user_is_author( $c );
	
	$c->stash->{ now } = DateTime->now;
	
	# Set the TT template to use
	$c->stash->{template} = 'blog/update.tt';
}


sub update_do : Chained('base') : PathPart('update_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	if ( $c->request->params->{ delete } eq 'Delete Post' ) {
		$c->go('delete_do')
	}
	
	# Get the data from the form
	my $post_id = $c->request->params->{ post_id };
	my $posted  = $c->request->params->{ posted  } or die 'No posted date.';
	my $title   = $c->request->params->{ title   } or die 'No title.';
	my $body    = $c->request->params->{ body    } or die 'No body text.';
	
	# Get the author from the stash
	my $author_id = $c->stash->{ author_id };
	
	if ( $post_id ) {
		my $post = $c->model('DB::BlogPost')->find( { id => $post_id } );
		
		$post->update({
			title  => $title,
			body   => $body,
			posted => $posted,
		});
	}
	else {
		# Create the blog post
		my $post = $c->stash->{ blog }->first->create_related( 'blog_posts', {
			title  => $title,
			body   => $body,
			posted => $posted,
		});
		$post_id = $post->id;
	}
	
	# Stick the post ID in the stash for use in links
	$c->stash->{ post_id } = $post_id;
	
	# Set the TT template to use
	$c->stash->{template} = 'blog/update_done.tt';
}


sub delete_do : Chained('base') : PathPart('delete_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Get the data from the form
	my $post_id = $c->request->params->{ post_id };
	
	$c->model('BlogPost')->find( { id => $post_id } )->delete;
	
	# Set the TT template to use
	$c->stash->{template} = 'blog/delete_done.tt';
}


=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

