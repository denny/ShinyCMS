package ShinyCMS::Schema::Result::Image;

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

ShinyCMS::Schema::Result::Image

=cut

__PACKAGE__->table("image");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 mime

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 uploaded

  data_type: 'datetime'
  is_nullable: 0

=head2 path

  data_type: 'text'
  is_nullable: 0

=head2 caption

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "mime",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "uploaded",
  { data_type => "datetime", is_nullable => 0 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "caption",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FKj70fEB5eOHZzAkaoLy6Q



# EOF
__PACKAGE__->meta->make_immutable;
1;

