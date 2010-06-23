package ShinyCMS::Schema::Result::PollAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("poll_answer");
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
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "poll_anon_votes",
  "ShinyCMS::Schema::Result::PollAnonVote",
  { "foreign.answer" => "self.id" },
);
__PACKAGE__->belongs_to(
  "question",
  "ShinyCMS::Schema::Result::PollQuestion",
  { id => "question" },
);
__PACKAGE__->has_many(
  "poll_user_votes",
  "ShinyCMS::Schema::Result::PollUserVote",
  { "foreign.answer" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-03-15 00:03:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eRMzcukmOfmn/yU9b3UI+Q


# Return the number of votes for this answer
sub votes {
	my ( $self ) = @_;
	
	return $self->poll_user_votes->count + $self->poll_anon_votes->count || 0;
}


# EOF
1;

