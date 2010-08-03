package ShinyCMS::Schema::Result::PollAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

ShinyCMS::Schema::Result::PollAnswer

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "question",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
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

=head2 question

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PollQuestion>

=cut

__PACKAGE__->belongs_to(
  "question",
  "ShinyCMS::Schema::Result::PollQuestion",
  { id => "question" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7G7zsrT3J9R+LY1SmUsK4Q


# Return the number of votes for this answer
sub votes {
	my ( $self ) = @_;
	
	return $self->poll_user_votes->count + $self->poll_anon_votes->count || 0;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

