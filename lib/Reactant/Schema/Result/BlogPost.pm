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
  "discussion",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "discussion",
  "Reactant::Schema::Result::Discussion",
  { id => "discussion" },
);
__PACKAGE__->belongs_to("blog", "Reactant::Schema::Result::Blog", { id => "blog" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-11 18:03:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qvc8tMiIz1gNhaiz7ImDrA



# EOF
1;

