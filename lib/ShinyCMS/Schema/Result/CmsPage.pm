package ShinyCMS::Schema::Result::CmsPage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("cms_page");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
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
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
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


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-07 17:18:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SqHf+F9PCfEsrm4HJkgL/A



# EOF
1;

