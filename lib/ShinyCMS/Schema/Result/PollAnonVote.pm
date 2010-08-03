package ShinyCMS::Schema::Result::PollAnonVote;

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

ShinyCMS::Schema::Result::PollAnonVote

=cut

__PACKAGE__->table("poll_anon_vote");

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

=head2 ip_address

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "question",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "ip_address",
  { data_type => "varchar", is_nullable => 0, size => 15 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 answer

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PollAnswer>

=cut

__PACKAGE__->belongs_to(
  "answer",
  "ShinyCMS::Schema::Result::PollAnswer",
  { id => "answer" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WOQ/G1uETrrCXKKfyteo7Q



# EOF
__PACKAGE__->meta->make_immutable;
1;

