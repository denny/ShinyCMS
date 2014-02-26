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

=cut


=head2 index

Display list of news items

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
	
    $c->go('list_items');
}


=head2 base

Set the base path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/news' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the controller name
	$c->stash->{ controller } = 'Admin::News';
}


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


=head2 list_items

List news items.

=cut

sub list_items : Chained( 'base' ) : PathPart( 'list' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'list all news items', 
		role     => 'News Admin',
		redirect => '/news'
	});
	
	$page  ||= 1;
	$count ||= 20;
	
	my $posts = $self->get_posts( $c, $page, $count );
	
	$c->stash->{ news_items } = $posts;
}


=head2 add_item

=cut

sub add_item : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add news items', 
		role     => 'News Admin',
		redirect => '/news'
	});
	
	$c->stash->{ template } = 'admin/news/edit_item.tt';
}


=head2 add_do

=cut

sub add_do : Chained( 'base' ) : PathPart( 'add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add news items', 
		role     => 'News Admin',
		redirect => '/news'
	});
	
	# Tidy up the URL title
	my $url_title = $c->request->param( 'url_title' );
	$url_title  ||= $c->request->param( 'title'     );
	$url_title   =~ s/\s+/-/g;
	$url_title   =~ s/-+/-/g;
	$url_title   =~ s/[^-\w]//g;
	$url_title   =  lc $url_title;
	
	# TODO: catch and fix duplicate year/month/url_title combinations
	
	# Add the item
	my $hidden = $c->request->param( 'hidden' ) ? 1 : 0;
	my $item = $c->model( 'DB::NewsItem' )->create({
		author      => $c->user->id,
		title       => $c->request->param( 'title'       ),
		url_title   => $url_title || undef,
		body        => $c->request->param( 'body'        ),
		related_url => $c->request->param( 'related_url' ),
		hidden      => $hidden,
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
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit news items', 
		role     => 'News Admin',
		redirect => '/news'
	});
	
	# Stash the news item
	$c->stash->{ news_item } = $c->model( 'DB::NewsItem' )->find({
		id => $item_id,
	});
}


=head2 edit_do

=cut

sub edit_do : Chained( 'base' ) : PathPart( 'edit-do' ) : Args( 1 ) {
	my ( $self, $c, $item_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit news items', 
		role     => 'News Admin',
		redirect => '/news'
	});
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param( 'delete' ) eq 'Delete' ) {
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
	
	# Perform the update
	my $hidden = $c->request->param( 'hidden' ) ? 1 : 0;
	my $item = $c->model( 'DB::NewsItem' )->find({
		id => $item_id,
	})->update({
		title       => $c->request->param( 'title'       ),
		url_title   => $url_title || undef,
		body        => $c->request->param( 'body'        ),
		related_url => $c->request->param( 'related_url' ),
		hidden      => $hidden,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'News item updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $item_id ) );
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

