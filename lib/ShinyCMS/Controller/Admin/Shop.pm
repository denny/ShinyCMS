package ShinyCMS::Controller::Admin::Shop;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Shop

=head1 DESCRIPTION

Controller for ShinyCMS shop admin features.

=cut


has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has currency => (
	isa     => Str,
	is      => 'ro',
	default => '&pound;',
);

has display_items_in_order_list => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has hide_new_categories => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has hide_new_items => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has items_order => (
	isa     => Str,
	is      => 'ro',
	default => 'desc',
);

has items_order_by => (
	isa     => Str,
	is      => 'ro',
	default => 'created',
);


=head1 METHODS

=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/shop' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure the user is a shop admin
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'use shop admin features',
		role     => 'Shop Admin',
		redirect => '/shop'
	});

	# Stash the currency symbol
	$c->stash->{ currency } = $self->currency;

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Shop';
}


=head2 index

For now, forwards to the category list.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->go( 'list_items' );
}


# ========== ( Items ) ==========

=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained( 'base' ) : PathPart( 'item' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $item_id ) = @_;

	# Fetch and stash the item
	$c->stash->{ item } = $c->model( 'DB::ShopItem' )->find({ id => $item_id });

	unless ( $c->stash->{ item } ) {
		$c->flash->{ error_msg } = "Item not found: $item_id";
		$c->response->redirect( $c->uri_for( '/admin/shop/items' ) );
		$c->detach;
	}

	# Fetch and stash the item elements
	my @elements = $c->stash->{ item }->shop_item_elements->all;
	$c->stash->{ shop_item_elements } = \@elements;
}


=head2 get_tags

Get the tags for a specified item

=cut

sub get_tags {
	my ( $self, $c, $item_id ) = @_;

	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $item_id,
		resource_type => 'ShopItem',
	});
	if ( $tagset ) {
		my @tags1 = $tagset->tags;
		my $tags = [];
		foreach my $tag ( @tags1 ) {
			push @$tags, $tag->tag;
		}
		@$tags = sort @$tags;
		return $tags;
	}
}


=head2 list_items

List all items.

=cut

sub list_items : Chained( 'base' ) : PathPart( 'items' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $order_by = 'me.id, '. $self->items_order_by .' '. $self->items_order;

	my $categories = $c->model( 'DB::ShopCategory' )->search(
		{},
		{
			join     => { 'shop_item_categories' => 'item' },
			prefetch => { 'shop_item_categories' => 'item' },
			order_by => \$order_by,
		}
	);
	$c->stash->{ categories } = $categories;

	$c->stash->{ clone_destination } = $self->clone_destination_name( $c );
}


=head2 add_item

Add an item.

=cut

sub add_item : Chained( 'base' ) : PathPart( 'item/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of product types
	my @types = $c->model( 'DB::ShopProductType' )->all;
	$c->stash->{ product_types } = \@types;

	# Stash the list of categories
	my @categories = $c->model( 'DB::ShopCategory' )->all;
	$c->stash->{ categories } = \@categories;

	# Stash the postage options
	my @options = $c->model( 'DB::PostageOption' )->all;
	$c->stash->{ postage_options } = \@options;

	# Stash a list of images present in the shop-images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'shop-images/original' );

	# Find default comment setting and pass through
	$c->stash->{ comments_default_on } = 'YES'
		if uc $self->comments_default eq 'YES';

	# Stash 'hide new items' setting
	$c->stash->{ hide_new_items } = 1 if uc $self->hide_new_items eq 'YES';

	$c->stash->{ template } = 'admin/shop/edit_item.tt';
}


=head2 add_item_do

Process adding a new item.

=cut

sub add_item_do : Chained( 'base' ) : PathPart( 'item/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Extract item details from form
	my $price = ''.$c->request->param( 'price' );
	$price =~ s{[^\.\d]}{}g;  # Remove any cruft from the price string
	$price = '0.00' if $price eq '0';
	$price = $price ? $price : undef;

	my $item_code = $c->request->param( 'code' ) ?
		$c->request->param( 'code' ) :
		$c->request->param( 'name' );
	$item_code = $self->make_url_slug( $item_code );

	my $restock_date = $self->safe_param( $c, 'restock_date' );
	my $stock        = $self->safe_param( $c, 'stock'        );
	my $hidden       = $c->request->param( 'hidden'          ) ?  1 : 0;

	my $details = {
		name         => $c->request->param( 'name'         ),
		code         => $item_code,
		product_type => $c->request->param( 'product_type' ),
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		stock        => $stock,
		restock_date => $restock_date,
		hidden       => $hidden,
		price        => $price,
	};

	# Create item
	my $item = $c->model( 'DB::ShopItem' )->create( $details );

	# Set up elements
	my @elements = $c->model( 'DB::ShopProductType' )->find({
		id => $c->request->param( 'product_type' ),
	})->shop_product_type_elements->all;

	foreach my $element ( @elements ) {
		my $el = $item->shop_item_elements->create({
			name => $element->name,
			type => $element->type,
		});
	}

	# Set up categories
	my $categories = $c->request->params->{ categories };
	$categories = [ $categories ] unless ref $categories eq 'ARRAY';
	foreach my $category ( @$categories ) {
		$item->shop_item_categories->create({
			category => $category,
		});
	}

	# Add postage options
	my $options = $c->request->params->{ postage_options };
	if ( $options ) {
		$options = [ $options ] unless ref $options eq 'ARRAY';
		foreach my $option ( @$options ) {
			$item->shop_item_postage_options->create({
				postage => $option,
			});
		}
	}

	# Process the tags
	if ( $c->request->param( 'tags' ) ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $item->id,
			resource_type => 'ShopItem',
			hidden        => $c->request->param( 'hidden' ) ? 1 : 0,
		});
		my @tags = sort split /\s*,\s*/, $c->request->param( 'tags' );
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}

	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $item->id,
			resource_type => 'ShopItem',
		});
		$item->update({ discussion => $discussion->id });
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Item added';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'item', $item->id, 'edit' ) );
}


=head2 edit_item

Edit an item.

=cut

sub edit_item : Chained( 'get_item' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of element types
	$c->stash->{ types  } = get_element_types();

	# Stash the list of product types
	my @types = $c->model( 'DB::ShopProductType' )->all;
	$c->stash->{ product_types } = \@types;

	# Stash the categories
	my @categories = $c->model( 'DB::ShopCategory' )->all;
	$c->stash->{ categories } = \@categories;

	# Stash the postage options
	my @options = $c->model( 'DB::PostageOption' )->all;
	$c->stash->{ postage_options } = \@options;

	# Stash a list of images present in the shop-images folder
	$c->stash->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'shop-images/original' );

	# Stash the tags
	$c->stash->{ shop_item_tags } = $self->get_tags( $c, $c->stash->{ item }->id );
}


=head2 edit_item_do

Process an item update.

=cut

sub edit_item_do : Chained( 'get_item' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->model( 'DB::ShopItemCategory' )->search({
			item => $c->stash->{ item }->id
		})->delete;
		my $tagset = $c->model( 'DB::Tagset' )->search({
			resource_type => 'ShopItem',
			resource_id   => $c->stash->{ item }->id,
		})->single;
		if ( $tagset ) {
			$tagset->tags->delete;
			$tagset->delete;
		}
		$c->stash->{ item }->shop_item_views->delete;
		$c->stash->{ item }->shop_items_like->delete;
		$c->stash->{ item }->shop_item_favourites->delete;
		$c->stash->{ item }->shop_item_postage_options->delete;
		$c->stash->{ item }->shop_item_elements->delete;
		$c->stash->{ item }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Item deleted';

		# Bounce to the 'list items' page
		$c->response->redirect( $c->uri_for( '/admin/shop' ) );
		$c->detach;
	}

	# Get the tagset
	my $tagset = $c->model( 'DB::Tagset' )->find({
		resource_id   => $c->stash->{ item }->id,
		resource_type => 'ShopItem',
	});

	# Extract item details from form
	my $price = ''.$c->request->param( 'price' );
	$price =~ s{[^\.\d]}{}g;  # Remove any cruft from the price string
	$price = '0.00' if $price eq '0';

	my $item_code = $c->request->param( 'code' ) ?
		$c->request->param( 'code' ) : $c->request->param( 'name' );
	$item_code = $self->make_url_slug( $item_code );

	my $details = {
		name         => $c->request->param( 'name'         ),
		code         => $item_code,
		description  => $c->request->param( 'description'  ),
		image        => $c->request->param( 'image'        ),
		stock        => $self->safe_param( $c, 'stock'        ),
		restock_date => $self->safe_param( $c, 'restock_date' ),
		hidden       => $c->request->param( 'hidden'       ) ? 1 : 0,
		price        => $price || undef,
		updated      => \'current_timestamp',
	};

	if ( $c->user->has_role( 'CMS Template Admin' ) ) {
		$details->{ product_type } = $c->request->param( 'product_type' );
		if ( $details->{ product_type } != $c->stash->{ item }->product_type->id ) {
			# TODO: If product type has changed, change element stack
			# Fetch old element set
			# Fetch new element set
			# Find the difference between the two sets
			# Add missing elements
			# Remove superfluous elements? Probably not - keep in case of reverts.
		}
	}

	# Extract elements from form
	my $elements = {};
	my $user_is_template_admin = $c->user->has_role( 'CMS Template Admin' );
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
		}
		next unless $user_is_template_admin;
		if ( $input =~ m/^name_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'name' } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^type_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'type' } = $c->request->param( $input );
		}
	}

	# Update item
	my $item = $c->model( 'DB::ShopItem' )->find({
		id => $c->stash->{ item }->id,
	})->update( $details );

	# Update elements
	foreach my $element ( keys %$elements ) {
		$c->stash->{ item }->shop_item_elements->find({
			id => $element,
		})->update( $elements->{ $element } );
	}

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

	# Update postage options
	my $options = $c->request->params->{ postage_options };
	# first, remove all existing postage options for this item
	$item->shop_item_postage_options->delete;
	# second, loop through the requested set of options, (re)creating them
	if ( $options ) {
		$options = [ $options ] unless ref $options eq 'ARRAY';
		foreach my $option ( @$options ) {
			$item->shop_item_postage_options->create({
				postage => $option,
			});
		}
	}

	# Process the tags
	if ( $tagset ) {
		my $tags = $tagset->tags;
		$tags->delete;
		if ( $c->request->param( 'tags' ) ) {
			my @tags = sort split /\s*,\s*/, $c->request->param( 'tags' );
			foreach my $tag ( @tags ) {
				$tagset->tags->create({
					tag => $tag,
				});
			}
			$tagset->update({
				hidden => $c->request->param( 'hidden' ) ? 1 : 0,
			});
		}
		else {
			$tagset->delete;
		}
	}
	elsif ( $c->request->param( 'tags' ) ) {
		my $tagset = $c->model( 'DB::Tagset' )->create({
			resource_id   => $item->id,
			resource_type => 'ShopItem',
			hidden        => $c->request->param( 'hidden' ) ? 1 : 0,
		});
		my @tags = sort split /\s*,\s*/, $c->request->param( 'tags' );
		foreach my $tag ( @tags ) {
			$tagset->tags->create({
				tag => $tag,
			});
		}
	}

	# Disconnect the related discussion thread, if requested
	# (leaves the comments orphaned, rather than deleting them)
	if ( $item->discussion ) {
		unless ( $c->request->param( 'allow_comments' ) ) {
			 $item->update({ discussion => undef });
		}
	}
	# Create a related discussion thread, if requested
	elsif ( $c->request->param( 'allow_comments' ) ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $item->id,
			resource_type => 'ShopItem',
		});
		$item->update({ discussion => $discussion->id });
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Item updated';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'item', $item->id, 'edit' ) );
}


=head2 add_element_do

Add an element to an item.

=cut

sub add_element_do : Chained( 'get_item' ) : PathPart( 'add_element_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Extract page element from form
	my $element = $c->request->param( 'new_element' );
	my $type    = $c->request->param( 'new_type'    );

	# Update the database
	$c->model( 'DB::ShopItemElement' )->create({
		item => $c->stash->{ item }->id,
		name => $element,
		type => $type,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';

	# Bounce back to the 'edit' page
	$c->response->redirect(
		$c->uri_for( 'item', $c->stash->{ item }->id, 'edit' ) .'#add_element'
	);
}


=head2 clone_item

Clone an item using the Duplicator

=cut

sub clone_item : Chained( 'get_item' ) : PathPart( 'clone' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'clone a shop item',
		role     => 'CMS Shop Admin',
		redirect => '/admin/shop'
	});

	my $destination_db = $self->clone_destination_schema( $c );

	if ( $destination_db ) {
		my $duplicator = ShinyCMS::Duplicator->new({
			source_db      => $c->model( 'DB' )->schema,
			destination_db => $destination_db,
			source_item    => $c->stash->{ item },
		});
		$duplicator->clone;

		if ( $duplicator->has_errors ) {
			$c->flash->{ error_msg } = 'Cloning failed';
		}
		else {
			if ( $c->config->{ DuplicatorDestination }->{ hide_clones } ) {
				$duplicator->cloned_item->update({ hidden => 1 });
				$duplicator->cloned_item->tags->update({ hidden => 1 });
			}

			$c->flash->{ status_msg } = $duplicator->result;
		}
	}
	else {
		$c->flash->{ error_msg } = 'Failed to connect to cloning destination';
	}

	$c->response->redirect( $c->uri_for( '/admin/shop' ) );
}


# ========== ( Categories ) ==========

=head2 list_categories

List all the categories

=cut

sub list_categories : Chained( 'base' ) : PathPart( 'categories' ) : Args(0) {
	my ( $self, $c ) = @_;

	my @categories = $c->model( 'DB::ShopCategory' )->search({ parent => undef });
	$c->stash->{ categories } = \@categories;
}


=head2 get_category

Stash details and items relating to the specified category.

=cut

sub get_category : Chained( 'base' ) : PathPart( 'category' ) : CaptureArgs(1) {
	my ( $self, $c, $category_id ) = @_;

	# numeric identifier
	$c->stash->{ category } = $c->model( 'DB::ShopCategory' )->find( { id => $category_id } );

	# TODO: better 404 handler here?
	unless ( $c->stash->{ category } ) {
		$c->stash->{ error_msg } =
			'Specified category not found - please select from the options below';
		$c->go( 'list_categories' );
	}
}


=head2 add_category

Add a category.

=cut

sub add_category : Chained( 'base' ) : PathPart( 'category/add' ) : Args(0) {
	my ( $self, $c ) = @_;

	my @categories = $c->model( 'DB::ShopCategory' )->search;
	$c->stash->{ categories } = \@categories;

	# Stash 'hide new categories' setting
	$c->stash->{ hide_new_categories } = 1 if uc $self->hide_new_categories eq 'YES';

	$c->stash->{template} = 'admin/shop/edit_category.tt';
}


=head2 add_category_do

Process a category add.

=cut

sub add_category_do : Chained( 'base' ) : PathPart( 'category/add-do' ) : Args(0) {
	my ( $self, $c ) = @_;

	# Tidy up the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Create category
	my $category = $c->model( 'DB::ShopCategory' )->create({
		name        => $c->request->param( 'name'        ),
		url_name    => $url_name,
		parent	    => $self->safe_param( $c, 'parent'      ),
		description => $c->request->param( 'description' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Category added';

	# Go to the category's edit page
	my $url = $c->uri_for( '/admin/shop/category', $category->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_category

Edit a category.

=cut

sub edit_category : Chained( 'get_category' ) : PathPart( 'edit' ) : Args(0) {
	my ( $self, $c ) = @_;

	my @categories = $c->model( 'DB::ShopCategory' )->search;
	$c->stash->{ categories } = \@categories;
}


=head2 edit_category_do

Process a category edit.

=cut

sub edit_category_do : Chained( 'get_category' ) : PathPart( 'save' ) : Args(0) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->model( 'DB::ShopCategory' )->find({
				id => $c->stash->{ category }->id
			})->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Category deleted';

		# Bounce to the 'view all categories' page
		$c->response->redirect( '/admin/shop/categories' );
		$c->detach;
	}

	# Tidy up the url_name
	my $url_name = $c->request->param( 'url_name' ) ?
	    $c->request->param( 'url_name' ) :
	    $c->request->param( 'name'     );
	$url_name = $self->make_url_slug( $url_name );

	# Update category
	my $category = $c->model( 'DB::ShopCategory' )->find({
					id => $c->stash->{ category }->id
				})->update({
					name        => $c->request->param( 'name' ),
					url_name    => $url_name,
					parent	    => $self->safe_param( $c, 'parent' ),
					description => $c->request->param( 'description' ),
				});

	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Category updated';

	# Bounce back to the category's edit page
	my $url = $c->uri_for( '/admin/shop/category', $c->stash->{ category }->id, 'edit' );
	$c->response->redirect( $url );
}


# ========== ( Product Types ) ==========

=head2 list_product_types

List all the product types.

=cut

sub list_product_types : Chained( 'base' ) : PathPart( 'product-types' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @types = $c->model( 'DB::ShopProductType' )->search;
	$c->stash->{ product_types } = \@types;

	$c->stash->{ clone_destination } = $self->clone_destination_name( $c );
}


=head2 get_product_type

Stash details relating to a product type.

=cut

sub get_product_type : Chained( 'base' ) : PathPart( 'product-type' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $product_type_id ) = @_;

	$c->stash->{ product_type } =
		$c->model( 'DB::ShopProductType' )->find({ id => $product_type_id });

	unless ( $c->stash->{ product_type } ) {
		$c->stash->{ error_msg } =
			'Specified product type not found - please select from the options below';
		$c->go( 'list_product_types' );
	}

	# Get product type elements
	my @elements = $c->stash->{ product_type }->shop_product_type_elements->all;
	$c->stash->{ product_type_elements } = \@elements;
}


=head2 get_template_filenames

Get a list of available template filenames.

=cut

sub get_template_filenames : Private {
	my ( $self, $c ) = @_;

	my $template_dir = $c->path_to( 'root/shop/product-type-templates' );
	opendir( my $template_dh, $template_dir )
		or die "Failed to open template directory $template_dir: $!";
	my @templates;
	foreach my $filename ( readdir( $template_dh ) ) {
		next unless $filename =~ m/\.tt$/; # only show TT files
		push @templates, $filename;
	}

	return \@templates;
}


=head2 add_product_type

Add a product type.

=cut

sub add_product_type : Chained( 'base' ) : PathPart( 'product-type/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ template_filenames } = $self->get_template_filenames( $c );

	$c->stash->{ template } = 'admin/shop/edit_product_type.tt';
}


=head2 add_product_type_do

Process a product type addition.

=cut

sub add_product_type_do : Chained( 'base' ) : PathPart( 'product-type/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Create product type
	my $type = $c->model( 'DB::ShopProductType' )->create({
		name          => $c->request->param( 'name'          ),
		template_file => $c->request->param( 'template_file' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Product type details saved';

	# Bounce to the new product type's edit page
	my $url = $c->uri_for( '/admin/shop/product-type', $type->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 edit_product_type

Edit a product type.

=cut

sub edit_product_type : Chained( 'get_product_type' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ element_types } = get_element_types();

	$c->stash->{ template_filenames } = $self->get_template_filenames( $c );
}


=head2 edit_product_type_do

Process a product type edit.

=cut

sub edit_product_type_do : Chained( 'get_product_type' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->stash->{ product_type }->shop_product_type_elements->delete;
		$c->stash->{ product_type }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Product type deleted';

		# Bounce to the 'view all product types' page
		$c->response->redirect( $c->uri_for( '/admin/shop/product-types' ) );
		$c->detach;
	}

	# Update product type
	my $type = $c->stash->{ product_type }->update({
		name          => $c->request->param( 'name'          ),
		template_file => $c->request->param( 'template_file' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Product type details updated';

	# Bounce back to the product type's edit page
	my $url = $c->uri_for( '/admin/shop/product-type', $type->id, 'edit' );
	$c->response->redirect( $url );
}


=head2 get_element_types

Return a list of page-element types.

=cut

sub get_element_types {
	# TODO: more elegant way of doing this

	return [ 'Short Text', 'Long Text', 'HTML', 'Image' ];
}


=head2 add_product_type_element_do

Add an element to a product_type.

=cut

sub add_product_type_element_do : Chained( 'get_product_type' ) : PathPart( 'add-element-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Extract element from form
	my $element = $c->request->param( 'new_element' );
	my $type    = $c->request->param( 'new_type'    );

	# Update the database
	$c->model( 'DB::ShopProductTypeElement' )->create({
		product_type => $c->stash->{ product_type }->id,
		name         => $element,
		type         => $type,
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element added';

	# Bounce back to the 'edit' page
	$c->response->redirect(
		$c->uri_for( 'product-type', $c->stash->{ product_type }->id, 'edit' ) .'#add_element'
	);
}


=head2 delete_product_type_element

Remove an element from a product_type.

=cut

sub delete_product_type_element : Chained( 'get_product_type' ) : PathPart( 'delete-element' ) : Args( 1 ) {
	my ( $self, $c, $element_id ) = @_;

	# Update the database
	$c->model( 'DB::ShopProductTypeElement' )->find({
		id => $element_id,
	})->delete;

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Element removed';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for(
		'product-type', $c->stash->{ product_type }->id, 'edit' )
	);
}


=head2 clone_product_type

Clone a product type using the Duplicator

=cut

sub clone_product_type : Chained( 'get_product_type' ) : PathPart( 'clone' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	return 0 unless $self->user_exists_and_can($c, {
		action   => 'clone a product type',
		role     => 'CMS Shop Admin',
		redirect => '/admin/shop'
	});

	my $destination_db = $self->clone_destination_schema( $c );

	if ( $destination_db ) {
		my $duplicator = ShinyCMS::Duplicator->new({
			source_db      => $c->model( 'DB' )->schema,
			destination_db => $destination_db,
			source_item    => $c->stash->{ cms_template },
		});
		$duplicator->clone;

		if ( $duplicator->has_errors ) {
			$c->flash->{ error_msg } = 'Cloning failed';
		}
		else {
			$self->
			$c->flash->{ status_msg } = $duplicator->result;
		}
	}
	else {
		$c->flash->{ error_msg } = 'Failed to connect to cloning destination';
	}

	$c->response->redirect( $c->uri_for( '/admin/shop/product-types' ) );
}


=head2 clone_destination_name

Return the name of the configured cloning destination, if one exists

=cut

sub clone_destination_name : Private {
	my ( $self, $c ) = @_;

	return unless $c->config->{ DuplicatorDestination };

	return $c->config->{ DuplicatorDestination }->{ name } ||
				 $c->config->{ DuplicatorDestination }->{ connect_info }->{ dsn };
}


=head2 clone_destination_schema

Return the configured cloning destination schema (if any)

=cut

sub clone_destination_schema : Private {
	my ( $self, $c ) = @_;

	return unless $c->config->{ DuplicatorDestination };

	return ShinyCMS::Schema->connect(
		$c->config->{ DuplicatorDestination }->{ connect_info }
	);
}


# ========== ( Orders ) ==========

=head2 list_orders

List the most recent orders

=cut

sub list_orders : Chained( 'base' ) : PathPart( 'orders' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $orders = $c->model( 'DB::Order' )->search(
		{},
		{
			join     => 'order_items',
			prefetch => 'order_items',
			order_by => { -desc => 'me.created' },
		}
	);
	$c->stash->{ orders } = $orders;

	$c->stash->{ display_items } = 1 if
		uc $self->display_items_in_order_list eq 'YES';
}


=head2 get_order

Stash details relating to an order

=cut

sub get_order : Chained( 'base' ) : PathPart( 'order' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $order_id ) = @_;

	$c->stash->{ order } = $c->model( 'DB::Order' )->find({ id => $order_id });

	unless ( $c->stash->{ order } ) {
		$c->stash->{ error_msg } =
			'Specified order not found - please select from the orders below';
		$c->go( 'list_orders' );
	}
}


=head2 edit_order

Edit an order.

=cut

sub edit_order : Chained( 'get_order' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ statuses } = [
		'Order incomplete',
		'Awaiting payment',
		'Awaiting despatch',
		'Despatched',
		'Cancelled',
	];
}


=head2 edit_order_do

Update the details of an order.

=cut

sub edit_order_do : Chained( 'get_order' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process cancellations
	if ( defined $c->request->param( 'cancel' ) ) {
		$c->stash->{ order }->update({ status => 'Cancelled' });

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Order cancelled';

		# Bounce to the 'view all orders' page
		$c->response->redirect( $c->uri_for( '/admin/shop/orders' ) );
		$c->detach;
	}

	# Update the status, if changed
	if ( $c->request->param( 'status' ) ne $c->stash->{ order }->status ) {
		$c->stash->{ order }->update({
			status => $c->request->param( 'status' ),
		});
	}

	my $params = $c->request->params;

	# Update postage options
	foreach my $key ( keys %$params ) {
		next unless $key =~ m/^postage_(\d+)$/;
		my $order_item_id = $1;

		$c->stash->{ order }->order_items->find({
			id => $order_item_id,
		})->update({
			postage => $params->{ $key } || undef,
		});
	}

	# Update item quantities
	foreach my $key ( keys %$params ) {
		next unless $key =~ m{^quantity_(\d+)$};
		my $item_id = $1;

		if ( $params->{ $key } == 0 ) {
			# Remove the item
			$c->stash->{ order }->order_items->find({
				id => $item_id,
			})->delete;

			# Set a status message
			$c->flash->{ status_msg } = 'Item removed.';
		}
		else {
			# Update the item
			$c->stash->{ order }->order_items->find({
				id => $item_id,
			})->update({
				quantity => $params->{ $key },
			});

			# Set a status message
			$c->flash->{ status_msg } = 'Item updated.';
		}
	}

	# Redirect to edit order page
	my $uri = $c->uri_for( '/admin/shop/order', $c->stash->{ order }->id );
	$c->response->redirect( $uri );
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
