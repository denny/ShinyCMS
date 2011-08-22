package ShinyCMS::Schema::Result::ShopProductType;

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

ShinyCMS::Schema::Result::ShopProductType

=cut

__PACKAGE__->table("shop_product_type");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 template_file

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "template_file",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 shop_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItem>

=cut

__PACKAGE__->has_many(
  "shop_items",
  "ShinyCMS::Schema::Result::ShopItem",
  { "foreign.product_type" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_product_type_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopProductTypeElement>

=cut

__PACKAGE__->has_many(
  "shop_product_type_elements",
  "ShinyCMS::Schema::Result::ShopProductTypeElement",
  { "foreign.product_type" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-08-20 22:34:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ciYgZw/TPKziyTDxaOYgRw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
