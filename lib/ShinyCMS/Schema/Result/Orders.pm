package ShinyCMS::Schema::Result::Orders;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("orders");
__PACKAGE__->add_columns(
  "id",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 36 },
  "shopper",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 36 },
  "type",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },
  "number",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "created",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "updated",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "comments",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "shipmethod",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "shipping",
  {
    data_type => "DECIMAL",
    default_value => "0.00",
    is_nullable => 0,
    size => 9,
  },
  "handling",
  {
    data_type => "DECIMAL",
    default_value => "0.00",
    is_nullable => 0,
    size => 9,
  },
  "tax",
  {
    data_type => "DECIMAL",
    default_value => "0.00",
    is_nullable => 0,
    size => 9,
  },
  "subtotal",
  {
    data_type => "DECIMAL",
    default_value => "0.00",
    is_nullable => 0,
    size => 9,
  },
  "total",
  {
    data_type => "DECIMAL",
    default_value => "0.00",
    is_nullable => 0,
    size => 9,
  },
  "billtofirstname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtolastname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtoaddress1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "billtoaddress2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "billtoaddress3",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "billtocity",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "billtostate",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "billtozip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "billtocountry",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtodayphone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtonightphone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtofax",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "billtoemail",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptosameasbillto",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },
  "shiptofirstname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptolastname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptoaddress1",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptoaddress2",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptoaddress3",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptocity",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptostate",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "shiptozip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "shiptocountry",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptodayphone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptonightphone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptofax",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "shiptoemail",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-08 15:43:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XrA2Ou6iVTgDO1hTqz7cGw



# EOF
1;

