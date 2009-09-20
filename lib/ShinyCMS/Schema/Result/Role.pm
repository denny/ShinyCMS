package ShinyCMS::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "user_roles",
  "ShinyCMS::Schema::Result::UserRole",
  { "foreign.role" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-20 19:46:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S4BqKVdwwNYnEmDIhC298A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
