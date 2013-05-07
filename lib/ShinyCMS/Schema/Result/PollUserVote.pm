use utf8;
package ShinyCMS::Schema::Result::PollUserVote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::PollUserVote

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

=head1 TABLE: C<poll_user_vote>

=cut

__PACKAGE__->table("poll_user_vote");

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

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 ip_address

  data_type: 'varchar'
  is_nullable: 0
  size: 15

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
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ip_address",
  { data_type => "varchar", is_nullable => 0, size => 15 },
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

=head2 answer

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PollAnswer>

=cut

__PACKAGE__->belongs_to(
  "answer",
  "ShinyCMS::Schema::Result::PollAnswer",
  { id => "answer" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
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

=head2 user

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ShinyCMS::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Rm2XXy0AiIqAYYIRdKE/6Q



# EOF
__PACKAGE__->meta->make_immutable;
1;

