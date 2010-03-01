package ShinyCMS::Schema::Result::BlogPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("blog_post");
__PACKAGE__->add_columns(
  "blog",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
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
    data_type => "TIMESTAMP",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "discussion",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 11,
  },
);
__PACKAGE__->set_primary_key("blog", "id");
__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to("blog", "ShinyCMS::Schema::Result::Blog", { id => "blog" });


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-03-01 00:21:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uMlxhpl46fumK4TC+yqxYg



# EOF
1;

