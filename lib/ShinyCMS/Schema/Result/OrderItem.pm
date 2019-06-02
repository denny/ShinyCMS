use utf8;
package ShinyCMS::Schema::Result::OrderItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::OrderItem

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

=head1 TABLE: C<order_item>

=cut

__PACKAGE__->table("order_item");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 order

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 item

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 quantity

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 unit_price

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 postage

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "order",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "item",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "quantity",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "unit_price",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "postage",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 item

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ShopItem>

=cut

__PACKAGE__->belongs_to(
  "item",
  "ShinyCMS::Schema::Result::ShopItem",
  { id => "item" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 order

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Order>

=cut

__PACKAGE__->belongs_to(
  "order",
  "ShinyCMS::Schema::Result::Order",
  { id => "order" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 order_item_attributes

Type: has_many

Related object: L<ShinyCMS::Schema::Result::OrderItemAttribute>

=cut

__PACKAGE__->has_many(
  "order_item_attributes",
  "ShinyCMS::Schema::Result::OrderItemAttribute",
  { "foreign.item" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 postage

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::PostageOption>

=cut

__PACKAGE__->belongs_to(
  "postage",
  "ShinyCMS::Schema::Result::PostageOption",
  { id => "postage" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9dto1vcSr6WhuMJ+/CExpQ


=head2 total_price_without_postage

Return the total price of the quantity of this item in this order, exc. postage

=cut

sub total_price_without_postage {
	my( $self ) = @_;

	return $self->unit_price * $self->quantity;
}


=head2 total_postage

Return the total postage for the quantity of this item in this order

=cut

sub total_postage {
	my( $self ) = @_;

	return 0 unless $self->postage;
	return $self->postage->price * $self->quantity;
}


=head2 total_price

Return the total price of the quantity of this item in this order, inc. postage

=cut

sub total_price {
	my( $self ) = @_;

	my $goods   = $self->unit_price * $self->quantity;
	my $postage = 0;
	if ( $self->postage ) {
		$postage = $self->postage->price * $self->quantity;
	}
	return $goods + $postage;
}



# EOF
__PACKAGE__->meta->make_immutable;
1;

