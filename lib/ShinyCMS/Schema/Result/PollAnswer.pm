use utf8;
package ShinyCMS::Schema::Result::PollAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::PollAnswer

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<poll_answer>

=cut

__PACKAGE__->table("poll_answer");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 question

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "question",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 poll_anon_votes

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PollAnonVote>

=cut

__PACKAGE__->has_many(
  "poll_anon_votes",
  "ShinyCMS::Schema::Result::PollAnonVote",
  { "foreign.answer" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_user_votes

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PollUserVote>

=cut

__PACKAGE__->has_many(
  "poll_user_votes",
  "ShinyCMS::Schema::Result::PollUserVote",
  { "foreign.answer" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 question

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PollQuestion>

=cut

__PACKAGE__->belongs_to(
  "question",
  "ShinyCMS::Schema::Result::PollQuestion",
  { id => "question" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0o0b48STZ1Mn27O7eq+lBA


=head2 votes

Return the total number of votes for this answer

=cut

sub votes {
	my ( $self ) = @_;

	return 0 + $self->poll_user_votes->count + $self->poll_anon_votes->count;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
