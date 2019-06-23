package ShinyCMS::Controller::Tag;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use HTML::TagCloud;


=head1 NAME

ShinyCMS::Controller::Tag

=head1 DESCRIPTION

Controller for site-wide tag features.

=cut


has tags_in_cloud => (
	isa     => 'Int',
	is      => 'ro',
	default => 50,
);


=head1 METHODS

=head2 base

=cut

sub base : Chained( '/base' ) : PathPart( 'tag' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the name of the controller
	$c->stash->{ controller } = 'Tag';
}


=head2 index

Forward to tag list.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'view_tags' );
}


=head2 view_tags

Display a list of tags currently in use on the site.

=cut

sub view_tags : Chained( 'base' ) : PathPart( 'tag-list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $tag_info = $self->get_tags( $c );

	my @tags = keys %$tag_info;

	@tags = sort { lc $a cmp lc $b } @tags;

	$c->stash->{ tags     } = \@tags;
	$c->stash->{ tag_info } = $tag_info;
}


=head2 tag_cloud

Display a tag cloud.

=cut

sub tag_cloud : Chained( 'base' ) : PathPart( 'tag-cloud' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $tag_info = $self->get_tags( $c );
	my @tags = keys %$tag_info;

	my $cloud = HTML::TagCloud->new;
	foreach my $tag ( @tags ) {
		$cloud->add( $tag, $c->uri_for( '/tag', $tag ), $tag_info->{ $tag }->{ count } );
	}

	$c->stash->{ tag_cloud_html } = $cloud->html_and_css( $self->tags_in_cloud );
}


=head2 view_tag

Display info for a specified tag

=cut

sub view_tag : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;

	my $tag_info = $self->get_tag( $c, $tag );

	$c->stash->{ tag      } = $tag;
	$c->stash->{ tag_info } = $tag_info;
}


# ========== ( utility methods ) ==========

=head2 get_tags

Get a list of tags.

=cut

sub get_tags {
	my ( $self, $c ) = @_;

	my @tags = $c->model( 'DB::Tagset' )->search({
		hidden => 0,
	})->search_related( 'tags' )->all;

	my $tag_info = {};
	foreach my $tag ( @tags ) {
		$tag_info->{ $tag->tag }->{ count } += 1;
	}

	# TODO: Hide tags that are only used on future-dated content

	return $tag_info;
}


=head2 get_tag

Get all the info about a specific tag.

=cut

sub get_tag {
	my ( $self, $c, $tag ) = @_;

	my @tag_data = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});

	my $now = DateTime->now;

	my $tag_info = ();
	foreach my $data ( @tag_data ) {
		my $tagset = $data->tagset;
		my $resource = $c->model( 'DB::'.$tagset->resource_type )->search({
			id => $tagset->resource_id,
			hidden => 0,
		})->first;
		next unless $resource;
		my $item = {};
		if ( $tagset->resource_type eq 'BlogPost' ) {
			next if $resource->posted > $now;	# Hide future-dated posts
			$item->{ title  } = $resource->title;
			$item->{ link   } = $c->uri_for( '/blog', $resource->posted->year, $resource->posted->month, $resource->url_title )->as_string;
			$item->{ type   } = 'blog post';
			$item->{ object } = $resource;
		}
		elsif ( $tagset->resource_type eq 'ForumPost' ) {
			next if $resource->posted > $now;	# Hide future-dated posts
			$item->{ title  } = $resource->title;
			$item->{ link   } = $c->uri_for( '/forums', $resource->forum->section->url_name, $resource->forum->url_name, $resource->id, $resource->url_title )->as_string;
			$item->{ type   } = 'forum post';
			$item->{ object } = $resource;
		}
		elsif ( $tagset->resource_type eq 'ShopItem' ) {
			$item->{ title  } = $resource->name;
			$item->{ link   } = $c->uri_for( '/scene', 'item', $resource->code )->as_string;
			$item->{ type   } = 'shop item';
			$item->{ object } = $resource;
		}
		else {
			next;
		}

		# TODO: other resource types

		# Add onto the end of the list
		unshift @$tag_info, $item;
	}

	return $tag_info;
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
