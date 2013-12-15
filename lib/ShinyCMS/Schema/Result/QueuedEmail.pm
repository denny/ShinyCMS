use utf8;
package ShinyCMS::Schema::Result::QueuedEmail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::QueuedEmail

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

=head1 TABLE: C<queued_email>

=cut

__PACKAGE__->table("queued_email");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 email

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 recipient

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 send

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  default_value: 'Not sent'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "email",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "recipient",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "send",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "status",
  {
    data_type => "varchar",
    default_value => "Not sent",
    is_nullable => 0,
    size => 20,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 email

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::AutoresponderEmail>

=cut

__PACKAGE__->belongs_to(
  "email",
  "ShinyCMS::Schema::Result::AutoresponderEmail",
  { id => "email" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 recipient

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::MailRecipient>

=cut

__PACKAGE__->belongs_to(
  "recipient",
  "ShinyCMS::Schema::Result::MailRecipient",
  { id => "recipient" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-12-15 10:24:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZvDuAP4viQsazlwfedPWFQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
