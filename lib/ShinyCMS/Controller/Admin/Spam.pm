package ShinyCMS::Controller::Admin::Spam;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Spam

=head1 DESCRIPTION

Controller for ShinyCMS spam comment administration.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 50,
);


=head1 METHODS

=head2 base

Set up the path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/spam' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'manage the spam comments queue',
		role     => 'Discussion Admin',
		redirect => '/admin'
	});

	$c->stash->{ spam_comments } = $c->model( 'DB::Comment' )->search({ spam => 1 });

	$c->stash->{ admin_controller } = 'Spam';
}


=head2 index

Show the list of spam comments

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_spam_comments' );
}


=head2 list_spam_comments

List all spam comments

=cut

sub list_spam_comments : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ spam_comments } = $c->model( 'DB::Comment' )->search(
		{
			spam => 1,
		},
		{
			order_by => { -desc => 'posted' },
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		},
	);
}


=head2 update_spam

Either remove some spam flags, or delete some spam comments.

=cut

sub update_spam : Chained( 'base' ) : PathPart( 'update' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $comment_uids = $c->request->param( 'comment_uid' );

	my $comments = $c->stash->{ spam_comments }->search({ uid => $comment_uids });

	if ( $c->request->param( 'action' ) eq 'delete' ) {
		$comments->delete;
		$c->flash->{ status_msg } = 'Spam comments deleted from database';
	}
	elsif ( $c->request->param( 'action' ) eq 'not-spam' ) {
		$comments->update({ spam => 0 });
		$c->flash->{ status_msg } = 'Spam flags removed';
	}

	$c->response->redirect( $c->uri_for( '/admin/spam' ) );
}


=head2 mark_all_as_not_spam

Remove spam flag from all comments

=cut

sub mark_all_as_not_spam : Chained( 'base' ) : PathPart( 'mark-all-not-spam' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ spam_comments }->update({ spam => 0 });

	$c->flash->{ status_msg } = "All comments marked as 'not spam'";

	$c->response->redirect( $c->uri_for( '/admin/spam' ) );
}


=head2 delete_all_spam

Delete all spam comments from database

=cut

sub delete_all_spam : Chained( 'base' ) : PathPart( 'delete-all' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	while ( my $comment = $c->stash->{ spam_comments }->next ) {
		$comment->comments_like->delete;
	}
	$c->stash->{ spam_comments }->delete;

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'All spam comments deleted from database';

	# Bounce back to the list of roles
	$c->response->redirect( $c->uri_for( '/admin/spam' ) );
}



=head1 AUTHOR

Denny de la Haye <2020@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2020 Denny de la Haye.

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
