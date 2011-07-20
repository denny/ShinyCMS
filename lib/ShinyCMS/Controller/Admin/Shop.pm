package ShinyCMS::Controller::Admin::Shop;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Shop

=head1 DESCRIPTION

Controller for ShinyCMS shop admin features.

=head1 METHODS

=cut


=head2 index

For now, forwards to the category list.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->go( 'list' );
}


=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained( '/' ) : PathPart( 'admin/shop' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Shop';
}


=head2 list_categories

List all the categories (for admin).

=cut

sub list_categories : Chained('base') : PathPart('list-categories') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @categories = $c->model('DB::ShopCategory')->search({ parent => undef });
	$c->stash->{ categories } = \@categories;
}


=head2 get_category

Stash details and items relating to the specified category.

=cut

sub get_category : Chained('base') : PathPart('category') : CaptureArgs(1) {
	my ( $self, $c, $category_id ) = @_;
	
	if ( $category_id =~ /\D/ ) {
		# non-numeric identifier (category url_name)
		$c->stash->{ category } = $c->model('DB::ShopCategory')->find( { url_name => $category_id } );
	}
	else {
		# numeric identifier
		$c->stash->{ category } = $c->model('DB::ShopCategory')->find( { id => $category_id } );
	}
	
	# TODO: better 404 handler here?
	unless ( $c->stash->{ category } ) {
		$c->flash->{ error_msg } = 
			'Specified category not found - please select from the options below';
		$c->go('view_categories');
	}
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


=head2 list_items

List all items.

=cut

sub list_items : Chained('base') : PathPart('list-items') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view the list of items
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'view the list of items', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	my @items = $c->model('DB::ShopItem')->search;
	$c->stash->{ items } = \@items;
}


=head2 add_item

Add an item.

=cut

sub add_item : Chained('base') : PathPart('add-item') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add items
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add items', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	my @categories = $c->model('DB::ShopCategory')->search;
	$c->stash->{ categories } = \@categories;
	
	# Stash a list of images present in the event-images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'shop-images/original' );
	
	$c->stash->{template} = 'admin/shop/edit_item.tt';
}


=head2 add_item_do

Process an item add.

=cut

sub add_item_do : Chained('base') : PathPart('add-item-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add items
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add items', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	# Extract item details from form
	my $details = {
		name			=> $c->request->params->{ name	        } || undef,
		code			=> $c->request->params->{ code          } || undef,
		description		=> $c->request->params->{ description   } || undef,
		image			=> $c->request->params->{ image         } || undef,
		price			=> $c->request->params->{ price         } || undef,
		paypal_button	=> $c->request->params->{ paypal_button } || undef,
	};
	
	# Tidy up the item code
	my $item_code = $details->{ code };
	$item_code  ||= $details->{ name };
	$item_code   =~ s/\s+/-/g;
	$item_code   =~ s/[^-\w]//g;
	$item_code   =~ s/-+/-/g;
	
	$details->{ code } = lc $item_code;
	
	# Create item
	my $item = $c->model('DB::ShopItem')->create( $details );
	
	# Set up categories
	my $categories = $c->request->params->{ categories };
	$categories = [ $categories ] unless ref $categories eq 'ARRAY';
	foreach my $category ( @$categories ) {
		$item->shop_item_categories->create({
			category => $category,
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Item added';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( '/shop/item/'. $item->code .'/edit' );
}


=head2 edit_item

Edit an item.

=cut

sub edit_item : Chained('get_item') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit items
	my $item_id = $c->stash->{ item }->code || $c->stash->{ item }->id;
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit items', 
		role     => 'Shop Admin',
		redirect => '/shop/item/'. $item_id,
	});
	
	# Stash a list of images present in the event-images folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'shop-images/original' );
	
	my @categories = $c->model('DB::ShopCategory')->search;
	$c->stash->{ categories } = \@categories;
}


=head2 edit_item_do

Process an item update.

=cut

sub edit_item_do : Chained( 'get_item' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit items
	my $item_id = $c->stash->{ item }->code || $c->stash->{ item }->id;
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit items', 
		role     => 'Shop Admin',
		redirect => '/shop/item/'. $item_id,
	});
	
	# Process deletions
	if ( $c->request->params->{ 'delete' } eq 'Delete' ) {
		$c->model( 'DB::ShopItemCategory' )->search({
				item => $c->stash->{ item }->id
			})->delete;
		$c->stash->{ item }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Item deleted';
		
		# Bounce to the 'list items' page
		$c->response->redirect( $c->uri_for( 'list-items' ) );
		return;
	}
	
	# Check for price updates, warn if using external checkout
	if ( $c->request->params->{ paypal_button } ) {
		my $old_price = $c->model( 'DB::ShopItem' )->find({
							id => $c->stash->{ item }->id
						})->price;
		if ( $c->request->params->{ price } != $old_price ) {
			$c->flash->{ warning_msg } = 'Remember to also update price in PayPal checkout.';
		}
	}
	
	# Extract item details from form
	my $details = {
		name			=> $c->request->params->{ name	        } || undef,
		code			=> $c->request->params->{ code          } || undef,
		description		=> $c->request->params->{ description   } || undef,
		image			=> $c->request->params->{ image         } || undef,
		price			=> $c->request->params->{ price         } || undef,
		paypal_button	=> $c->request->params->{ paypal_button } || undef,
	};
	
	# Tidy up the item code
	my $item_code = $details->{ code };
	$item_code  ||= $details->{ name };
	$item_code   =~ s/\s+/-/g;
	$item_code   =~ s/[^-\w]//g;
	$item_code   =~ s/-+/-/g;
	
	$details->{ code } = lc $item_code;
	
	# Update item
	my $item = $c->model( 'DB::ShopItem' )->find({
					id => $c->stash->{ item }->id,
				})->update( $details );
	
	# Set up categories
	my $categories = $c->request->params->{ categories };
	$categories = [ $categories ] unless ref $categories eq 'ARRAY';
	# first, remove all existing item/category links
	$item->shop_item_categories->delete;
	# second, loop through the requested set of links, creating them
	foreach my $category ( @$categories ) {
		$item->shop_item_categories->create({
			category => $category,
		});
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Item updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'item', $c->stash->{ item }->code, 'edit' ) );
}


=head2 add_category

Add a category.

=cut

sub add_category : Chained('base') : PathPart('add-category') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add categories
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add shop categories', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	my @categories = $c->model('DB::ShopCategory')->search;
	$c->stash->{ categories } = \@categories;
	
	$c->stash->{template} = 'admin/shop/edit_category.tt';
}


=head2 add_category_do

Process a category add.

=cut

sub add_category_do : Chained('base') : PathPart('add-category-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to add categories
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add shop categories', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	# Create category
	my $category = $c->model('DB::ShopCategory')->create({
		name        => $c->request->params->{ name	      },
		url_name    => $c->request->params->{ url_name    },
		parent		=> $c->request->params->{ parent      } || undef,
		description => $c->request->params->{ description },
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Category added';
	
	# Bounce back to the category list
	$c->response->redirect( '/shop/categories' );
}


=head2 edit_category

Edit a category.

=cut

sub edit_category : Chained('get_category') : PathPart('edit') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit categories
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit shop categories', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	my @categories = $c->model('DB::ShopCategory')->search;
	$c->stash->{ categories } = \@categories;
}


=head2 edit_category_do

Process a category edit.

=cut

sub edit_category_do : Chained('get_category') : PathPart('edit-do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to edit categories
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'edit shop categories', 
		role     => 'Shop Admin',
		redirect => '/shop',
	});
	
	# Process deletions
	if ( $c->request->params->{ 'delete' } eq 'Delete' ) {
		$c->model('DB::ShopCategory')->find({
				id => $c->stash->{ category }->id
			})->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Category deleted';
		
		# Bounce to the 'view all categories' page
		$c->response->redirect( '/shop/categories' );
		return;
	}
	
	# Update category
	my $category = $c->model('DB::ShopCategory')->find({
					id => $c->stash->{ category }->id
				})->update({
					name        => $c->request->params->{ name	      },
					url_name    => $c->request->params->{ url_name	  },
					parent		=> $c->request->params->{ parent      } || undef,
					description => $c->request->params->{ description },
				});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Category updated';
	
	# Bounce back to the category list
	$c->response->redirect( '/shop/categories' );
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

