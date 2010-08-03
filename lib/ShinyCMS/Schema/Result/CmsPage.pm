package ShinyCMS::Schema::Result::CmsPage;

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

ShinyCMS::Schema::Result::CmsPage

=cut

__PACKAGE__->table("cms_page");

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

=head2 template

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 section

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

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
  "template",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "section",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "menu_position",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("section_page", ["section", "url_name"]);

=head1 RELATIONS

=head2 template

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::CmsTemplate>

=cut

__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::CmsTemplate",
  { id => "template" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 section

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::CmsSection>

=cut

__PACKAGE__->belongs_to(
  "section",
  "ShinyCMS::Schema::Result::CmsSection",
  { id => "section" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 cms_page_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CmsPageElement>

=cut

__PACKAGE__->has_many(
  "cms_page_elements",
  "ShinyCMS::Schema::Result::CmsPageElement",
  { "foreign.page" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S2ow9vsytM9+Tgf88IoO9g



# EOF
__PACKAGE__->meta->make_immutable;
1;

