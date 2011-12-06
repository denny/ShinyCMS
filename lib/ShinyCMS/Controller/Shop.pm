package ShinyCMS::Controller::Shop;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Shop

=head1 DESCRIPTION

Controller for ShinyCMS shop.

=head1 METHODS

=cut


=head2 index

For now, forwards to the category list.

=cut

sub index : Path : Args( 0 ) {
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


=head2 get_categories

Return the top-level categories.

=cut

sub get_categories {
	my ( $self, $c ) = @_;
	
	my $categories = $c->model( 'DB::ShopCategory' )->search(
		{
			parent => undef,
		},
		{
			order_by => { -asc => 'name' },
		}
	);
	
	return $categories;
}


=head2 view_categories

View all the categories (for shop-user).

=cut

sub view_categories : Chained( 'base' ) : PathPart( 'categories' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
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


=head2 get_category_items

Fetch items in the specified category.

=cut

sub get_category_items {
	my ( $self, $c, $category_id, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $items = $c->model( 'DB::ShopCategory' )->find(
		{
			id => $category_id,
		}
	)->items->search(
		{
			hidden   => 'false',
		},
		{
			page     => $page,
			rows     => $count,
		}
	);
	
	return $items;
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
	
	my $items = $c->model( 'DB::ShopItem' )->search(
		{
			hidden   => 'false',
		},
		{
			order_by => { -desc => [ 'updated', 'added' ] },
			page     => $page,
			rows     => $count,
		}
	);
	
	return $items;
}


=head2 view_recent_items

View recently-added items.

=cut

sub view_recent_items : Chained( 'base' ) : PathPart( 'recent' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Shop }->{ items_per_page };
	
	my $items = $self->get_recent_items( $c, $page, $count );
	
	$c->stash->{ recent_items } = $items;
}


=head2 get_tagged_items

Fetch items with a specified tag.

=cut

sub get_tagged_items {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
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
		push @tagged, $tagset->get_column( 'resource_id' ),
	}
	
	my $items = $c->model( 'DB::ShopItem' )->search(
		{
			id       => { 'in' => \@tagged },
			hidden   => 'false',
		},
		{
			order_by => { -desc => 'updated' },
			page     => $page,
			rows     => $count,
		},
	);
	
	return $items;
}


=head2 view_tagged_items

View items with a specified tag.

=cut

sub view_tagged_items : Chained( 'base' ) : PathPart( 'tag' ) : Args( 1 ) : OptionalArgs( 2 ) {
	my ( $self, $c, $tag, $page, $count ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	$page  ||= 1;
	$count ||= $c->config->{ Shop }->{ items_per_page };
	
	my $items = $self->get_tagged_items( $c, $tag, $page, $count );
	
	$c->stash->{ tag          } = $tag;
	$c->stash->{ tagged_items } = $items;
}


=head2 get_item

Find the item we're interested in and stick it in the stash.

=cut

sub get_item : Chained( 'base' ) : PathPart( 'item' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $item_id ) = @_;
	
	if ( $item_id =~ /\D/ ) {
		# non-numeric identifier (product code)
		$c->stash->{ item } = $c->model( 'DB::ShopItem' )->find({
			code   => $item_id,
			hidden => 'false',
		});
	}
	else {
		# numeric identifier
		$c->stash->{ item } = $c->model( 'DB::ShopItem' )->find({
			id     => $item_id,
			hidden => 'false',
		});
	}
	
	unless ( $c->stash->{ item } ) {
		$c->stash->{ error_msg } = 'Specified item not found.  Please try again.';
		$c->go( 'view_categories' );
	}
}


=head2 get_tags

Get the tags for a specified item, or for the whole shop if no item is specified

=cut

sub get_tags {
	my ( $self, $c, $item_id ) = @_;
	
	if ( $item_id ) {
		my $tagset = $c->model( 'DB::Tagset' )->find({
			resource_id   => $item_id,
			resource_type => 'ShopItem',
		});
		return $tagset->tag_list if $tagset;
	}
	else {
		my @tagsets = $c->model( 'DB::Tagset' )->search({
			resource_type => 'ShopItem',
		});
		my @taglist;
		foreach my $tagset ( @tagsets ) {
			push @taglist, @{ $tagset->tag_list };
		}
		my %taghash;
		foreach my $tag ( @taglist ) {
			$taghash{ $tag } = 1;
		}
		my @tags = keys %taghash;
		@tags = sort { lc $a cmp lc $b } @tags;
		return \@tags;
	}
	
	return;
}


=head2 view_item

View an item.

=cut

sub view_item : Chained( 'get_item' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	# Stash the tags
	$c->stash->{ shop_item_tags } = $self->get_tags( $c, $c->stash->{ item }->id );
	
	# Set template
	$c->stash->{ template } = 
		'shop/product-type-templates/'. $c->stash->{ item }->product_type->template_file;
}


=head2 like_item

Like (or unlike) an item.

=cut

sub like_item : Chained( 'get_item' ) : PathPart( 'like' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	my $level = $c->config->{ Shop }->{ can_like };
	
	if ( $level eq 'User' ) {
		unless ( $c->user_exists ) {
			$c->flash->{ error_msg } = 'You must be logged in to like this item.';
			$c->response->redirect( $c->request->referer );
			return;
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
	$c->response->redirect( $c->request->referer );
}


=head2 search

Search the shop.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my @items;
		my %item_hash;
		
		# Look in the item name/desc
		my @results = $c->model( 'DB::ShopItem' )->search([
			{ name        => { 'LIKE', '%'.$search.'%'} },
			{ code        => { 'LIKE', '%'.$search.'%'} },
			{ description => { 'LIKE', '%'.$search.'%'} },
		]);
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
		foreach my $item ( keys %item_hash ) {
			push @items, $item_hash{ $item };
		}
		$c->stash->{ shop_results } = \@items;
	}
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

