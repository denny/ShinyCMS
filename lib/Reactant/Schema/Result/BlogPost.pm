package Reactant::Schema::Result::BlogPost;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("blog_post");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "blog",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "body",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "posted",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("blog", "Reactant::Schema::Result::Blog", { id => "blog" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-04 15:03:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lPdILafgfmdMqAJJXx5RAw


# You can replace this text with custom content, and it will be preserved on regeneration
1;

