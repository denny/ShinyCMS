package ShinyCMS::Controller::Shop;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Shop

=head1 DESCRIPTION

Controller for ShinyCMS's online shop functionality.

=head1 METHODS

=cut


=head2 index

For now, forwards to the category list.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# TODO: Storefront - special offers, featured items, new additions, etc
	
	$c->go('view_categories');
}


=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained('/') : PathPart('shop') : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Shop';
}


=head2 view_categories

View all the categories (for shop-user).

=cut

sub view_categories : Chained( 'base' ) : PathPart( 'categories' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	my @categories = $c->model( 'DB::ShopCategory' )->search({ parent => undef });
	$c->stash->{ categories } = \@categories;
}


=head2 no_category_specified

Catch people traversing the URL path by hand and show them something useful.

=cut

sub no_category_specified : Chained( 'base' ) : PathPart( 'category' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'view_categories' );
}


=head2 get_category

Stash details relating to the specified category.

=cut

sub get_category : Chained( 'base' ) : PathPart( 'category' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $category_id ) = @_;
	
	if ( $category_id =~ /\D/ ) {
		# non-numeric identifier (category url_name)
		$c->stash->{ category } = $c->model( 'DB::ShopCategory' )->find( { url_name => $category_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ category } = $c->model( 'DB::ShopCategory' )->find( { id => $category_id } );
	}
	
	unless ( $c->stash->{ category } ) {
		$c->flash->{ error_msg } = 
			'Category not found - please choose from the options below';
		$c->go( 'view_categories' );
	}
}


=head2 get_recent_items

Fetch items in the specified category.

=cut

sub get_category_items {
	my ( $self, $c, $category_id, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my @items = $c->model( 'DB::ShopCategory' )->find(
		{
			id => $category_id,
		}
	)->items->search(
		{},
		{
			page     => $page,
			rows     => $count,
		}
	);
	
	return \@items;
}


=head2 view_category

View all items in the specified category.

=cut

sub view_category : Chained( 'get_category' ) : PathPart( '' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Shop }->{ items_per_page };
	
	my $items = $self->get_category_items( $c, $c->stash->{ category }->id, $page, $count );
	$c->stash->{ shop_items } = $items;
}


=head2 get_recent_items

Fetch recently-added items.

=cut

sub get_recent_items {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my @items = $c->model( 'DB::ShopItem' )->search(
		{},
		{
			order_by => { -desc => 'added' },
			page     => $page,
			rows     => $count,
		}
	);
	
	return \@items;
}


=head2 recent_items

View recently-added items.

=cut

sub recent_items : Chained( 'base' ) : PathPart( 'recent' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Shop }->{ items_per_page };
	
	my $items = $self->get_recent_items( $c, $page, $count );
	
	$c->stash->{ recent_items } = $items;
}


=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained('base') : PathPart('item') : CaptureArgs(1) {
	my ( $self, $c, $item_id ) = @_;
	
	if ( $item_id =~ /\D/ ) {
		# non-numeric identifier (product code)
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { code => $item_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ item } = $c->model('DB::ShopItem')->find( { id => $item_id } );
	}
	
	# TODO: 404 handler - should present user with a search feature and helpful guidance
	die "Item not found: $item_id" unless $c->stash->{ item };
}


=head2 view_item

View an item.

=cut

sub view_item : Chained('get_item') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
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

