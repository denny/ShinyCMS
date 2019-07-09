package ShinyCMS::Controller::Blog;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Blog

=head1 DESCRIPTION

Controller for ShinyCMS blogs.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 10,
);


=head1 METHODS

=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/base' ) : PathPart( 'blog' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };

	# Stash the name of the controller
	$c->stash->{ controller } = 'Blog';
}


=head2 index

Display recent blog posts.

/blog

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'view_posts' );
}


=head2 view_posts

Display a page of blog posts.

/blog/posts

=cut

sub view_posts : Chained( 'base' ) : PathPart( 'posts' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ blog_posts } = $self->get_posts( $c );
}


=head2 view_tag

Display a page of blog posts with a particular tag.

/blog/tag/stuff    # Posts about 'stuff'

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;

	my $posts = $self->get_tagged_posts( $c, $tag );

	$c->stash->{ blog_posts } = $posts;
	$c->stash->{ tag        } = $tag;

	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_month

Display blog posts from a specified month.

/blog/2012/5	# Posts from May 2012

=cut

sub view_month : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $year, $month ) = @_;

	if ( $year =~ m/\D/ ) {
		$c->response->status( 400 );
		$c->response->body( 'Year must be a number' );
		$c->detach;
	}

	if ( $month =~ m/\D/ or $month < 1 or $month > 12 ) {
		$c->response->status( 400 );
		$c->response->body( 'Month must be a number between 1 and 12' );
		$c->detach;
	}

	my $month_start = DateTime->new(
		day   => 1,
		month => $month,
		year  => $year,
	);
	my $month_end = $month_start->clone->add( months => 1 );

	my @blog_posts = $c->model( 'DB::BlogPost' )->search(
		{
			-and => [
				posted => { '<=' => \'current_timestamp' },
				posted => { '>=' => $month_start->ymd    },
				posted => { '<'  => $month_end->ymd      },
			],
			hidden => 0,
		},
		{
			order_by => 'posted',
		},
	);

	my $tagged_posts = ();
	foreach my $post ( @blog_posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}
	$c->stash->{ blog_posts } = $tagged_posts;

	my $one_month = DateTime::Duration->new( months => 1 );
	my $date = DateTime->new( year => $year, month => $month );
	my $prev = $date - $one_month;
	my $next = $month_end;

	$c->stash->{ date      } = $date;
	$c->stash->{ prev      } = $prev;
	$c->stash->{ next      } = $next;
	$c->stash->{ prev_link } = $c->uri_for( $prev->year, $prev->month );
	$c->stash->{ next_link } = $c->uri_for( $next->year, $next->month );

	$c->stash->{ template  } = 'blog/view_posts.tt';
}


=head2 view_year

Display summary of blog posts in a year.

/blog/2012		# Posts from 2012

=cut

sub view_year : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $year ) = @_;

	if ( $year =~ m/\D/ ) {
		$c->response->status( 400 );
		$c->response->body( 'Year must be a number' );
		$c->detach;
	}

	$c->stash->{ months } = $self->get_posts_for_year( $c, $year );
	$c->stash->{ year   } = $year;
}


=head2 view_posts_by_author

Display a page of blog posts by a particular author.

/blog/author/blogger    # Posts by 'blogger'

=cut

sub view_posts_by_author : Chained( 'base' ) : PathPart( 'author' ) : Args( 1 ) {
	my ( $self, $c, $author ) = @_;

	my $posts = $self->get_posts_by_author( $c, $author );

	$c->stash->{ blog_posts } = $posts;
	$c->stash->{ author     } = $author;

	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_post

View a specified blog post.

/blog/2012/5/this-is-the-url-title

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;

	if ( $year =~ m/\D/ ) {
		$c->response->status( 400 );
		$c->response->body( 'Year must be a number' );
		$c->detach;
	}

	if ( $month =~ m/\D/ or $month < 1 or $month > 12 ) {
		$c->response->status( 400 );
		$c->response->body( 'Month must be a number between 1 and 12' );
		$c->detach;
	}

	my $month_start = DateTime->new(
		day   => 1,
		month => $month,
		year  => $year,
	);
	my $month_end = $month_start->clone->add( months => 1 );

	# Stash the post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->search({
		url_title => $url_title,
		-and => [
				posted => { '<=' => \'current_timestamp' },
				posted => { '>=' => $month_start->ymd    },
				posted => { '<'  => $month_end->ymd      },
			],
			hidden => 0,
	})->first;

	unless ( $c->stash->{ blog_post } ) {
		$c->flash->{ error_msg } = 'Failed to find specified blog post.';
		$c->go( 'view_recent' );
	}

	$c->stash->{ year } = $year;

	# Stash the tags
	$c->stash->{ blog_post }->{ tags } =
		$self->get_tags( $c, $c->stash->{ blog_post }->id );
}


# ========== ( utility methods ) ==========

=head2 get_posts

Get a page's worth of posts

=cut

sub get_posts : Private {
	my ( $self, $c ) = @_;

	$c->stash->{ blog_posts_obj } = $c->model( 'DB::BlogPost' )->search(
		{
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $c->request->param( 'page'  ) ?
						$c->request->param( 'page'  ) : 1,
			rows     => $c->request->param( 'count' ) ?
						$c->request->param( 'count' ) : $self->page_size,
		},
	);

	# TODO: ewww
	my @posts = $c->stash->{ blog_posts_obj }->all;
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}

	return $tagged_posts;
}


=head2 get_posts_for_year

Get a year's worth of posts, broken down by months (for archive widget)

=cut

sub get_posts_for_year : Private {
	my ( $self, $c, $year ) = @_;

	my $year_start = DateTime->new(
		day   => 1,
		month => 1,
		year  => $year,
	);
	my $year_end = $year_start->clone->add( years => 1 );

	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			-and => [
				posted => { '<=' => \'current_timestamp' },
				posted => { '>=' => $year_start->ymd     },
				posted => { '<'  => $year_end->ymd       },
			],
			hidden => 0,
		},
		{
			order_by => 'posted',
		},
	);

	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}

	my $by_months = {};
	foreach my $post ( @$tagged_posts ) {
		my $month = $post->posted->month;
		push @{ $by_months->{ $month } }, $post;
	}

	my $months = [];
	foreach my $month ( sort {$a<=>$b} keys %$by_months ) {
		push @$months, $by_months->{ $month };
	}

	return $months;
}


=head2 get_tags

Get the tags for a post, or for the whole blog if no post specified

=cut

sub get_tags : Private {
	my ( $self, $c, $post_id ) = @_;

	if ( $post_id ) {
		my $tagset = $c->model( 'DB::Tagset' )->find({
			resource_id   => $post_id,
			resource_type => 'BlogPost',
		});
		return $tagset->tag_list if $tagset;
	}
	else {
		my @tagsets = $c->model( 'DB::Tagset' )->search({
			resource_type => 'BlogPost',
		});
		my @taglist;
		foreach my $tagset ( @tagsets ) {
			push @taglist, @{ $tagset->tag_list };
		}
		my %taghash;
		foreach my $tag ( @taglist ) {
			$taghash{ $tag } = 1;
		}
		my @tags = keys %taghash;
		@tags = sort { lc $a cmp lc $b } @tags;
		return \@tags;
	}

	return;
}


=head2 get_tagged_posts

Get a page's worth of posts with a particular tag

=cut

sub get_tagged_posts : Private {
	my ( $self, $c, $tag, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : $self->page_size;

	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'BlogPost';
		push @tagged, $tagset->get_column( 'resource_id' ),
	}

	$c->stash->{ blog_posts_obj } = $c->model( 'DB::BlogPost' )->search(
		{
			id       => { 'in' => \@tagged },
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $c->request->param( 'page'  ) ?
						$c->request->param( 'page'  ) : 1,
			rows     => $c->request->param( 'count' ) ?
						$c->request->param( 'count' ) : $self->page_size,
		},
	);

	# TODO: ewww
	my @posts = $c->stash->{ blog_posts_obj }->all;
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

sub get_posts_by_author : Private {
	my ( $self, $c, $username ) = @_;

	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});

	$c->stash->{ blog_posts_obj } = $c->model( 'DB::BlogPost' )->search(
		{
			author   => $author->id,
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $c->request->param( 'page'  ) ?
						$c->request->param( 'page'  ) : 1,
			rows     => $c->request->param( 'count' ) ?
						$c->request->param( 'count' ) : $self->page_size,
		},
	);

	# TODO: ewww
	my @posts = $c->stash->{ blog_posts_obj }->all;
	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}

	return $tagged_posts;
}


# ========== ( search method used by site-wide search feature ) ==========

=head2 search

Search the blog section.

=cut

sub search {
	my ( $self, $c ) = @_;

	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $blog_posts = [];
		my @results = $c->model( 'DB::BlogPost' )->search({
			-and => [
				posted => { '<=' => \'current_timestamp' },
				hidden => 0,
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
			push @$blog_posts, $result;
		}
		$c->stash->{ blog_results } = $blog_posts;
	}
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
