package ShinyCMS::Controller::Events;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

ShinyCMS::Controller::Events

=head1 DESCRIPTION

Controller for ShinyCMS events calendar.

=head1 METHODS

=cut



=head2 base

=cut

sub base : Chained( '/' ) : PathPart( 'events' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 get_events

Get a set of events from the database according to various criteria

=cut

sub get_events {
	my ( $self, $c, $count, $start_date, $end_date ) = @_;
	
	$count ||= 10;
	
	$start_date ||= DateTime->now;
	
	# Slightly confusing interaction of start and end dates here.  We want 
	# to return any event that finishes before the search range starts, or 
	# starts before the search range finishes.
	my $where = {};
	$where->{ end_date   } = { '>=' => $start_date->date };
	$where->{ start_date } = { '<=' => $end_date->date   } if $end_date;
	
	my @events = $c->model( 'DB::Event' )->search(
		$where,
		{
			order_by => 'start_date, end_date',
			rows     => $count,
		},
	);
	
	return \@events;
}


=head2 coming_soon

List events which are coming soon.

=cut

sub coming_soon : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ events } = $self->get_events( $c );
	
	$c->stash->{ template } = 'events/view_events.tt';
	
	$c->forward( 'Root', 'build_menu' );
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

