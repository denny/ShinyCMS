package ShinyCMS::Schema::Result::ShopItemCategory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("shop_item_category");
__PACKAGE__->add_columns(
  "item",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "category",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("item", "category");
__PACKAGE__->belongs_to("item", "ShinyCMS::Schema::Result::ShopItem", { id => "item" });
__PACKAGE__->belongs_to(
  "category",
  "ShinyCMS::Schema::Result::ShopCategory",
  { id => "category" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-12-12 16:17:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nS6zt75OCIZTSVjSKacZhA



# EOF
1;

