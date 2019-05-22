package ShinyCMS::Controller::Admin::Polls;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Polls

=head1 DESCRIPTION

Controller for ShinyCMS poll admin features.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);


=head1 METHODS

=cut


=head2 base

Base method, sets up path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/polls' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to administrate polls
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'administrate polls',
		role     => 'Poll Admin',
		redirect => '/polls'
	});
	
	# Stash the name of the controller
	$c->stash->{ admin_controller } = 'Polls';
}


=head2 list_polls

Display a list of the polls

=cut

sub list_polls : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ polls } = $c->model('DB::PollQuestion')->search(
		{},
		{
			order_by => { -desc => 'created' },
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
}


=head2 add_poll

Add a new poll

=cut

sub add_poll : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ template } = 'admin/polls/edit_poll.tt';
}


=head2 edit_poll

Edit a poll

=cut

sub edit_poll : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $poll_id ) = @_;
	
	$c->stash->{ poll } = $c->model('DB::PollQuestion')->find(
		{
			id => $poll_id,
		},
		{
			prefetch => 'poll_answers',
		}
	);
}


=head2 save_poll

Save a new/edited poll

=cut

sub save_poll : Chained( 'base' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $poll;
	if ( $c->request->param( 'poll_id' ) ) {
		# Fetch poll details
		$poll = $c->model('DB::PollQuestion')->find({
			id => $c->request->param( 'poll_id' ),
		});
		
		# TODO: delete poll
	}
	
	# Get the new details
	# TODO: answers
	my $hidden  = $c->request->param( 'hidden' ) ? 1 : 0;
	my $details = {
		question => $c->request->param( 'question' ) || '',
		hidden   => $hidden,
	};
	
	if ( $poll ) {
		# Update poll question
		$poll->update( $details );
		# TODO: answers
	}
	else {
		# Create poll question
		$poll = $c->model('DB::PollQuestion')->create( $details );
		# TODO: answers
	}
	
	# Redirect to poll's edit page
	$c->response->redirect( $c->uri_for( '/admin/polls/edit', $poll->id ) );
}


=head2 add_answer

Add a new answer to an existing poll

=cut

sub add_answer : Chained( 'base' ) : PathPart( 'add-answer' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $poll = $c->model('DB::PollQuestion')->find({
		id => $c->request->param( 'poll_id' ),
	});
	
	# TODO
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
