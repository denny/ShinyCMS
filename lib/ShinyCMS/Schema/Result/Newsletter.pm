use utf8;
package ShinyCMS::Schema::Result::Newsletter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Newsletter

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

=head1 TABLE: C<newsletter>

=cut

__PACKAGE__->table("newsletter");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 plaintext

  data_type: 'text'
  is_nullable: 1

=head2 list

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  default_value: 'Not sent'
  is_nullable: 0
  size: 20

=head2 sent

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "template",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "plaintext",
  { data_type => "text", is_nullable => 1 },
  "list",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "status",
  {
    data_type => "varchar",
    default_value => "Not sent",
    is_nullable => 0,
    size => 20,
  },
  "sent",
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

=head2 list

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::MailingList>

=cut

__PACKAGE__->belongs_to(
  "list",
  "ShinyCMS::Schema::Result::MailingList",
  { id => "list" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 newsletter_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::NewsletterElement>

=cut

__PACKAGE__->has_many(
  "newsletter_elements",
  "ShinyCMS::Schema::Result::NewsletterElement",
  { "foreign.newsletter" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WAa4en5PP+cBBMNVqRagXQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
