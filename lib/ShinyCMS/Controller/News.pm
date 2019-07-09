package ShinyCMS::Controller::News;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::News

=head1 DESCRIPTION

Controller for ShinyCMS news section.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 10,
);


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

/news

TODO: Add support for /news/year and /news/year/month URLs, like the blog has.

=cut

sub view_items : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ news_items } = $c->model( 'DB::NewsItem' )->search(
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
}


=head2 view_tag

Display a page of news items with a particular tag.

/news/tag/stuff    # News about 'stuff'

=cut

sub view_tag : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;

	my @tagged = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	})->search_related( 'tagset' )->search({
		resource_type => 'NewsItem',
	})->get_column( 'resource_id' )->all;

	$c->stash->{ news_items } = $c->model( 'DB::NewsItem' )->search(
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

	$c->stash->{ tag        } = $tag;
	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_item

View details of a news item.

=cut

sub view_item : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
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

	$c->stash->{ news_item } = $c->model( 'DB::NewsItem' )->search({
		url_title => $url_title,
		-and => [
			posted => { '<=' => \'current_timestamp' },
			posted => { '>=' => $month_start->ymd    },
			posted => { '<=' => $month_end->ymd      },
		],
		hidden => 0,
	})->first;

	unless ( $c->stash->{ news_item } ) {
		$c->flash->{ error_msg } = 'Failed to find specified news item.';
		$c->go( 'view_items' );
	}
}


# ========== ( utility methods ) ==========

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
