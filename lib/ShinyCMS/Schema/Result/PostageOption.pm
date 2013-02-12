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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 order_item_postage_options

Type: has_many

Related object: L<ShinyCMS::Schema::Result::OrderItemPostageOption>

=cut

__PACKAGE__->has_many(
  "order_item_postage_options",
  "ShinyCMS::Schema::Result::OrderItemPostageOption",
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

=head2 items

Type: many_to_many

Composing rels: L</shop_item_postage_options> -> item

=cut

__PACKAGE__->many_to_many("items", "shop_item_postage_options", "item");

=head2 items_2s

Type: many_to_many

Composing rels: L</order_item_postage_options> -> item

=cut

__PACKAGE__->many_to_many("items_2s", "order_item_postage_options", "item");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-02-12 18:57:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5b3asdh5WvUVp0tJ2aVczQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
