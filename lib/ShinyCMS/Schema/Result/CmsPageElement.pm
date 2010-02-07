package ShinyCMS::Schema::Result::CmsPageElement;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("cms_page_element");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "page",
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
  "content",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("page", "ShinyCMS::Schema::Result::CmsPage", { id => "page" });


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-07 17:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oCHIj3nZMUCGGONn2PXEPQ



# EOF
1;

