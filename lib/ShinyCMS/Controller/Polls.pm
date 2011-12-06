package ShinyCMS::Controller::Polls;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Polls

=head1 DESCRIPTION

Controller for ShinyCMS polls.

=head1 METHODS

=cut



=head2 base

Base method, sets up path.

=cut

sub base : PathPart( 'polls' ) : Chained( '/' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Polls';
}


=head2 view_polls

View polls.

=cut

sub view_polls : PathPart( '' ) : Chained( 'base' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build up the CMS menu
	$c->forward( 'Root', 'build_menu' );
	
	my @polls = $c->model( 'DB::PollQuestion' )->search(
		{},
		{
			order_by => { -desc => 'id' },
		},
	);
	
	$c->stash->{ polls } = \@polls;
}


=head2 view_poll

View a poll.

=cut

sub view_poll : PathPart( '' ) : Chained( 'base' ) : Args( 1 ) {
	my ( $self, $c, $poll_id ) = @_;
	
	# Build up the CMS menu
	$c->forward( 'Root', 'build_menu' );
	
	$c->stash->{ poll } = $c->model( 'DB::PollQuestion' )->find({
		id => $poll_id,
	});
}


=head2 vote

Vote in a poll.

=cut

sub vote : PathPart( 'vote' ) : Chained( 'base' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $poll = $c->model( 'DB::PollQuestion' )->find({
		id => $c->request->param( 'poll' ),
	});
	
	if ( $c->user_exists ) {
		# Logged-in user voting
		my $existing_vote = $poll->poll_user_votes->find({
			user => $c->user->id,
		});
		if ( $existing_vote ) {
			if ( $c->request->param( 'answer' ) == $existing_vote->answer->id ) {
				$c->flash->{ status_msg } = 'You have already voted for \''.
					$existing_vote->answer->answer .'\' in this poll.';
			}
			else {
				$c->flash->{ status_msg } = 'You had already voted in this poll, for \''.
					$existing_vote->answer->answer .
					'\'.  Your vote has now been changed to \''.
					$poll->poll_answers->find({
						id => $c->request->param( 'answer' ),
					})->answer .'\'.';
				$existing_vote->update({
					answer     => $c->request->param( 'answer' ),
					ip_address => $c->request->address,
				});
			}
		}
		else {
			# Check for an anonymous vote from this IP address
			my $anon_vote = $poll->poll_anon_votes->find({
				ip_address => $c->request->address,
			});
			if ( $anon_vote ) {
				# Remove the anon vote if one exists
				$c->flash->{ status_msg } = 'Somebody from your IP address had '.
					'already voted anonymously in this poll, for \''.
					$anon_vote->answer->answer .
					'\'.  That vote has been replaced by your vote for \''.
					$poll->poll_answers->find({
						id => $c->request->param( 'answer' ),
					})->answer .'\'.';
				$anon_vote->delete;
			}
			# Store the user-linked vote
			$poll->poll_user_votes->create({
				answer     => $c->request->param( 'answer' ),
				user       => $c->user->id,
				ip_address => $c->request->address,
			});
		}
	}
	else {
		# Anonymous vote
		my $anon_vote = $poll->poll_anon_votes->find({
			ip_address => $c->request->address,
		});
		my $user_vote = $poll->poll_user_votes->find({
			ip_address => $c->request->address,
		});
		if ( $anon_vote or $user_vote ) {
			# Return an 'already voted' error
			$c->flash->{ error_msg } = 
				'Somebody with your IP address has already voted in this poll.';
		}
		else {
			# Add the vote
			$poll->poll_anon_votes->create({
				answer     => $c->request->param( 'answer' ),
				ip_address => $c->request->address,
			});
		}
	}
	
	$c->response->redirect( $c->uri_for( $poll->id ) );
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

