package ShinyCMS::Schema::Result::CmsTemplate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("cms_template");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "cms_pages",
  "ShinyCMS::Schema::Result::CmsPage",
  { "foreign.template" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-09-20 19:46:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:osE3vjjT1FShZLfrS2Vd+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
