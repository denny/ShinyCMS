package ShinyCMS::Schema::Result::PollQuestion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("poll_question");
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
  { "foreign.question" => "self.id" },
);
__PACKAGE__->has_many(
  "poll_answers",
  "ShinyCMS::Schema::Result::PollAnswer",
  { "foreign.question" => "self.id" },
);
__PACKAGE__->has_many(
  "poll_user_votes",
  "ShinyCMS::Schema::Result::PollUserVote",
  { "foreign.question" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-03-20 13:18:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fuG85vpiZardTqLHLFbIzg


# Return the total number of votes for this poll
sub votes {
	my ( $self ) = @_;
	
	return $self->poll_user_votes->count + $self->poll_anon_votes->count || 0;
}


# EOF
1;

