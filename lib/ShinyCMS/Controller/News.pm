package ShinyCMS::Controller::News;

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::News

=head1 DESCRIPTION

Controller for ShinyCMS news section.

=head1 METHODS

=cut


=head2 base

=cut

sub base : Chained('/') : PathPart('news') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
}


=head2 view_items

=cut

sub view_items : Chained('base') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my @news = $c->model('DB::NewsItem')->search(
		{ },
		{ order_by => 'posted desc',
		  limit => 10 },
	);
	$c->stash->{ news_posts } = \@news;
}


=head2 view_item

=cut

sub view_item : Chained('base') : PathPart('') : Args(3) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ news_post } = $c->model('DB::NewsItem')->search(
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	)->first;
}


=head2 list_items

=cut

sub list_items : Chained('base') : PathPart('list-items') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @news = $c->model('DB::NewsItem')->search(
		{ },
		{ order_by => 'posted desc' }
	);
	$c->stash->{ news_posts } = \@news;
}


=head2 edit_item

=cut

sub edit_post : Chained('base') : PathPart('edit') : Args(1) {
	my ( $self, $c, $post_id ) = @_;
	
	$c->stash->{ news_post } = $c->model('DB::NewsItem')->find({
		id => $post_id,
	});
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

1;

