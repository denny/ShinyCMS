use utf8;
package ShinyCMS::Schema::Result::ShopItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ShopItem

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<shop_item>

=cut

__PACKAGE__->table("shop_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 product_type

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 price

  data_type: 'decimal'
  is_nullable: 1
  size: [9,2]

=head2 stock

  data_type: 'integer'
  is_nullable: 1

=head2 restock_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 updated

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "product_type",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "image",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "price",
  { data_type => "decimal", is_nullable => 1, size => [9, 2] },
  "stock",
  { data_type => "integer", is_nullable => 1 },
  "restock_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<shop_item_product_code>

=over 4

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint("shop_item_product_code", ["code"]);

=head1 RELATIONS

=head2 basket_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BasketItem>

=cut

__PACKAGE__->has_many(
  "basket_items",
  "ShinyCMS::Schema::Result::BasketItem",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 discussion

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 order_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "ShinyCMS::Schema::Result::OrderItem",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_type

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopProductType>

=cut

__PACKAGE__->belongs_to(
  "product_type",
  "ShinyCMS::Schema::Result::ShopProductType",
  { id => "product_type" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 shop_item_categories

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemCategory>

=cut

__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemElement>

=cut

__PACKAGE__->has_many(
  "shop_item_elements",
  "ShinyCMS::Schema::Result::ShopItemElement",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_favourites

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemFavourite>

=cut

__PACKAGE__->has_many(
  "shop_item_favourites",
  "ShinyCMS::Schema::Result::ShopItemFavourite",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_postage_options

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemPostageOption>

=cut

__PACKAGE__->has_many(
  "shop_item_postage_options",
  "ShinyCMS::Schema::Result::ShopItemPostageOption",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_views

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemView>

=cut

__PACKAGE__->has_many(
  "shop_item_views",
  "ShinyCMS::Schema::Result::ShopItemView",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_items_like

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemLike>

=cut

__PACKAGE__->has_many(
  "shop_items_like",
  "ShinyCMS::Schema::Result::ShopItemLike",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-03 16:19:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zrvoKBvniz69kFU9onkx4g

=head2 elements

Alias of `shop_item_elements`

=cut

__PACKAGE__->has_many(
  "elements",
  "ShinyCMS::Schema::Result::ShopItemElement",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


=head2 categories

Type: many_to_many

Composing rels: L</shop_item_categories> -> category

For some reason DBIC::S::L started handling this, then removed it again.  :(

=cut

__PACKAGE__->many_to_many("categories", "shop_item_categories", "category");


=head2 postages

Type: many_to_many

Composing rels: L</shop_item_postage_options> -> postage

Likewise, DBIC::S::L has something weird going on with this relationship. :-\

=cut

__PACKAGE__->many_to_many("postages", "shop_item_postage_options", "postage");


=head2 in_category

Check to see if the item is in a particular category

=cut

sub in_category {
	my( $self, $wanted ) = @_;
	my @categories = $self->categories->all;
	foreach my $category ( @categories ) {
		return 1 if $category->id == $wanted;
	}
	return 0;
}


=head2 has_postage_option

Check to see if the item has a particular postage option

=cut

sub has_postage_option {
	my( $self, $wanted ) = @_;
	my @options = $self->postages->all;
	foreach my $option ( @options ) {
		return 1 if $option->id == $wanted;
	}
	return 0;
}


=head2 get_elements

Return a hash containing the associated elements

=cut

sub get_elements {
	my( $self ) = @_;

	my $elements = {};
	my @elements = $self->shop_item_elements;
	foreach my $element ( @elements ) {
		$elements->{ $element->name } = $element->content;
	}

	return $elements;
}


=head2 like_count

Return numbers of 'likes' this item has received

=cut

sub like_count {
	my( $self ) = @_;
	return 0 + $self->shop_items_like->count;
}


=head2 liked_by_user

Return true if item is liked by specified user

=cut

sub liked_by_user {
	my( $self, $user_id ) = @_;
	return $self->shop_items_like->count({
		user => $user_id,
	});
}


=head2 liked_by_anon

Return true if item is liked by anon user with specified IP address

=cut

sub liked_by_anon {
	my( $self, $ip_address ) = @_;
	return $self->shop_items_like->count({
		ip_address => $ip_address,
		user       => undef,
	});
}


=head2 favourited_by_user

Return true if item is favourited by specified user

=cut

sub favourited_by_user {
	my( $self, $user_id ) = @_;
	my @faves = $self->shop_item_favourites;
	foreach my $fave ( @faves ) {
		return 1 if $fave->user->id == $user_id;
	}
	return 0;
}


=head2 tagset

Return the tagset for this shop item

=cut

sub tagset {
    my ( $self ) = @_;

    $self->result_source->schema->resultset( 'Tagset' )->find_or_create({
        resource_type => 'ShopItem',
        resource_id   => $self->id,
  			hidden        => $self->hidden,
    });
}


=head2 tags

Return the tag list for this news item

=cut

sub tags {
    my ( $self ) = @_;

    return unless $self->tagset;

    return $self->tagset->tag_list;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
