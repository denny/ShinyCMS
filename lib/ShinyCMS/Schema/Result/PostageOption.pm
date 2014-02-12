use utf8;
package ShinyCMS::Schema::Result::PostageOption;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::PostageOption

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

=head1 TABLE: C<postage_option>

=cut

__PACKAGE__->table("postage_option");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 price

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

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
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "price",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "description",
  { data_type => "text", is_nullable => 1 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
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

=head2 order_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "ShinyCMS::Schema::Result::OrderItem",
  { "foreign.postage" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_postage_options

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemPostageOption>

=cut

__PACKAGE__->has_many(
  "shop_item_postage_options",
  "ShinyCMS::Schema::Result::ShopItemPostageOption",
  { "foreign.postage" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+8XOBH5DGeHZT6DUmuHgZw



# EOF
__PACKAGE__->meta->make_immutable;
1;

