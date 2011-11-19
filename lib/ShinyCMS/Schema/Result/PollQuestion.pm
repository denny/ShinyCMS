use utf8;
package ShinyCMS::Schema::Result::PollQuestion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::PollQuestion

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

=head1 TABLE: C<poll_question>

=cut

__PACKAGE__->table("poll_question");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 question

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "question",
  { data_type => "varchar", is_nullable => 0, size => 100 },
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
  { "foreign.question" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_answers

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PollAnswer>

=cut

__PACKAGE__->has_many(
  "poll_answers",
  "ShinyCMS::Schema::Result::PollAnswer",
  { "foreign.question" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_user_votes

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PollUserVote>

=cut

__PACKAGE__->has_many(
  "poll_user_votes",
  "ShinyCMS::Schema::Result::PollUserVote",
  { "foreign.question" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-11-19 02:30:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OeEzaVXBFgZmaEH3J95HMw


=head2 votes

Return the total number of votes for this poll

=cut

sub votes {
	my ( $self ) = @_;
	
	return $self->poll_user_votes->count + $self->poll_anon_votes->count || 0;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

