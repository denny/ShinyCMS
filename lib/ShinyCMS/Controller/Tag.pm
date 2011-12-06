package ShinyCMS::Controller::Tag;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Tag

=head1 DESCRIPTION

Controller for site-wide tag features.

=head1 METHODS

=cut


=head2 index

Forward to tag list.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	$c->go( 'view_tags' );
}


=head2 base

=cut

sub base : Chained( '/' ) : PathPart( 'tag' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Tag';
}


=head2 get_tags

Get a list of tags.

=cut

sub get_tags {
	my ( $self, $c ) = @_;
	
	my @tags = $c->model( 'DB::Tag' )->all;
	
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
		my $resource = $c->model( 'DB::'.$tagset->resource_type )->find({
			id => $tagset->resource_id,
		});
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
			$item->{ link   } = $c->uri_for( '/shop', 'item', $resource->code )->as_string;
			$item->{ type   } = 'shop item';
			$item->{ object } = $resource;
		}
		
		# TODO: other resource types
		
		# Add onto the end of the list
		unshift @$tag_info, $item;
	}
	
	return $tag_info;
}


=head2 view_tags

Display a list of tags currently in use on the site.

=cut

sub view_tags : Chained( 'base' ) : PathPart( 'tag-list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my $tag_info = $self->get_tags( $c );
	
	my @tags = keys %$tag_info;
	
	@tags = sort { lc $a cmp lc $b } @tags;
	
	$c->stash->{ tags     } = \@tags;
	$c->stash->{ tag_info } = $tag_info;
}


=head2 tag_cloud

TODO: Display a tag cloud.

=cut

sub tag_cloud : Chained( 'base' ) : PathPart( 'tag-cloud' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my $tags = $self->get_tags( $c );
}


=head2 view_tag

Display info for a specified tag

=cut

sub view_tag : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $tag ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my $tag_info = $self->get_tag( $c, $tag );
	
	$c->stash->{ tag      } = $tag;
	$c->stash->{ tag_info } = $tag_info;
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

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

