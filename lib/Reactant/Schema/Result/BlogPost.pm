package Reactant::Schema::Result::BlogPost;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("blog_post");
__PACKAGE__->add_columns(
  "blog",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "id",
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
  "discussion",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("blog", "id");
__PACKAGE__->belongs_to(
  "discussion",
  "Reactant::Schema::Result::Discussion",
  { id => "discussion" },
);
__PACKAGE__->belongs_to("blog", "Reactant::Schema::Result::Blog", { id => "blog" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-17 20:34:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lAZIspZHq+GRc69wdDEMrQ



# EOF
1;

