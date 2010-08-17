package ShinyCMS::Schema::Result::Order;

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

ShinyCMS::Schema::Result::Order

=cut

__PACKAGE__->table("orders");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 36

=head2 shopper

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 36

=head2 type

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 number

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 created

  data_type: 'datetime'
  is_nullable: 1

=head2 updated

  data_type: 'datetime'
  is_nullable: 1

=head2 comments

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 shipmethod

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 shipping

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 handling

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 tax

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 subtotal

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 total

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 0
  size: [9,2]

=head2 billtofirstname

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtolastname

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtoaddress1

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billtoaddress2

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billtoaddress3

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billtocity

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billtostate

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 billtozip

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 billtocountry

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtodayphone

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtonightphone

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtofax

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 billtoemail

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptosameasbillto

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 shiptofirstname

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptolastname

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptoaddress1

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptoaddress2

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptoaddress3

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptocity

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptostate

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 shiptozip

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 shiptocountry

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptodayphone

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptonightphone

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptofax

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 shiptoemail

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "shopper",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "type",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "number",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "created",
  { data_type => "datetime", is_nullable => 1 },
  "updated",
  { data_type => "datetime", is_nullable => 1 },
  "comments",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "shipmethod",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "shipping",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "handling",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "tax",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "subtotal",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "total",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 0,
    size => [9, 2],
  },
  "billtofirstname",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtolastname",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtoaddress1",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billtoaddress2",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billtoaddress3",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billtocity",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billtostate",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "billtozip",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "billtocountry",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtodayphone",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtonightphone",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtofax",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "billtoemail",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptosameasbillto",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "shiptofirstname",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptolastname",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptoaddress1",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptoaddress2",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptoaddress3",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptocity",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptostate",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "shiptozip",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "shiptocountry",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptodayphone",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptonightphone",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptofax",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "shiptoemail",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mt07eYHoqjqn84DoU74kFA



# EOF
1;



# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
