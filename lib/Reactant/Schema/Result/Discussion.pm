package Reactant::Schema::Result::Discussion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("discussion");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "comments",
  "Reactant::Schema::Result::Comment",
  { "foreign.discussion" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-04 15:03:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DKV3oOynSoBrhwZ6oMZ55w


# You can replace this text with custom content, and it will be preserved on regeneration
1;

