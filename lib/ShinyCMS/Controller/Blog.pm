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

	my $page  = int ( $c->request->param( 'page'  ) || 1 );
	my $count = int ( $c->request->param( 'count' ) || $self->page_size );

	$c->stash->{ blog_posts } = $c->model( 'DB::BlogPost' )->search(
		{
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
}


=head2 view_tag

Display a page of blog posts with a particular tag.

/blog/tag/stuff    # Posts about 'stuff'

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;

	my $page  = int ( $c->request->param( 'page'  ) || 1 );
	my $count = int ( $c->request->param( 'count' ) || $self->page_size );

	my @tagged = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	})->search_related( 'tagset' )->search({
		resource_type => 'BlogPost',
	})->get_column( 'resource_id' )->all;

	$c->stash->{ blog_posts } = $c->model( 'DB::BlogPost' )->search(
		{
			id       => { 'in' => \@tagged },
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);

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

	$c->stash->{ blog_posts } = $c->model( 'DB::BlogPost' )->search(
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
	my ( $self, $c, $username ) = @_;

	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});
	# TODO: bail out gracefully if author not found

	my $page  = int ( $c->request->param( 'page'  ) || 1 );
	my $count = int ( $c->request->param( 'count' ) || $self->page_size );

	$c->stash->{ blog_posts } = $author->blog_posts->search(
		{
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);

	$c->stash->{ author   } = $username;
	$c->stash->{ template } = 'blog/view_posts.tt';
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

	# Find and stash the post
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
		$c->stash->{ error_msg } = 'Failed to find specified blog post.';
		$c->go( 'view_posts' );
	}

	$c->stash->{ year } = $year;
}


# ========== ( utility methods ) ==========

=head2 get_posts

Fetch a specified number of recent blog posts (for 'recent blog post' embeds)

=cut

sub get_posts : Private {
	my ( $self, $c, $count ) = @_;

	my $posts = $c->model( 'DB::BlogPost' )->search(
		{
			posted   => { '<=' => \'current_timestamp' },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'posted' },
			page     => 1,
			rows     => $count,
		},
	);

	return $posts;
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
	)->all;

	my $by_months = {};
	foreach my $post ( @posts ) {
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
			hidden        => 0,
		});
		return $tagset->tag_list if $tagset;
	}
	else {
		my @tagset_ids = $c->model( 'DB::Tagset' )
                       ->search({ resource_type => 'BlogPost', hidden => 0 })
                       ->get_column( 'id' )->all;

		my @tags = $c->model( 'DB::Tag' )
                 ->search({ tagset => \@tagset_ids }, { group_by => 'tag' })
                 ->get_column( 'tag' )->all;

		@tags = sort { lc $a cmp lc $b } @tags;
		return \@tags;
	}
}


# ========== ( search method used by site-wide search feature ) ==========

=head2 search

Search the blog section.

=cut

sub search {
	my ( $self, $c ) = @_;

	return unless my $search = $c->request->param( 'search' );

	my @results = $c->model( 'DB::BlogPost' )->search({
		-and => [
			posted => { '<=' => \'current_timestamp' },
			hidden => 0,
			-or => [
				title => { 'LIKE', '%'.$search.'%'},
				body  => { 'LIKE', '%'.$search.'%'},
			],
		],
	})->all;

	my $blog_posts = [];
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
	return $blog_posts;
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
