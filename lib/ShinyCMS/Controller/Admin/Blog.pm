package ShinyCMS::Controller::Admin::Blog;

use Moose;
use MooseX::Types::Moose qw/ Str Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use XML::Feed;
#use Encode;


=head1 NAME

ShinyCMS::Controller::Admin::Blog

=head1 DESCRIPTION

Controller for ShinyCMS blog admin features.

=cut


has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has hide_new_posts => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);


=head1 METHODS

=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/blog' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'add or edit a blog post',
		role     => 'Blog Author',
		redirect => '/blog'
	});

	# Stash the name of the controller
	$c->stash->{ admin_controller } = 'Blog';
}


=head2 index

Forward to list_posts

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_posts' );
}


=head2 list_posts

Lists all blog posts, for use in admin area.

=cut

sub list_posts : Chained( 'base' ) : PathPart( 'posts' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ blog_posts } = $c->model( 'DB::BlogPost' )->search(
		{},
		{
			order_by => { -desc => 'posted' },
			page     => $c->request->param( 'page'  ) ?
						$c->request->param( 'page'  ) : 1,
			rows     => $c->request->param( 'count' ) ?
						$c->request->param( 'count' ) : $self->page_size,
		},
	);
}


=head2 add_post

Add a new blog post.

=cut

sub add_post : Chained( 'base' ) : PathPart( 'post/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Pass in the list of blog authors
	my @authors = $c->model( 'DB::Role' )->search({ role => 'Blog Author' })
		->single->users->all;
	$c->stash->{ authors } = \@authors;

	# Find default comment setting and pass through
	$c->stash->{ comments_default_on } = 'YES'
		if uc $self->comments_default eq 'YES';

	# Stash 'hide new posts' setting
	$c->stash->{ hide_new_posts } = 1 if uc $self->hide_new_posts eq 'YES';

	$c->stash->{ template } = 'admin/blog/edit_post.tt';
}


=head2 add_post_do

Process adding a blog post.

=cut

sub add_post_do : Chained( 'base' ) : PathPart( 'post/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' ) ?
	    $c->request->param( 'url_title' ) :
	    $c->request->param( 'title'     );
	$url_title = $self->make_url_slug( $url_title );

	# TODO: catch and fix duplicate year/month/url_title combinations

	my $posted;
	if ( $c->request->param( 'posted_date' ) ) {
		$posted = $c->request->param( 'posted_date' ) .' '. $c->request->param( 'posted_time' );
	}

	my $author_id = $c->user->id;
	if ( $c->user->has_role( 'Blog Admin' ) and $c->request->param( 'author' ) ) {
		$author_id = $c->request->param( 'author' );
	}

	# Add the post
	my $hidden = $c->request->param( 'hidden' ) ? 1 : 0;
	my $post = $c->model( 'DB::BlogPost' )->create({
		blog      => 1,
		title     => $self->safe_param( $c, 'title' ),
		url_title => $url_title,
		author    => $author_id,
		posted    => $posted,
		hidden    => $hidden,
		body      => $self->safe_param( $c, 'body' ),
	});

	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		$post->update({ discussion => $discussion->id });
	}

	# Process the tags
	if ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		my %dedupe;
		foreach my $tag ( @tags ) {
			$dedupe{ $tag } = 1;
		}
		foreach my $tag ( keys %dedupe ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post added';

	# Rebuild the atom feed
	$c->forward( 'Admin::Blog', 'generate_atom_feed' ) unless $hidden;

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'post', $post->id, 'edit' ) );
}


=head2 get_post
Get details of an existing blog post.

=cut

sub get_post : Chained( 'base' ) : PathPart( 'post' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $post_id ) = @_;

	# Stash the blog post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
	# Stash the tags
	$c->stash->{ blog_post_tags } = $self->get_tags( $c, $post_id );
}


=head2 edit_post

Edit an existing blog post.

=cut

sub edit_post : Chained( 'get_post' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @authors = $c->model( 'DB::Role' )->search({ role => 'Blog Author' })
		->single->users->all;
	$c->stash->{ authors } = \@authors;
}


=head2 edit_post_do

Process an update.

=cut

sub edit_post_do : Chained( 'get_post' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Get the post
	my $post   = $c->stash->{ blog_post };
	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $post->id,
		resource_type => 'BlogPost',
	});

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		# Delete tags and tagset associated with this post
		if ( $tagset ) {
			$tagset->tags->delete;
			$tagset->delete;
		}
		# Delete comments and discussion, if not attached to any other content
		if ( defined $post->discussion ) {
			my $b = $post->discussion->blog_posts;
			my $s = $post->discussion->shop_items;
			my $f = $post->discussion->forum_posts;
			my $u = $post->discussion->users;
			my $count = $b->count;
			$count += $s->count if $s;
			$count += $f->count if $f;
			$count += $u->count if $u;
			if ( $count == 1 ) {
				# This blog post was the discussion's only 'parent'
				my $d = $post->discussion;
				$d->comments->delete if $d->comments;
				$post->update({ discussion => undef });
				$d->delete;
			}
			else {
				# Discussion is attached to more than one piece of content;
				# do not delete it!  But, if this blog post is currently the
				# discussion's 'primary parent', then we should change that.
				if ( $post->discussion->resource_type eq 'BlogPost'
						and $post->discussion->resource_id == $post->id ) {
					my $new_resource_type;
					my $new_resource_id;
					if ( $b->count > 1 ) {
						my $posts = $b->search({ id => { '!=' => $post->id } });
						$new_resource_type = 'BlogPost';
						$new_resource_id   = $posts->last->id;
					}
					elsif ( $s and $s->count > 0 ) {
						$new_resource_type = 'ShopItem';
						$new_resource_id   = $s->last->id;
					}
					elsif ( $f and $f->count > 0 ) {
						$new_resource_type = 'ForumPost';
						$new_resource_id   = $f->last->id;
					}
					elsif ( $u and $u->count > 0 ) {
						$new_resource_type = 'User';
						$new_resource_id   = $u->last->id;
					}
					else {
						warn 'Should not reach here!';
					}
					$post->discussion->update({
						resource_type => $new_resource_type,
						resource_id   => $new_resource_id
					});
				}
			}
		}
		# Delete the post itself
		$post->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Post deleted';

		# Rebuild the atom feed
		$self->generate_atom_feed( $c );

		# Bounce to the list of posts
		$c->response->redirect( $c->uri_for( 'posts' ) );
		return;
	}

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' ) ?
	    $c->request->param( 'url_title' ) :
	    $c->request->param( 'title'     );
	$url_title = $self->make_url_slug( $url_title );

	# TODO: catch and fix duplicate year/month/url_title combinations

	my $posted = $c->request->param( 'posted_date' ) .' '. $c->request->param( 'posted_time' );

	my $author_id = $post->author->id;
	if ( $c->user->has_role( 'Blog Admin' ) and $c->request->param( 'author' ) ) {
		$author_id = $c->request->param( 'author' );
	}

	# Perform the update
	my $hidden = $c->request->param( 'hidden' ) ? 1 : 0;
	$post->update({
		title     => $self->safe_param( $c, 'title' ),
		url_title => $url_title,
		author    => $author_id,
		posted    => $posted,
		hidden    => $hidden,
		body      => $self->safe_param( $c, 'body' ),
	});

	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) and not $post->discussion ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		$post->update({ discussion => $discussion->id });
	}
	# Disconnect the related discussion thread, if requested
	# (leaves it orphaned, rather than deleting it)
	elsif ( $post->discussion and not $c->request->param( 'allow_comments' ) ) {
		$post->update({ discussion => undef });
	}

	# Process the tags
	if ( $tagset ) {
		my $tags = $tagset->tags;
		$tags->delete;
		if ( $c->request->param('tags') ) {
			my @tags = sort split /\s*,\s*/, $c->request->param('tags');
			my %dedupe;
			foreach my $tag ( @tags ) {
				$dedupe{ $tag } = 1;
			}
			foreach my $tag ( keys %dedupe ) {
				$tagset->tags->create({
					tag => $tag,
				});
			}
		}
		else {
			$tagset->delete;
		}
	}
	elsif ( $c->request->param('tags') ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $post->id,
			resource_type => 'BlogPost',
		});
		my @tags = sort split /\s*,\s*/, $c->request->param('tags');
		my %dedupe;
		foreach my $tag ( @tags ) {
			$dedupe{ $tag } = 1;
		}
		foreach my $tag ( keys %dedupe ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Blog post updated';

	# Rebuild the atom feed
	$self->generate_atom_feed( $c ) unless $hidden;

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'post', $post->id, 'edit' ) );
}


# ========= ( utility methods ) ==========

=head2 get_tags

Get the tags for a post, or for the whole blog if no post specified

=cut

sub get_tags {
	my ( $self, $c, $post_id ) = @_;

	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_type => 'BlogPost',
		resource_id   => $post_id,
	});

	return $tagset->tag_list if $tagset;
}


=head2 generate_atom_feed

Generate the atom feed.

=cut

sub generate_atom_feed {
	my ( $self, $c ) = @_;

	my $now = DateTime->now;
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			hidden   => 0,
			posted   => { '<=', $now->ymd .' '. $now->hms },
		},
		{
			order_by => { -desc => 'posted' },
			page     => 1,
			rows     => 10,
		}
	)->all;

	my $domain    = $c->config->{ domain    } || 'shinycms.org';
	my $site_name = $c->config->{ site_name } || 'ShinySite';

	my $feed = XML::Feed->new( 'Atom' );
	$feed->id(          'tag:'. $domain .',2010:blog' );
	$feed->self_link(   $c->uri_for( '/static', 'feeds', 'atom.xml' ) );
	$feed->link(        $c->uri_for( '/blog' )               );
	$feed->modified(    $now                                 );
	$feed->title(       $site_name                           );
	$feed->description( 'Recent blog posts from '.$site_name );

	# Process the entries
	foreach my $post ( @posts ) {
		my $posted = $post->posted;
		$posted->set_time_zone( 'UTC' );

		my $url = $c->uri_for( '/blog', $posted->year, $posted->month, $post->url_title );
		my $id  = 'tag:'. $domain .',2010:blog:'. $posted->year .':'. $posted->month .':'. $post->url_title;

		my $author = $post->author->display_name || $post->author->username;

		my $entry = XML::Feed::Entry->new( 'Atom' );

		$entry->id(       $id          );
		$entry->link(     $url         );
		$entry->author(   $author      );
		$entry->modified( $posted      );
		$entry->title(    $post->title );
		$entry->content(  $post->body  );

		$feed->add_entry( $entry );
	}

	# Write feed to file
	my $xml  = $feed->as_xml;
	my $file = $c->path_to( 'root', 'static', 'feeds' ) .'/atom.xml';
	open my $fh, '>', $file or die "Failed to open atom.xml for writing: $!";
	print $fh $xml, "\n"    or die "Failed to write to atom.xml: $!";
	close $fh               or die "Failed to close atom.xml after writing: $!";
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
