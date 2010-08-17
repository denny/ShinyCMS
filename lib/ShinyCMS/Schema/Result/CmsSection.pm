package ShinyCMS::Schema::Result::CmsSection;

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

ShinyCMS::Schema::Result::CmsSection

=cut

__PACKAGE__->table("cms_section");

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

=head2 default_page

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 menu_position

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "default_page",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "menu_position",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("url_name", ["url_name"]);

=head1 RELATIONS

=head2 cms_pages

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CmsPage>

=cut

__PACKAGE__->has_many(
  "cms_pages",
  "ShinyCMS::Schema::Result::CmsPage",
  { "foreign.section" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1660E2cmq4vjSA9QtpAx+w



# EOF
__PACKAGE__->meta->make_immutable;
1;

