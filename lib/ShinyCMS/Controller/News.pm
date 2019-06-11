package ShinyCMS::Controller::News;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::News

=head1 DESCRIPTION

Controller for ShinyCMS news section.

=cut


=head1 METHODS

=head2 base

Set the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'news' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the name of the controller
	$c->stash->{ controller } = 'News';
}


=head2 view_items

View a page of news items.

/news will give you the first page, default page size
/news/2 will give you the second page, default page size
/news/3/4 will give yoiu the third page, four items per page (so items 9-12)

Note: The catchall 'Args' here could potentially steal the view_item() URLs,
but luckily doesn't.  Don't ask me why.  All hail the mighty Dispatcher.

TODO: Rewrite this to support /news/year and /news/year/month URLs like the
blog.  Use query params (and the DBIC pager object) for paging  instead (copy
paging code from admin area).

=cut

sub view_items : Chained( 'base' ) : PathPart( '' ) : Args {
	my ( $self, $c, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : 10;

	my $posts = $self->get_posts( $c, $page, $count );

	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;

	$c->stash->{ news_items } = $posts;
}


=head2 view_item

View details of a news item.

=cut

sub view_item : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;

	my $month_start = DateTime->new(
		day   => 1,
		month => $month,
		year  => $year,
	);
	my $month_end = DateTime->new(
		day   => 1,
		month => $month,
		year  => $year,
	);
	$month_end->add( months => 1 );

	$c->stash->{ news_item } = $c->model( 'DB::NewsItem' )->search({
		url_title => $url_title,
		-and => [
			posted => { '<=' => \'current_timestamp' },
			posted => { '>=' => $month_start->ymd    },
			posted => { '<=' => $month_end->ymd      },
		],
		hidden => 0,
	})->first;
}


# ========== ( utility methods ) ==========

=head2 get_posts

Get the specified number of recent news posts.

=cut

sub get_posts : Private {
	my ( $self, $c, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : 10;

	my @posts = $c->model( 'DB::NewsItem' )->search(
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

	my $tagged_posts = ();
	foreach my $post ( @posts ) {
		# Stash the tags
		$post->{ tags } = $self->get_tags( $c, $post->id );
		push @$tagged_posts, $post;
	}

	return $tagged_posts;
}


=head2 get_tags

Get the tags for a news post

=cut

sub get_tags : Private {
	my ( $self, $c, $post_id ) = @_;

	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $post_id,
		resource_type => 'NewsItem',
	});

	return $tagset->tag_list if $tagset;
	return;
}


=head2 get_tagged_posts

Get a page's worth of posts with a particular tag

=cut

sub get_tagged_posts : Private {
	my ( $self, $c, $tag, $page, $count ) = @_;

	$page  = $page  ? $page  : 1;
	$count = $count ? $count : 10;

	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'NewsItem';
		push @tagged, $tagset->get_column( 'resource_id' ),
	}

	my @posts = $c->model( 'DB::NewsItem' )->search(
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

Search the news section.

=cut

sub search {
	my ( $self, $c ) = @_;

	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $news_items = ();
		my @results = $c->model( 'DB::NewsItem' )->search({
			-or => [
				title => { 'LIKE', '%'.$search.'%'},
				body  => { 'LIKE', '%'.$search.'%'},
			],
			hidden => 0,
		});
		foreach my $result ( @results ) {
			# Pull out the matching search term and its immediate context
			my $match = '';
			if ( $result->title =~ m/(.{0,50}$search.{0,50})/i ) {
				$match = $1;
			}
			elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/i ) {
				$match = $1;
			}
			# Tidy up and mark the truncation
			unless ( $match eq $result->title or $match eq $result->body ) {
				$match =~ s/^\S*\s/... /;
				$match =~ s/\s\S*$/ .../;
			}
			if ( $match eq $result->title ) {
				$match = substr $result->body, 0, 100;
				$match =~ s/\s\S+\s?$/ .../;
			}
			# Add the match string to the page result
			$result->{ match } = $match;

			# Push the result onto the results array
			push @$news_items, $result;
		}
		$c->stash->{ news_results } = $news_items;
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
