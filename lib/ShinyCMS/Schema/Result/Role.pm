package ShinyCMS::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
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


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-07 17:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jUn1pY2iKZEQVG6uSRSyuQ



# EOF
1;

