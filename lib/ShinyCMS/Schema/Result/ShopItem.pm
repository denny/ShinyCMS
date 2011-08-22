package ShinyCMS::Schema::Result::ShopItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

ShinyCMS::Schema::Result::ShopItem

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
  is_nullable: 1
  size: 200

=head2 code

  data_type: 'varchar'
  is_nullable: 1
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
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 added

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
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "code",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "image",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "price",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "added",
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
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("product_code", ["code"]);

=head1 RELATIONS

=head2 product_type

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopProductType>

=cut

__PACKAGE__->belongs_to(
  "product_type",
  "ShinyCMS::Schema::Result::ShopProductType",
  { id => "product_type" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-08-22 13:01:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9GDJo9tEY8vYHSrR5zh7eQ


__PACKAGE__->many_to_many(
	categories => 'shop_item_categories', 'category'
);


=head2 in_category

Check to see if the item is in a particular category

=cut

sub in_category {
	my( $self, $wanted ) = @_;
	my @categories = $self->categories;
	foreach my $category ( @categories ) {
		return 1 if $category->id eq $wanted;
	}
	return 0;
}


=head2 elements

Return a hash containing the associated elements

=cut

sub elements {
	my( $self ) = @_;
	
	my $elements = {};
	my @elements = $self->shop_item_elements;
	foreach my $element ( @elements ) {
		$elements->{ $element->name } = $element->content;
	}

	return $elements;
}



# EOF
__PACKAGE__->meta->make_immutable;
1;

