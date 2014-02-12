use utf8;
package ShinyCMS::Schema::Result::CmsPage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::CmsPage

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

=head1 TABLE: C<cms_page>

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

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

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

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "template",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "section",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "menu_position",
  { data_type => "integer", is_nullable => 1 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "created",
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

=head1 UNIQUE CONSTRAINTS

=head2 C<cms_page_url_name>

=over 4

=item * L</section>

=item * L</url_name>

=back

=cut

__PACKAGE__->add_unique_constraint("cms_page_url_name", ["section", "url_name"]);

=head1 RELATIONS

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

=head2 cms_sections

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CmsSection>

=cut

__PACKAGE__->has_many(
  "cms_sections",
  "ShinyCMS::Schema::Result::CmsSection",
  { "foreign.default_page" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 template

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::CmsTemplate>

=cut

__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::CmsTemplate",
  { id => "template" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vzKfYF+iQF300FBKRO5Ghg



# EOF
__PACKAGE__->meta->make_immutable;
1;

