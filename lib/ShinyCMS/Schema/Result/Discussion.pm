package ShinyCMS::Schema::Result::Discussion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("discussion");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "resource_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "resource_type",
  {
    data_type => "VARCHAR",
    default_value => "BlogPost",
    is_nullable => 0,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "blog_posts",
  "ShinyCMS::Schema::Result::BlogPost",
  { "foreign.discussion" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-06 15:44:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C4s0kacYjf1y39qd6c+RxA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
