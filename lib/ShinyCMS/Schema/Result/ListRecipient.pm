package ShinyCMS::Schema::Result::ListRecipient;

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

ShinyCMS::Schema::Result::ListRecipient

=cut

__PACKAGE__->table("list_recipient");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 list

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "list",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::MailingList>

=cut

__PACKAGE__->belongs_to(
  "list",
  "ShinyCMS::Schema::Result::MailingList",
  { id => "list" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 recipient

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::MailRecipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "ShinyCMS::Schema::Result::MailRecipient",
  { id => "recipient" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-11-06 01:23:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rIh7Qx06f0TMad1HXcZ4MQ



# EOF
__PACKAGE__->meta->make_immutable;
1;

