use utf8;
package ShinyCMS::Schema::Result::ShopItemCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ShopItemCategory

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

=head1 TABLE: C<shop_item_category>

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

=head1 PRIMARY KEY

=over 4

=item * L</item>

=item * L</category>

=back

=cut

__PACKAGE__->set_primary_key("item", "category");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07014 @ 2011-11-19 02:30:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TLWdiknyHswy1DpkAGtygw



# EOF
__PACKAGE__->meta->make_immutable;
1;

