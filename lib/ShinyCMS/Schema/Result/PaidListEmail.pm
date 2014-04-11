use utf8;
package ShinyCMS::Schema::Result::PaidListEmail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::PaidListEmail

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

=head1 TABLE: C<paid_list_email>

=cut

__PACKAGE__->table("paid_list_email");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 paid_list

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 subject

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 delay

  data_type: 'integer'
  is_nullable: 0

=head2 plaintext

  data_type: 'text'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "paid_list",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subject",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "template",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "delay",
  { data_type => "integer", is_nullable => 0 },
  "plaintext",
  { data_type => "text", is_nullable => 1 },
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

=head2 paid_list

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PaidList>

=cut

__PACKAGE__->belongs_to(
  "paid_list",
  "ShinyCMS::Schema::Result::PaidList",
  { id => "paid_list" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 paid_list_email_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PaidListEmailElement>

=cut

__PACKAGE__->has_many(
  "paid_list_email_elements",
  "ShinyCMS::Schema::Result::PaidListEmailElement",
  { "foreign.email" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 queued_paid_emails

Type: has_many

Related object: L<ShinyCMS::Schema::Result::QueuedPaidEmail>

=cut

__PACKAGE__->has_many(
  "queued_paid_emails",
  "ShinyCMS::Schema::Result::QueuedPaidEmail",
  { "foreign.email" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 template

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::NewsletterTemplate>

=cut

__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::NewsletterTemplate",
  { id => "template" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-04-07 16:38:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+10QtybaJLXQ4+GgeQC9+A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
