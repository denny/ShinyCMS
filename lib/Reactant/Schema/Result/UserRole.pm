package Reactant::Schema::Result::UserRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "user",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user", "role");
__PACKAGE__->belongs_to("user", "Reactant::Schema::Result::User", { id => "user" });
__PACKAGE__->belongs_to("role", "Reactant::Schema::Result::Role", { id => "role" });


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-18 18:06:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3H+R37sTFlOMDRwjplKrjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;

