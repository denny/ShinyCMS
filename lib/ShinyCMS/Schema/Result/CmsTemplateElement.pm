package ShinyCMS::Schema::Result::CmsTemplateElement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("cms_template_element");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "template",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "type",
  {
    data_type => "VARCHAR",
    default_value => "Text",
    is_nullable => 0,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::CmsTemplate",
  { id => "template" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-15 20:34:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JLl2C8+dTMZuTk+bUkLBLw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
