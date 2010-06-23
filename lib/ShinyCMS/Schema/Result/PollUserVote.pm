package ShinyCMS::Schema::Result::PollUserVote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("poll_user_vote");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "question",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "answer",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "user",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "ip_address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 15,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "question",
  "ShinyCMS::Schema::Result::PollQuestion",
  { id => "question" },
);
__PACKAGE__->belongs_to(
  "answer",
  "ShinyCMS::Schema::Result::PollAnswer",
  { id => "answer" },
);
__PACKAGE__->belongs_to("user", "ShinyCMS::Schema::Result::User", { id => "user" });


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-03-21 15:44:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1eddFy8Mb+xfknuiqF0Hhg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
