package ShinyCMS::Schema::Result::ShopItem;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("shop_item");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "image",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
  "price",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "paypal_button",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("product_code", ["code"]);
__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.item" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-03 22:23:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uClDipQG9mVgbNlUVti35g


__PACKAGE__->many_to_many(
	categories => 'shop_item_categories', 'category'
);


# Check to see if the item is in a particular category
sub in_category {
	my( $self, $wanted ) = @_;
	my @categories = $self->categories;
	foreach my $category ( @categories ) {
		return 1 if $category->id eq $wanted;
	}
	return 0;
}


# EOF
1;

