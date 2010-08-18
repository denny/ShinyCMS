package ShinyCMS::Schema::Result::Tagset;

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

ShinyCMS::Schema::Result::Tagset

=cut

__PACKAGE__->table("tagset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 resource_id

  data_type: 'integer'
  is_nullable: 0

=head2 resource_type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "resource_type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 tags

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
  "tags",
  "ShinyCMS::Schema::Result::Tag",
  { "foreign.tagset" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-17 23:18:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ve4kGuOL2h54K0reSxAozg



# EOF
__PACKAGE__->meta->make_immutable;
1;

