package ShinyCMS::Schema::Result::CmsPage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("cms_page");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "url_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "template",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("url_name", ["url_name"]);
__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::CmsTemplate",
  { id => "template" },
);
__PACKAGE__->has_many(
  "cms_page_elements",
  "ShinyCMS::Schema::Result::CmsPageElement",
  { "foreign.page" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-10-08 15:43:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lc3nULM6XiQ1r+YKQj1Iow

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-12-12 16:17:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R/Ct03cqxTJSIMkzQBWZHQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
