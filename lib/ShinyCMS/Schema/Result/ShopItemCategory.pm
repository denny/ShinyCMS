package ShinyCMS::Schema::Result::ShopItemCategory;

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

ShinyCMS::Schema::Result::ShopItemCategory

=cut

__PACKAGE__->table("shop_item_category");

=head1 ACCESSORS

=head2 item

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 category

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "item",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "category",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("item", "category");

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopItem>

=cut

__PACKAGE__->belongs_to(
  "item",
  "ShinyCMS::Schema::Result::ShopItem",
  { id => "item" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 category

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopCategory>

=cut

__PACKAGE__->belongs_to(
  "category",
  "ShinyCMS::Schema::Result::ShopCategory",
  { id => "category" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c0U3cHT3qbA4m/oOffFkOw



# EOF
__PACKAGE__->meta->make_immutable;
1;

