package ShinyCMS::Controller::Admin::News;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::News

=head1 DESCRIPTION

Controller for ShinyCMS news admin features.

=cut


has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has hide_new_items => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);


=head1 METHODS

=head2 base

Set the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/news' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'add/edit/delete news items',
		role     => 'News Admin',
		redirect => '/news'
	});

	# Stash the controller name
	$c->stash->{ admin_controller } = 'News';
}


=head2 index

Display list of news items

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_items' );
}


=head2 list_items

List news items.

=cut

sub list_items : Chained( 'base' ) : PathPart( 'list' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;

	$page  ||= 1;
	$count ||= 20;

	my $posts = $self->get_posts( $c, $page, $count );

	$c->stash->{ news_items } = $posts;
}


=head2 add_item

=cut

sub add_item : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ template } = 'admin/news/edit_item.tt';
}


=head2 add_do

=cut

sub add_do : Chained( 'base' ) : PathPart( 'add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;

	# TODO: catch and fix duplicate year/month/url_title combinations

	# Add the item
	my $item = $c->model( 'DB::NewsItem' )->create({
		author      => $c->user->id,
		title       => $c->request->param( 'title'       ),
		url_title   => $url_title,
		body        => $c->request->param( 'body'        ),
		related_url => $c->request->param( 'related_url' ),
		hidden      => $c->request->param( 'hidden'      ) ? 1 : 0,
	});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'News item added';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item->id ) );
}


=head2 edit_item

=cut

sub edit_item : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $item_id ) = @_;

	# Stash the news item
	$c->stash->{ news_item } = $c->model( 'DB::NewsItem' )->find({
		id => $item_id,
	});
}


=head2 edit_do

=cut

sub edit_do : Chained( 'base' ) : PathPart( 'edit-do' ) : Args( 1 ) {
	my ( $self, $c, $item_id ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->model( 'DB::NewsItem' )->search({ id => $item_id })->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'News item deleted';

		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}

	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;

	# TODO: catch and fix duplicate year/month/url_title combinations

	my $posted = $c->request->param( 'posted_date' ) .' '. $c->request->param( 'posted_time' );

	# Perform the update
	my $item = $c->model( 'DB::NewsItem' )->find({
		id => $item_id,
	})->update({
		title       => $c->request->param( 'title'       ),
		url_title   => $url_title,
		body        => $c->request->param( 'body'        ),
		related_url => $c->request->param( 'related_url' ),
		posted      => $posted,
		hidden      => $c->request->param( 'hidden'      ) ? 1 : 0,
	});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'News item updated';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item_id ) );
}


# ========== ( utility methods ) ==========

=head2 get_posts

Get the specified number of recent news posts.

=cut

sub get_posts {
	my ( $self, $c, $page, $count ) = @_;

	$page  ||= 1;
	$count ||= 20;

	my @posts = $c->model( 'DB::NewsItem' )->search(
		{},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);

	return \@posts;
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
