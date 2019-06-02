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

=head2 base

Base method, sets up path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/polls' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to see if user is allowed to administrate polls
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'administrate polls',
		role     => 'Poll Admin',
		redirect => '/polls'
	});

	# Stash the name of the controller
	$c->stash->{ admin_controller } = 'Polls';
}


=head2 index

Display list of news items

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_polls' );
}


=head2 list_polls

Display a list of the polls

=cut

sub list_polls : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
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
		$poll = $c->model('DB::PollQuestion')->find({
			id => $c->request->param( 'poll_id' ),
		});

		if ( defined $c->request->param( 'delete' ) ) {
			$poll->poll_anon_votes->delete;
			$poll->poll_user_votes->delete;
			$poll->poll_answers->delete;
			$poll->delete;

			$c->response->redirect( $c->uri_for( '/admin/polls' ) );
			$c->detach;
		}
	}

	# Get the new details from the form
	my $details = {
		question => $c->request->param( 'question' ) || '',
		hidden   => $c->request->param( 'hidden' ) ? 1 : 0,
	};

	if ( $poll ) {
		# Update poll question
		$poll->update( $details );
		# Update poll answers
		my $answers = {};
		foreach my $input ( keys %{$c->request->params} ) {
			next unless $input =~ m{^answer_(\d+)$};
			$poll->poll_answers->find({
				id => $1,
			})->update({ answer => $c->request->param( $input ) });
		}
		# TODO: Update votes
	}
	else {
		# Create poll question
		$poll = $c->model('DB::PollQuestion')->create( $details );
	}

	# Redirect to poll's edit page
	$c->response->redirect( $c->uri_for( '/admin/polls/edit', $poll->id ) );
}


=head2 add_answer

Add a new answer to an existing poll

=cut

sub add_answer : Chained( 'base' ) : PathPart( 'add-answer' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Fetch poll
	my $poll = $c->model('DB::PollQuestion')->find({
		id => $c->request->param( 'poll_id' ),
	});
	# Add new answer
	$poll->poll_answers->create({
		answer => $c->request->param( 'new_answer' ),
	});

	# Redirect to poll's edit page
	$c->response->redirect( $c->uri_for( '/admin/polls/edit', $poll->id ) );
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
