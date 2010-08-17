package ShinyCMS::Schema::Result::OrderItem;

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

ShinyCMS::Schema::Result::OrderItem

=cut

__PACKAGE__->table("order_items");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 36

=head2 orderid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 36

=head2 sku

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 25

=head2 quantity

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 price

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 total

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "orderid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "sku",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 25 },
  "quantity",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "price",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "total",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WEo2OgDDWs/wWWJFtuR4xw



# EOF
1;



# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
