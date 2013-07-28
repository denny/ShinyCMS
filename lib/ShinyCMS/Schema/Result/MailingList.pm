use utf8;
package ShinyCMS::Schema::Result::MailingList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::MailingList

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

=head1 TABLE: C<mailing_list>

=cut

__PACKAGE__->table("mailing_list");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 private

  data_type: 'tinyint'
  default_value: 0
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
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "private",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
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

=head2 newsletters

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Newsletter>

=cut

__PACKAGE__->has_many(
  "newsletters",
  "ShinyCMS::Schema::Result::Newsletter",
  { "foreign.list" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-27 21:30:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SrlMYyrGnakriPowe3aTOg


__PACKAGE__->many_to_many( recipients => 'list_recipients', 'recipient' );


# EOF
__PACKAGE__->meta->make_immutable;
1;

