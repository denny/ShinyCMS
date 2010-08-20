package ShinyCMS::Controller::Tag;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

ShinyCMS::Controller::Tag

=head1 DESCRIPTION

Controller for site-wide tag features.

=head1 METHODS

=cut


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
	
	my @tags = $c->model( 'DB::Tag' )->search(
		{
			
		},
		{
			group_by => 'tag',
		},
	);
}


=head2 list_tags

Display a list of tags used on the site.

=cut

sub list_tags : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $tags = $self->get_tags( $c );
}


=head2 tag_cloud

Display a tag cloud.

=cut

sub tag_cloud : Chained( 'base' ) : PathPart( 'cloud' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $tags = $self->get_tags( $c );
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

1;

