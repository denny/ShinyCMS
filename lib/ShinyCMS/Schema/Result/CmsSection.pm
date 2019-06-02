use utf8;
package ShinyCMS::Schema::Result::CmsSection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::CmsSection

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

=head1 TABLE: C<cms_section>

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

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 default_page

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
  "description",
  { data_type => "text", is_nullable => 1 },
  "default_page",
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

=head2 C<cms_section_url_name>

=over 4

=item * L</url_name>

=back

=cut

__PACKAGE__->add_unique_constraint("cms_section_url_name", ["url_name"]);

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

=head2 default_page

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::CmsPage>

=cut

__PACKAGE__->belongs_to(
  "default_page",
  "ShinyCMS::Schema::Result::CmsPage",
  { id => "default_page" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-02-08 15:48:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EU30Hip/GMNKUaQ8UNQeQA


=head2 pages

Return the pages that are in this section.

=cut

sub pages {
	my ( $self ) = @_;

	return $self->cms_pages->search(
		{},
		{
			order_by => 'menu_position',
		}
	);
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

