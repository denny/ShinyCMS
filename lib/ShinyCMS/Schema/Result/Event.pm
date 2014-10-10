use utf8;
package ShinyCMS::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Event

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

=head1 TABLE: C<event>

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

=head2 url_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 start_date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1971-01-01 01:01:01'
  is_nullable: 0

=head2 end_date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1971-01-01 01:01:01'
  is_nullable: 0

=head2 address

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 link

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 booking_link

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "image",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "start_date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "1971-01-01 01:01:01",
    is_nullable => 0,
  },
  "end_date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "1971-01-01 01:01:01",
    is_nullable => 0,
  },
  "address",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "link",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "booking_link",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-10 18:32:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MhFk0clL9/i/TmqDy0/rRA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
