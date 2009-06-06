package Reactant::Schema::Result::BlogPostDiscussion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("blog_post_discussion");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "blog_post",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "blog_post",
  "Reactant::Schema::Result::BlogPost",
  { id => "blog_post" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-06-05 00:56:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WA0Ug+rzfjfMVNLogpR6DQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
