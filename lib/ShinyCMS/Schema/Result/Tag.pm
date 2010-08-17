package ShinyCMS::Schema::Result::Tag;

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

ShinyCMS::Schema::Result::Tag

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 tag

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tagset

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tag",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tagset",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("tag", "tagset");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-17 22:51:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eLJLPNiW5FiqrhqFsIlxyA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
