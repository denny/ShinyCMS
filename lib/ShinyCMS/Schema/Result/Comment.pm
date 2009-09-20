package ShinyCMS::Schema::Result::Comment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("comment");
__PACKAGE__->add_columns(
  "discussion",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "parent",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "author_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "author_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "author_email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
  "author_link",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
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
__PACKAGE__->set_primary_key("discussion", "id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-19 21:39:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RZizRGPiBULCJtiYd231Fg



# EOF
1;

