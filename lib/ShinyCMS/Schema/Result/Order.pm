use utf8;
package ShinyCMS::Schema::Result::Order;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Order

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

=head1 TABLE: C<order>

=cut

__PACKAGE__->table("order");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 session

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 1
  size: 72

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 telephone

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 billing_address

  data_type: 'text'
  is_nullable: 0

=head2 billing_town

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 billing_county

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billing_country

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 billing_postcode

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 delivery_address

  data_type: 'text'
  is_nullable: 1

=head2 delivery_town

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 delivery_county

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 delivery_country

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 delivery_postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 status

  data_type: 'varchar'
  default_value: 'Checkout incomplete'
  is_nullable: 0
  size: 50

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 updated

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 despatched

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "session",
  { data_type => "char", is_foreign_key => 1, is_nullable => 1, size => 72 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "telephone",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "billing_address",
  { data_type => "text", is_nullable => 0 },
  "billing_town",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "billing_county",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billing_country",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "billing_postcode",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "delivery_address",
  { data_type => "text", is_nullable => 1 },
  "delivery_town",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "delivery_county",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "delivery_country",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "delivery_postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "status",
  {
    data_type => "varchar",
    default_value => "Checkout incomplete",
    is_nullable => 0,
    size => 50,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "despatched",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
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
  { "foreign.order" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 session

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Session>

=cut

__PACKAGE__->belongs_to(
  "session",
  "ShinyCMS::Schema::Result::Session",
  { id => "session" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 user

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ShinyCMS::Schema::Result::User",
  { id => "user" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-05 14:36:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZPq53EP66QKCyovW3rtJug


=head2 total_items

Return the total number of items in this order

=cut

sub total_items {
	my( $self ) = @_;

	my $total;
	my @items = $self->order_items->all;
	foreach my $item ( @items ) {
		$total += $item->quantity;
	}

	return $total;
}


=head2 total_price_without_postage

Return the total price of the items in this order

=cut

sub total_price_without_postage {
	my( $self ) = @_;

	my $total = 0;
	my @items = $self->order_items->all;
	foreach my $item ( @items ) {
		$total += $item->total_price_without_postage;
	}

	return $total;
}


=head2 total_postage

Return the total price of postage for this order

=cut

sub total_postage {
	my( $self ) = @_;

	my $total = 0;
	my @items = $self->order_items->all;
	foreach my $item ( @items ) {
		$total += $item->total_postage;
	}

	return $total;
}


=head2 total_price

Return the total price of this order, including postage

=cut

sub total_price {
	my( $self ) = @_;

	my $total = 0;
	my @items = $self->order_items->all;
	foreach my $item ( @items ) {
		$total += $item->total_price;
	}

	return $total;
}



# EOF
__PACKAGE__->meta->make_immutable;
1;

