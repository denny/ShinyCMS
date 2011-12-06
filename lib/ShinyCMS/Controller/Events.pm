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

sub base : Chained( '/' ) : PathPart( 'events' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the current date
	$c->stash->{ now } = DateTime->now;
	
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
	
	$c->forward( 'Root', 'build_menu' );
	
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
	
	$c->forward( 'Root', 'build_menu' );
	
	my @events = $c->model( 'DB::Event' )->search({
		-and => [
			-nest => \[ 'year(start_date)  = ?', [ plain_value => $year  ] ],
			-nest => \[ 'month(start_date) = ?', [ plain_value => $month ] ],
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
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ event } = $c->model( 'DB::Event' )->search({
		url_name => $url_name,
		-nest => \[ 'year(start_date)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(start_date) = ?', [ plain_value => $month ] ],
	})->first;
}


=head2 admin_get_events

Get the full list of events from the database

=cut

sub admin_get_events {
	my ( $self, $c, $count, $start_date, $end_date ) = @_;
	
	$count ||= 10;
	
	# Slightly confusing interaction of start and end dates here.  We want 
	# to return any event that finishes before the search range starts, or 
	# starts before the search range finishes.
	my $where = {};
	$where->{ end_date   } = { '>=' => $start_date->date } if $start_date;
	$where->{ start_date } = { '<=' => $end_date->date   } if $end_date;
	
	my @events = $c->model( 'DB::Event' )->search(
		$where,
		{
			order_by => { -desc => [ 'start_date', 'end_date' ] },
			rows     => $count,
		},
	);
	
	return \@events;
}


=head2 list_events

List all events for the back-end

=cut

sub list_events : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'view the list of events', 
		role     => 'Events Admin',
		redirect => '/events'
	});
	
	my $events = $self->admin_get_events( $c, 50 );
	
	$c->stash->{ events } = $events;
}


=head2 add_event

Add a new event

=cut

sub add_event : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add an event', 
		role     => 'Events Admin',
		redirect => '/events'
	});
	
	# Stash a list of images present in the event-images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'event-images' );
	
	$c->stash->{ template } = 'events/edit_event.tt';
}


=head2 edit_event

Edit an existing event

=cut

sub edit_event : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $event_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit an event', 
		role     => 'Events Admin',
		redirect => '/events'
	});
	
	# Stash a list of images present in the event-images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'event-images' );
	
	$c->{ stash }->{ event  } = $c->model( 'DB::Event' )->find({
		id => $event_id,
	});
}


=head2 add_event_do

Process adding an event

=cut

sub add_event_do : Chained( 'base' ) : PathPart( 'add-event-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add an event', 
		role     => 'Events Admin',
		redirect => '/events'
	});
	
	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );
	
	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' );
	$url_name  ||= $c->request->param( 'name'     );
	$url_name   =~ s/\s+/-/g;
	$url_name   =~ s/-+/-/g;
	$url_name   =~ s/[^-\w]//g;
	$url_name   =  lc $url_name;
	
	# Add the item
	my $item = $c->model( 'DB::Event' )->create({
		name         => $c->request->param( 'name'         ),
		url_name     => $url_name,
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		start_date   => $start_date,
		end_date     => $end_date,
		postcode     => $c->request->param( 'postcode'     ),
		email        => $c->request->param( 'email'        ),
		link         => $c->request->param( 'link'         ),
		booking_link => $c->request->param( 'booking_link' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Event added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
}


=head2 edit_event_do

Process editing an event

=cut

sub edit_event_do : Chained( 'base' ) : PathPart( 'edit-event-do' ) : Args( 1 ) {
	my ( $self, $c, $event_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit an event', 
		role     => 'Events Admin',
		redirect => '/events'
	});
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->model( 'DB::Event' )->search({ id => $event_id })->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Event deleted';
		
		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}
	
	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );
	
	# Sanitise the url_name
	my $url_name = $c->request->param( 'url_name' );
	$url_name  ||= $c->request->param( 'name'     );
	$url_name   =~ s/\s+/-/g;
	$url_name   =~ s/-+/-/g;
	$url_name   =~ s/[^-\w]//g;
	$url_name   =  lc $url_name;
	
	# Add the item
	my $item = $c->model( 'DB::Event' )->find({
		id => $event_id,
	})->update({
		name         => $c->request->param( 'name'         ),
		url_name     => $url_name,
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		start_date   => $start_date,
		end_date     => $end_date,
		postcode     => $c->request->param( 'postcode'     ),
		email        => $c->request->param( 'email'        ),
		link         => $c->request->param( 'link'         ),
		booking_link => $c->request->param( 'booking_link' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Event updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
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
		# Tidy up and mark the truncation
		unless ( $match eq $result->name or $match eq $result->description ) {
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

