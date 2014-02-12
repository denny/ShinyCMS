use utf8;
package ShinyCMS::Schema::Result::ShopCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ShopCategory

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

=head1 TABLE: C<shop_category>

=cut

__PACKAGE__->table("shop_category");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

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
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<shop_category_url_name>

=over 4

=item * L</url_name>

=back

=cut

__PACKAGE__->add_unique_constraint("shop_category_url_name", ["url_name"]);

=head1 RELATIONS

=head2 parent

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopCategory>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "ShinyCMS::Schema::Result::ShopCategory",
  { id => "parent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 shop_categories

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopCategory>

=cut

__PACKAGE__->has_many(
  "shop_categories",
  "ShinyCMS::Schema::Result::ShopCategory",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_categories

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemCategory>

=cut

__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.category" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CtQ7bTcCrsrANxmkjDOc4A


=head2 items

Type: many_to_many

Composing rels: L</shop_item_categories> -> item

For some reason this code keeps appearing/disappearing when DBIC::S::L is run :(

=cut

__PACKAGE__->many_to_many("items", "shop_item_categories", "item");


# EOF
__PACKAGE__->meta->make_immutable;
1;

