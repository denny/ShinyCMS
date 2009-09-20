package Reactant::Schema::Result::ShopItem;

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


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 18:06:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DqMr2s1rtqFtcQAT0QxyEw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
