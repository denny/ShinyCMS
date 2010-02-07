package ShinyCMS::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "user",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "role",
  {
    data_type => "INT",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
);
__PACKAGE__->set_primary_key("user", "role");
__PACKAGE__->belongs_to("user", "ShinyCMS::Schema::Result::User", { id => "user" });
__PACKAGE__->belongs_to("role", "ShinyCMS::Schema::Result::Role", { id => "role" });


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-07 17:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rHEinlvSxDUDKzv+QU9dWg



# EOF
1;

