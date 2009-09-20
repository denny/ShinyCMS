package ShinyCMS::Schema::Result::ShopCategory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("shop_category");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
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
__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.category" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-20 19:46:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q0zPT8DzRSXoWSGiLMO64g


__PACKAGE__->many_to_many(
	items => 'shop_item_categories', 'item'
);


# EOF
1;

