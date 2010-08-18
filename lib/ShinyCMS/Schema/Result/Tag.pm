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
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tag",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tagset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("tag", "tagset");

=head1 RELATIONS

=head2 tagset

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Tagset>

=cut

__PACKAGE__->belongs_to(
  "tagset",
  "ShinyCMS::Schema::Result::Tagset",
  { id => "tagset" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-17 23:18:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zz/xtu6tWJarbcK5Js2gAA



# EOF
__PACKAGE__->meta->make_immutable;
1;

