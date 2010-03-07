package ShinyCMS::Controller::Blog;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

ShinyCMS::Controller::Blog

=head1 DESCRIPTION

Main controller for ShinyCMS's blog features.

=head1 METHODS

=cut


=head2 base

Do some checks and stash some useful stuff about the author.

=cut

sub base : Chained('/') : PathPart('blog') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	my $author_name = undef;
	if ( ShinyCMS->config->{ blogstyle } eq 'subdomains' ) {
		# Check for an author
		my $uri = $c->req->uri;
		my $domain = ShinyCMS->config->{domain};
		warn $domain;
		$uri =~ m!//(\w+)\.$domain!;
		$author_name = $1 if $1 and $1 ne 'www';
	}
	else {
		warn 'ENOCONF';
	}
	warn $author_name;
	
	# If we've got an author, put the name in the stash and set up a where clause
	my $where = undef;
	if ( $author_name ) {
		my $author = $c->model('DB::User')->find({ username => $author_name });
		die "Blog author '$author_name' not found." unless $author; # TODO
		my $author_id = $author->id;
		$c->stash->{ author_id } = $author_id;
		$c->stash->{ author    } = $author;
		$where = { author => $author_id };
	}
	
	# Put the blog/blogs into the stash
	$c->stash->{ blog } = $c->model('DB::Blog')->search(
		$where,
	);
	
	if ( $author_name ) {
		$c->stash->{ blog_title } = $c->stash->{ blog }->first->title;
	}
	elsif ( ShinyCMS->config->{ blogstyle } eq 'subdomains' ) {
		$c->stash->{ blog_title } = 'All Blogs';
	}
	else {
		$c->stash->{ blog_title } = 'Blog';
	}
}


=head2 recent

Display most recent blog posts.  This is the default action.

=cut

sub recent : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ posts } = [
		$c->stash->{ blog }->search_related('blog_posts')->search(
			{ },
			{ order_by => 'posted desc' },
		)
	];
}


=head2 get_post

Put details of specified blog post into the stash.

=cut

sub get_post : Chained('base') : PathPart('post') : CaptureArgs(1) {
	my ( $self, $c, $post_id ) = @_;
	
	$c->stash->{ post } = $c->model('DB::BlogPost')->find({
		blog => $c->stash->{ blog }->first->id,
		id   => $post_id, 
	});
	
	die "Post $post_id not found" unless $c->stash->{ post };
}


=head2 read

Display a blog post for reading.

=cut

sub read : Chained('get_post') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
}


=head2 edit

Edit a blog post.

=cut

sub edit : Chained('get_post') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure the logged in user is the author of this blog
	$self->user_is_author( $c );
	
	$c->stash->{ now } = DateTime->now;
	
	# Set the TT template to use
	$c->stash->{template} = 'blog/update.tt';
}


=head2 update

Post a new blog post.

=cut

sub update : Chained('base') : PathPart('update') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure the logged in user is the author of this blog
	$self->user_is_author( $c );
	
	$c->stash->{ now } = DateTime->now;
}


=head2 update_do

Process an update.

=cut

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


=head2 delete_do

Process a post deletion.

=cut

sub delete_do : Chained('base') : PathPart('delete_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Get the data from the form
	my $post_id = $c->request->params->{ post_id };
	
	$c->model('BlogPost')->find( { id => $post_id } )->delete;
	
	# Set the TT template to use
	$c->stash->{template} = 'blog/delete_done.tt';
}


=head2 user_is_author

Check to see if the current user is the author of this blog.

=cut

sub user_is_author : Private {
	my ( $self, $c ) = @_;
	
	unless ( $c->user_exists and $c->user->username eq $c->stash->{ author }->username ) {
		$c->response->redirect( $c->uri_for('/user/login') );
	}
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

