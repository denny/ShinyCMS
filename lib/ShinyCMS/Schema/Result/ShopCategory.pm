package ShinyCMS::Schema::Result::ShopCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("shop_category");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "parent",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 11,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "url_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("url_name", ["url_name"]);
__PACKAGE__->belongs_to(
  "parent",
  "ShinyCMS::Schema::Result::ShopCategory",
  { id => "parent" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "shop_categories",
  "ShinyCMS::Schema::Result::ShopCategory",
  { "foreign.parent" => "self.id" },
);
__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.category" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-07 17:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vJAILBaNmV/CZ5/nyRnesg


__PACKAGE__->many_to_many(
	items => 'shop_item_categories', 'item'
);


# EOF
1;

