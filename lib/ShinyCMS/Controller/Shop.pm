package ShinyCMS::Controller::Shop;

use Moose;
use MooseX::Types::Moose qw/ Str Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Shop

=head1 DESCRIPTION

Controller for ShinyCMS shop.

=cut


has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 10,
);

has can_like => (
	isa     => Str,
	is      => 'ro',
	default => 'Anonymous',
);

has currency => (
	isa      => Str,
	is       => 'ro',
	required => 1,
);


=head1 METHODS

=head2 base

Sets up the base part of the URL path.

=cut

sub base : Chained( '/base' ) : PathPart( 'shop' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the currency symbol
	$c->stash->{ currency } = $self->currency;

	# Stash the controller name
	$c->stash->{ controller } = 'Shop';

	# Stash shopping basket, if any
	my $basket = ShinyCMS::Controller::Shop::Basket->get_basket( $c );
	$c->stash( basket => $basket );
}


=head2 index

For now, forwards to the category list.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# TODO: Storefront - special offers, featured items, new additions, etc

	$c->go('view_categories');
}


=head2 view_categories

View all the categories (for shop-user).

=cut

sub view_categories : Chained( 'base' ) : PathPart( 'categories' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $categories = $self->get_categories( $c );
	$c->stash->{ categories } = $categories;
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
	my ( $self, $c, $url_name ) = @_;

	$c->stash->{ category } = $c->model( 'DB::ShopCategory' )->search({
		url_name => $url_name,
		hidden   => 0,
	})->single;

	unless ( $c->stash->{ category } ) {
		$c->stash->{ error_msg } =
			'Category not found - please choose from the options below';
		$c->go( 'view_categories' );
	}
}


=head2 view_category

View all items in the specified category.

=cut

sub view_category : Chained( 'get_category' ) : PathPart( '' ) : Args {
	my ( $self, $c, $page, $count ) = @_;

	$page  = int ( $page  || 1 );
	$count = int ( $count || $self->page_size );

	my $items = $self->get_category_items( $c, $c->stash->{ category }->id, $page, $count );
	$c->stash->{ shop_items } = $items;
}


=head2 view_recent_items

View recently-added items.

=cut

sub view_recent_items : Chained( 'base' ) : PathPart( 'recent' ) : Args {
	my ( $self, $c, $page, $count ) = @_;

	$page  = int ( $page  || 1 );
	$count = int ( $count || $self->page_size );

	my $items = $self->get_recent_items( $c, $page, $count );

	$c->stash->{ recent_items } = $items;
}


=head2 view_tagged_items

View items with a specified tag.

=cut

sub view_tagged_items : Chained( 'base' ) : PathPart( 'tag' ) : Args {
	my ( $self, $c, $tag, $page, $count ) = @_;

	$page  = int ( $page  || 1 );
	$count = int ( $count || $self->page_size );

	my $items = $self->get_tagged_items( $c, $tag, $page, $count );

	$c->stash->{ tag          } = $tag;
	$c->stash->{ tagged_items } = $items;
}


=head2 view_favourites

View favourite items

=cut

sub view_favourites : Chained( 'base' ) : PathPart( 'favourites' ) : Args {
	my ( $self, $c, $page, $count ) = @_;

	unless ( $c->user_exists ) {
		$c->flash->{ error_msg } = 'You must be logged in to view your favourites.';
		my $url = $c->request->referer ? $c->request->referer : $c->uri_for( '/shop' );
		$c->response->redirect( $url );
		$c->detach;
	}

	$page  = int ( $page  || 1 );
	$count = int ( $count || $self->page_size );

	my $items = $self->get_favourites( $c, $page, $count );

	$c->stash->{ favourites } = $items;
}


=head2 view_recently_viewed

View list of recently viewed items

=cut

sub view_recently_viewed : Chained( 'base' ) : PathPart( 'recently-viewed' ) : Args {
	my ( $self, $c, $page, $count ) = @_;

	unless ( $c->user_exists ) {
		$c->flash->{ error_msg } = 'You must be logged in to see your recently viewed items.';
		my $url = $c->request->referer ? $c->request->referer : $c->uri_for( '/shop' );
		$c->response->redirect( $url );
		$c->detach;
	}

	$page  = int ( $page  || 1 );
	$count = int ( $count || $self->page_size );

	my $items = $self->get_recently_viewed( $c, $page, $count );

	$c->stash->{ recently_viewed } = $items;
}


=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained( 'base' ) : PathPart( 'item' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $item_code ) = @_;

	$c->stash->{ item } = $c->model( 'DB::ShopItem' )->search({
		code   => $item_code,
		hidden => 0,
	})->single;

	if ( $c->stash->{ item } ) {
		$c->stash->{ item }->{ elements } = $c->stash->{ item }->get_elements;
	}
	elsif ( $c->action eq 'shop/preview' and $c->user->has_role( 'Shop Admin' ) ) {
		# Let this one slide through, for the admin preview feature
	}
	else {
		$c->stash->{ error_msg } = 'Specified item not found.  Please try again.';
		$c->go( 'view_categories' );
	}

	return $c->stash->{ item };
}


=head2 preview

Preview an item.

=cut

sub preview : Chained( 'get_item' ) PathPart( 'preview' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to preview CMS pages
	return 0 unless $self->user_exists_and_can($c, {
		action => 'preview shop items',
		role   => 'Shop Admin',
	});

	# Extract page details from form
	my $new_details = {
		name  => $c->request->param( 'name'  ) || 'No item name given',
		code  => $c->request->param( 'code'  ) || 'no-item-name-given',
		price       => $self->safe_param( $c, 'price'       ),
		image       => $self->safe_param( $c, 'image'       ),
		description => $self->safe_param( $c, 'description' ),
		like_count  => 0,
	};
	$c->stash->{ shop_item_tags } = $c->request->param( 'tags' );

	# Extract item elements from form
	my $elements = {};
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^name_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'name'    } = $c->request->param( $input );
		}
		elsif ( $input =~ m/^content_(\d+)$/ ) {
			my $id = $1;
			$elements->{ $id }{ 'content' } = $c->request->param( $input );
		}
	}
	# And set them up for insertion into the preview page
	my $new_elements = {};
	foreach my $key ( keys %$elements ) {
		$new_elements->{ $elements->{ $key }->{ name } }
			= $elements->{ $key }->{ content };
	}
	$new_details->{ elements } = $new_elements;

	# Set up the categories
	my $categories = $c->request->params->{ categories };
	$categories = [ $categories ] unless ref $categories eq 'ARRAY';
	my $new_categories = [];
	foreach my $category_id ( @$categories ) {
		my $category = $c->model('DB::ShopCategory')->find({
			id => $category_id,
		});
		push @$new_categories, {
			name     => $category->name,
			url_name => $category->url_name,
		};
	}
	$new_details->{ categories } = $new_categories;

	# Set the TT template to use
	my $new_template = $c->model('DB::ShopProductType')
		->find({ id => $c->request->param('product_type') })->template_file;

	# Over-ride everything
	$c->stash->{ item     } = $new_details;
	$c->stash->{ template } = 'shop/product-type-templates/'. $new_template;
	$c->stash->{ preview  } = 'preview';
}


=head2 view_item

View an item.

=cut

sub view_item : Chained( 'get_item' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the tags
	$c->stash->{ shop_item_tags } = $c->stash->{ item }->tagset->tag_list;

	# Track recently viewed
	if ( $c->user_exists ) {
		$c->user->shop_item_views->search({
			item => $c->stash->{ item }->id,
		})->delete;
		$c->user->shop_item_views->create({
			item => $c->stash->{ item }->id,
		});
	}

	# Set template
	$c->stash->{ template } =
		'shop/product-type-templates/'. $c->stash->{ item }->product_type->template_file;
}


=head2 like_item

Like (or unlike) an item.

=cut

sub like_item : Chained( 'get_item' ) : PathPart( 'like' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $item_url = $c->uri_for( '/shop/item', $c->stash->{ item }->code );

	if ( $self->can_like eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to like this item.';
			$c->response->redirect( $item_url );
			$c->detach;
		}
	}

	my $ip_address = $c->request->address;

	# Find out if this user or IP address has already liked this item
	if ( $c->user_exists and $c->stash->{ item }->liked_by_user( $c->user->id ) ) {
		# Undo like by logged-in user
		$c->user->shop_items_like->search({
			item => $c->stash->{ item }->id,
		})->delete;
	}
	elsif ( $c->stash->{ item }->liked_by_anon( $ip_address ) and not $c->user_exists ) {
		# Undo like by anon user
		$c->model( 'DB::ShopItemLike' )->search({
			user       => undef,
			item       => $c->stash->{ item }->id,
			ip_address => $ip_address,
		})->delete;
	}
	else {
		# No existing 'like' for this user/IP
		if ( $c->user_exists ) {
			# Set like by logged-in user
			$c->user->shop_items_like->create({
				item       => $c->stash->{ item }->id,
				ip_address => $ip_address,
			});
		}
		else {
			# Set like by anon user
			$c->model( 'DB::ShopItemLike' )->create({
				item       => $c->stash->{ item }->id,
				ip_address => $ip_address,
			});
		}
	}

	# Bounce back to the item
	$c->response->redirect( $item_url );
	$c->detach;
}


=head2 favourite

Add or remove an item from the user's list of favourites.

=cut

sub favourite : Chained( 'get_item' ) : PathPart( 'favourite' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my $item_url = $c->uri_for( '/shop/item', $c->stash->{ item }->code );

	unless ( $c->user_exists ) {
		$c->flash->{ error_msg } = 'You must be logged in to add favourites.';
		$c->response->redirect( $item_url );
		$c->detach;
	}

	my $ip_address = $c->request->address;

	# Find out if this user has already favourited this item
	if ( $c->stash->{ item }->favourited_by_user( $c->user->id ) ) {
		# Undo favourite
		$c->user->shop_item_favourites->search({
			item => $c->stash->{ item }->id,
		})->delete;
	}
	else {
		# Set as a favourite
		$c->user->shop_item_favourites->create({
			item => $c->stash->{ item }->id,
		});
	}

	# Bounce back to the item
	$c->response->redirect( $item_url );
	$c->detach;
}


# ========== ( utility methods ) ==========

=head2 get_categories

Return the top-level categories.

=cut

sub get_categories : Private {
	my ( $self, $c ) = @_;

	my $categories = $c->model( 'DB::ShopCategory' )->search(
		{
			parent => undef,
			hidden => 0,
		},
		{
			order_by => { -asc => 'name' },
		}
	);

	return $categories;
}


=head2 get_category_items

Fetch items in the specified category.

=cut

sub get_category_items : Private {
	my ( $self, $c, $category_id, $page, $count ) = @_;

	my $items = $c->model( 'DB::ShopCategory' )->search(
		{
			id     => $category_id,
			hidden => 0,
		}
	)->single->items->search(
		{
			hidden => 0,
		},
		{
			order_by => { -asc => 'name' },
			page     => $page,
			rows     => $count,
		}
	);

	return $items;
}


=head2 get_tagged_items

Fetch items with a specified tag.

=cut

sub get_tagged_items : Private {
	my ( $self, $c, $tag, $page, $count ) = @_;

	my @tags = $c->model( 'DB::Tag' )->search({
		tag => $tag,
	});
	my @tagsets;
	foreach my $tag1 ( @tags ) {
		push @tagsets, $tag1->tagset,
	}
	my @tagged;
	foreach my $tagset ( @tagsets ) {
		next unless $tagset->resource_type eq 'ShopItem';
		next if $tagset->hidden;
		push @tagged, $tagset->get_column( 'resource_id' ),
	}

	my $items = $c->model( 'DB::ShopItem' )->search(
		{
			id       => { 'in' => \@tagged },
			hidden   => 0,
		},
		{
			order_by => { -desc => 'created' },
			page     => $page,
			rows     => $count,
		},
	);

	return $items;
}


=head2 get_tags

Get the tags for a specified item, or for the whole shop if no item is specified

=cut

sub get_tags : Private {
	my ( $self, $c, $item_id ) = @_;

	if ( $item_id ) {
		my $tagset = $c->model( 'DB::Tagset' )->find({
			resource_id   => $item_id,
			resource_type => 'ShopItem',
		});
		return $tagset->tag_list if $tagset;
	}
	else {
		my @tagset_ids = $c->model( 'DB::Tagset' )
                       ->search({ resource_type => 'ShopItem', hidden => 0 })
                       ->get_column( 'id' )->all;

		my @tags = $c->model( 'DB::Tag' )
                 ->search({ tagset => \@tagset_ids }, { group_by => 'tag' })
                 ->get_column( 'tag' )->all;

		@tags = sort { lc $a cmp lc $b } @tags;
		return \@tags;
	}
}


=head2 get_recent_items

Fetch recently-added items.

=cut

sub get_recent_items : Private {
	my ( $self, $c, $page, $count, $order_by ) = @_;

	my $options = {
		page     => $page,
		rows     => $count,
	};

	if ( $order_by and ( $order_by eq 'updated' or $order_by eq 'created' ) ) {
		$options->{ order_by } = { -desc => $order_by };
	}
	else {
		$options->{ order_by } = { -desc => [ 'created', 'updated' ] };
	}

	my $items = $c->model( 'DB::ShopItem' )->search(
		{
			hidden => 0,
		},
		$options,
	);

	return $items;
}


=head2 get_recently_viewed

Fetch user's recently viewed items

=cut

sub get_recently_viewed : Private {
	my ( $self, $c, $page, $count ) = @_;

	my $viewed = $c->user->shop_item_views->search(
		{
			'item.hidden' => 0,
		},
		{
			order_by => { -desc => 'me.updated' },
			join     => 'item',
			prefetch => 'item',
			page     => $page,
			rows     => $count,
		}
	);

	return $viewed;
}


=head2 get_favourites

Fetch user's favourite items

=cut

sub get_favourites : Private {
	my ( $self, $c, $page, $count ) = @_;

	my $favourites = $c->user->shop_item_favourites->search_related('item')->search(
		{
			hidden   => 0,
		},
		{
			order_by => { -desc => 'created' },
			page     => $page,
			rows     => $count,
		},
	);

	return $favourites;
}


# ========== ( search method used by site-wide search feature ) ==========

=head2 search

Search the shop.

=cut

sub search {
	my ( $self, $c ) = @_;

	return unless my $search = $c->request->param( 'search' );

	# Look in the item name/desc
	my @results = $c->model( 'DB::ShopItem' )->search(
		[
			{ name        => { 'LIKE', '%'.$search.'%'} },
			{ code        => { 'LIKE', '%'.$search.'%'} },
			{ description => { 'LIKE', '%'.$search.'%'} },
		],
	)->search({
		hidden => 0,
	})->all;

	my %item_hash;
	foreach my $result ( @results ) {
		# Pull out the matching search term and its immediate context
		my $match = '';
		if ( $result->name =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->code =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		elsif ( $result->description =~ m/(.{0,50}$search.{0,50})/is ) {
			$match = $1;
		}
		# Tidy up and mark the truncation
		unless ( $match eq $result->name or $match eq $result->description ) {
				$match =~ s/^\S*\s/... / unless $match =~ m/^$search/i;
				$match =~ s/\s\S*$/ .../ unless $match =~ m/$search$/i;
		}
		if ( $match eq $result->name ) {
			$match = substr $result->description, 0, 100;
			$match =~ s/\s\S+\s?$/ .../;
		}
		# Add the match string to the page result
		$result->{ match } = $match;

		# Add the item to a de-duping hash
		$item_hash{ $result->code } = $result;
	}

	# Look at any related elements too
	my @elements = $c->model( 'DB::ShopItemElement' )->search({
		content => { 'LIKE', '%'.$search.'%'},
	});
	foreach my $element ( @elements ) {
		next if $element->item->hidden;
		# Pull out the matching search term and its immediate context
		$element->content =~ m/(.{0,50}$search.{0,50})/i;
		my $match = $1;
		# Tidy up and mark the truncation
		unless ( $match eq $element->content ) {
			$match =~ s/^\S+\s/... /;
			$match =~ s/\s\S+$/ .../;
		}
		# Add the match string to the page result
		$element->item->{ match } = $match;
		# Add the item to a de-duping hash
		$item_hash{ $element->item->code } = $element->item;
	}

	# Push the de-duped items onto the results array
	my $items = [];
	foreach my $item ( keys %item_hash ) {
		push @$items, $item_hash{ $item };
	}

	$c->stash->{ shop_results } = $items;
	return $items;
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
