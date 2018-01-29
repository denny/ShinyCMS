package ShinyCMS::Controller::Admin::Polls;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Polls

=head1 DESCRIPTION

Controller for ShinyCMS poll admin features.

=head1 METHODS

=cut



=head2 base

Base method, sets up path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/polls' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit polls
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'administrate polls', 
		role     => 'Poll Admin',
		redirect => '/polls'
	});
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Admin::Polls';
}


=head2 list

Display a list of the polls

=cut

sub list : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ polls } = $c->model('DB::PollQuestion')->search(
		{
		},
		{
			order_by => { -desc => 'me.id' },
			prefetch => 'poll_answers',
		}
	);
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


=head2 save

Save a new/edited poll

=cut

sub save : Chained( 'base' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# TODO
}



=head1 AUTHOR

Denny de la Haye <2018@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2018 Denny de la Haye.

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

