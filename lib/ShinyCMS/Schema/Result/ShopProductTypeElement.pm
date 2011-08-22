package ShinyCMS::Schema::Result::ShopProductTypeElement;

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

ShinyCMS::Schema::Result::ShopProductTypeElement

=cut

__PACKAGE__->table("shop_product_type_element");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 product_type

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 type

  data_type: 'varchar'
  default_value: 'Short Text'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "product_type",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "type",
  {
    data_type => "varchar",
    default_value => "Short Text",
    is_nullable => 0,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 product_type

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopProductType>

=cut

__PACKAGE__->belongs_to(
  "product_type",
  "ShinyCMS::Schema::Result::ShopProductType",
  { id => "product_type" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-08-20 18:48:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ziSesDWqPsnmODIC+EJqfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
