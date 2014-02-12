use utf8;
package ShinyCMS::Schema::Result::Image;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Image

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

=head1 TABLE: C<image>

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

=head2 path

  data_type: 'text'
  is_nullable: 0

=head2 caption

  data_type: 'text'
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 uploaded

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "mime",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "caption",
  { data_type => "text", is_nullable => 1 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "uploaded",
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lcnfCL3yf48s8Ov+NX5/bA



# EOF
__PACKAGE__->meta->make_immutable;
1;

