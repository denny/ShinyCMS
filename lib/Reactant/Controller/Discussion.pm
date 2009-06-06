package Reactant::Controller::Discussion;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Reactant::Controller::Discussion - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub thread : Path('thread') : CaptureArgs(1) {
    my ( $self, $c, $discussion_id ) = @_;
	
	# Get the comments from the db
	my @comments = $c->model('DB::Comment')->search({
		discussion => $discussion_id,
		parent     => undef,
	});
	
	# Build up the thread
	foreach my $comment ( @comments ) {
		$c->log->debug( 'Comment ID: '.$comment->id );
		$comment->{ children } = $self->get_subthread( $c, $discussion_id, $comment->id );
	}
	
	$c->stash->{ comments } = \@comments;
}


# Mmmm, recursion.
sub get_subthread : Private {
	my( $self, $c, $discussion_id, $parent ) = @_;
	
	my @comments = $c->model('DB::Comment')->search({
		discussion => $discussion_id,
		parent     => $parent,
	});
	
	return unless @comments;
	
	foreach my $comment ( @comments ) {
		$c->log->debug( 'Comment ID: '.$comment->id );
		$comment->{ children } = $self->get_subthread( $c, $discussion_id, $comment->id );
	}
	
	return \@comments;
}



=head1 AUTHOR

Denny de la Haye <reactant.2009@contentmanaged.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

