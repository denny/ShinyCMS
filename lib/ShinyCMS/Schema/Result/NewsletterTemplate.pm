package ShinyCMS::Schema::Result::NewsletterTemplate;

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

ShinyCMS::Schema::Result::NewsletterTemplate

=cut

__PACKAGE__->table("newsletter_template");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 filename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "filename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 newsletters

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Newsletter>

=cut

__PACKAGE__->has_many(
  "newsletters",
  "ShinyCMS::Schema::Result::Newsletter",
  { "foreign.template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 newsletter_template_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::NewsletterTemplateElement>

=cut

__PACKAGE__->has_many(
  "newsletter_template_elements",
  "ShinyCMS::Schema::Result::NewsletterTemplateElement",
  { "foreign.template" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-11-02 14:23:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fNZ16UK/aIEl8dGjsJb1+Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
