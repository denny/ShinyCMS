package ShinyCMS::Schema::Result::Cart;

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

ShinyCMS::Schema::Result::Cart

=cut

__PACKAGE__->table("cart");

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

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "shopper",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 36 },
  "type",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ETY+hW1HcoDUieWU5aHT0w



# EOF
1;



# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
