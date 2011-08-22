package ShinyCMS::Schema::Result::CmsTemplate;

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

ShinyCMS::Schema::Result::CmsTemplate

=cut

__PACKAGE__->table("cms_template");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 template_file

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "template_file",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
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


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-08-20 18:55:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oAYUem4n+mjkH56uSympqw



# EOF
__PACKAGE__->meta->make_immutable;
1;

