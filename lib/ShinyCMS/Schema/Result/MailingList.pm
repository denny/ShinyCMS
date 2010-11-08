package ShinyCMS::Schema::Result::MailingList;

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

ShinyCMS::Schema::Result::MailingList

=cut

__PACKAGE__->table("mailing_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list_recipients

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ListRecipient>

=cut

__PACKAGE__->has_many(
  "list_recipients",
  "ShinyCMS::Schema::Result::ListRecipient",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-11-06 01:23:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y11kqDUujHNtm4CcQgMV5Q


__PACKAGE__->many_to_many( roles => 'list_recipients', 'mail_recipient' );


# EOF
__PACKAGE__->meta->make_immutable;
1;

