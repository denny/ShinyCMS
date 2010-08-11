package ShinyCMS::Schema::Result::Event;

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

ShinyCMS::Schema::Result::Event

=cut

__PACKAGE__->table("event");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 start_date

  data_type: 'datetime'
  is_nullable: 0

=head2 end_date

  data_type: 'datetime'
  is_nullable: 1

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 link

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "start_date",
  { data_type => "datetime", is_nullable => 0 },
  "end_date",
  { data_type => "datetime", is_nullable => 1 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "link",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-11 17:01:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c+eIaywNwLRTvL6OjL1nDg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
