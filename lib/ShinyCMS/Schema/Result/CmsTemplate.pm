use utf8;
package ShinyCMS::Schema::Result::CmsTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::CmsTemplate

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

=head1 TABLE: C<cms_template>

=cut

__PACKAGE__->table("cms_template");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template_file

  data_type: 'varchar'
  is_nullable: 0
  size: 100

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
  "template_file",
  { data_type => "varchar", is_nullable => 0, size => 100 },
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

=head1 RELATIONS

=head2 cms_pages

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CmsPage>

=cut

__PACKAGE__->has_many(
  "cms_pages",
  "ShinyCMS::Schema::Result::CmsPage",
  { "foreign.template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cms_template_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CmsTemplateElement>

=cut

__PACKAGE__->has_many(
  "cms_template_elements",
  "ShinyCMS::Schema::Result::CmsTemplateElement",
  { "foreign.template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-08 18:49:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hcCh4IXZAZ3xAWpL3I7DIw



# EOF
__PACKAGE__->meta->make_immutable;
1;

