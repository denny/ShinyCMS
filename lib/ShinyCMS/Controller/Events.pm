package ShinyCMS::Controller::Events;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Events

=head1 DESCRIPTION

Controller for ShinyCMS events calendar.

=head1 METHODS

=cut



=head2 base

=cut

sub base : Chained( '/base' ) : PathPart( 'events' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Events';
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
	$where->{ end_date   } = { '>=' => $start_date->ymd };
	$where->{ start_date } = { '<=' => $end_date->ymd   } if $end_date;
	
	my @events = $c->model( 'DB::Event' )->search(
		$where,
		{
			order_by => [ 'start_date', 'end_date' ],
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
	
	my $start_date = DateTime->now;
	my $four_weeks = DateTime::Duration->new( weeks => 4 );
	my $end_date   = $start_date + $four_weeks;
	
	my $coming_events = $self->get_events( $c, 100, $start_date, $end_date );
	
	# Make sure we have at least 10 events (or the entire dataset, if fewer)
	my $events;
	if ( @$coming_events >= 10 ) {
		$events = $coming_events;
	}
	else {
		$events = $self->get_events( $c, 10 );
	}
	
	$c->stash->{ events } = $events;
	
	$c->stash->{ template } = 'events/view_events.tt';
}


=head2 view_month

View events starting in a given month

=cut

sub view_month : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $year, $month ) = @_;
	
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
	
	my @events = $c->model( 'DB::Event' )->search({
		-and => [
			end_date   => { '>=' => $month_start->ymd },
			start_date => { '<=' => $month_end->ymd   },
		],
	});
	
	$c->stash->{ events } = \@events;
	
	# Build some dates for prev/next links
	$c->stash->{ view_date } = DateTime->new( year => $year, month => $month );
	my $one_month  = DateTime::Duration->new( months => 1 );
	$c->stash->{ prev_date } = $c->stash->{ view_date } - $one_month;
	$c->stash->{ next_date } = $c->stash->{ view_date } + $one_month;
	
	$c->stash->{ template } = 'events/view_events.tt';
}


=head2 view_event

View details for a specific event

=cut

sub view_event : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_name ) = @_;
	
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
	
	$c->stash->{ event } = $c->model( 'DB::Event' )->search({
		url_name => $url_name,
		-and => [
			start_date => { '>=' => $month_start->ymd },
			start_date => { '<=' => $month_end->ymd   },
		],
	})->first;
}


=head2 search

Search the events section.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	return unless $c->request->param( 'search' );
	
	my $search = $c->request->param( 'search' );
	my $events = [];
	my @results = $c->model( 'DB::Event' )->search({
		-or => [
			name        => { 'LIKE', '%'.$search.'%'},
			description => { 'LIKE', '%'.$search.'%'},
			address     => { 'LIKE', '%'.$search.'%'},
			postcode    => { 'LIKE', '%'.$search.'%'},
		],
	});
	foreach my $result ( @results ) {
		# Pull out the matching search term and its immediate context
		my $match = '';
		if ( $result->name =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->description =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->address =~ m/$search/is ) {
			$match = $result->address . ', ' . $result->postcode;
		}
		elsif ( $result->postcode =~ m/$search/is ) {
			$match = $result->address . ', ' . $result->postcode;
		}
		# Tidy up and mark the truncation
		unless ( $match eq $result->name or $match eq $result->description 
				or $match eq $result->address or $match eq $result->postocde ) {
				$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
				$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
		}
		if ( $match eq $result->name ) {
			$match = substr $result->description, 0, 100;
			$match =~ s/\s\S+\s?$/ .../;
		}
		# Add the match string to the page result
		$result->{ match } = $match;
		
		# Push the result onto the results array
		push @$events, $result;
	}
	$c->stash->{ events_results } = $events;
}



=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2014 Shiny Ideas (www.shinyideas.co.uk).

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

