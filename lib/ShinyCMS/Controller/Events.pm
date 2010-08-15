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
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 view_event

View details for a specific event

=cut

sub view_event : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_name ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ event } = $c->model('DB::Event')->search(
		url_name => $url_name,
		-nest => \[ 'year(start_date)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(start_date) = ?', [ plain_value => $month ] ],
	)->first;
}


=head2 list_events

List all events for the back-end

=cut

sub list_events : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $events = $self->get_events( $c, 100 );
	
	$c->stash->{ events } = $events;
}


=head2 add_event

Add a new event

=cut

sub add_event : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to add events.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a news admin
	unless ( $c->user->has_role( 'Events Admin' ) ) {
		$c->stash->{ error_msg } = 'You do not have the ability to add events.';
		$c->response->redirect( '/events' );
	}
	
	$c->{ stash }->{ images } = $self->get_image_filenames( $c );
	
	$c->stash->{ template } = 'events/edit_event.tt';
}


=head2 edit_event

Edit an existing event

=cut

sub edit_event : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $event_id ) = @_;
	
	# Bounce if user isn't logged in
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to add events.';
		$c->go('/user/login');
	}
	
	# Bounce if user isn't a news admin
	unless ( $c->user->has_role( 'Events Admin' ) ) {
		$c->stash->{ error_msg } = 'You do not have the ability to edit events.';
		$c->response->redirect( '/events' );
	}
	
	$c->{ stash }->{ images } = $self->get_image_filenames( $c );
	
	$c->{ stash }->{ event  } = $c->model( 'DB::Event' )->find({
		id => $event_id,
	});
}


=head2 add_event_do

Process adding an event

=cut

sub add_event_do : Chained( 'base' ) : PathPart( 'add-event-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check user privs
	die unless $c->user->has_role( 'Events Admin' );	# TODO
	
	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );
	
	# Add the item
	my $item = $c->model( 'DB::Event' )->create({
		name        => $c->request->param( 'name'        ),
		url_name    => $c->request->param( 'url_name'    ),
		description => $c->request->param( 'description' ),
		image       => $c->request->param( 'image'       ),
		start_date  => $start_date,
		end_date    => $end_date,
		postcode    => $c->request->param( 'postcode'    ),
		link        => $c->request->param( 'link'        ),
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
	
	# Check user privs
	die unless $c->user->has_role( 'Events Admin' );	# TODO
	
	my $start_date = $c->request->param( 'start_date' ) .' '. $c->request->param( 'start_time' );
	my $end_date   = $c->request->param( 'end_date'   ) .' '. $c->request->param( 'end_time'   );
	
	# Add the item
	my $item = $c->model( 'DB::Event' )->find({
		id => $event_id,
	})->update({
		name        => $c->request->param( 'name'        ),
		url_name    => $c->request->param( 'url_name'    ),
		description => $c->request->param( 'description' ),
		image       => $c->request->param( 'image'       ),
		start_date  => $start_date,
		end_date    => $end_date,
		postcode    => $c->request->param( 'postcode'    ),
		link        => $c->request->param( 'link'        ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Event updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
}


=head2 get_image_filenames

Get a list of available image filenames.

TODO: This method is duplicated between Pages and Events
      - refactor into FileManager

=cut

sub get_image_filenames {
	my ( $self, $c ) = @_;
	
	my $image_dir = $c->path_to( 'root/static/cms-uploads/images' );
	opendir( my $image_dh, $image_dir ) 
		or die "Failed to open image directory $image_dir: $!";
	my $images = ();
	foreach my $filename ( readdir( $image_dh ) ) {
		push @$images, $filename unless $filename =~ m/^\./; # skip hidden files
	}
	
	return $images;
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

