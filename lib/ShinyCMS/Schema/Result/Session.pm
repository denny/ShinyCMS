use utf8;
package ShinyCMS::Schema::Result::Session;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Session

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

=head1 TABLE: C<session>

=cut

__PACKAGE__->table("session");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 72

=head2 session_data

  data_type: 'text'
  is_nullable: 1

=head2 expires

  data_type: 'integer'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 72 },
  "session_data",
  { data_type => "text", is_nullable => 1 },
  "expires",
  { data_type => "integer", is_nullable => 1 },
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

=head2 baskets

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Basket>

=cut

__PACKAGE__->has_many(
  "baskets",
  "ShinyCMS::Schema::Result::Basket",
  { "foreign.session" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "ShinyCMS::Schema::Result::Order",
  { "foreign.session" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-06-21 00:20:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R/4Q2Djxitg9Rtm0oIo2mw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
