package ShinyCMS::Schema::Result::ShopItem;

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

ShinyCMS::Schema::Result::ShopItem

=cut

__PACKAGE__->table("shop_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 price

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 paypal_button

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "image",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "price",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "paypal_button",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("product_code", ["code"]);

=head1 RELATIONS

=head2 shop_item_categories

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemCategory>

=cut

__PACKAGE__->has_many(
  "shop_item_categories",
  "ShinyCMS::Schema::Result::ShopItemCategory",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MoQGzLRHQDuuswzMQsML6w


__PACKAGE__->many_to_many(
	categories => 'shop_item_categories', 'category'
);


=head2 in_category

Check to see if the item is in a particular category

=cut

sub in_category {
	my( $self, $wanted ) = @_;
	my @categories = $self->categories;
	foreach my $category ( @categories ) {
		return 1 if $category->id eq $wanted;
	}
	return 0;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

