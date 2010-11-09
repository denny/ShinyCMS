package ShinyCMS::Schema::Result::Newsletter;

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

ShinyCMS::Schema::Result::Newsletter

=cut

__PACKAGE__->table("newsletter");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 sent

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "template",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "sent",
  { data_type => "datetime", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 template

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::NewsletterTemplate>

=cut

__PACKAGE__->belongs_to(
  "template",
  "ShinyCMS::Schema::Result::NewsletterTemplate",
  { id => "template" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 newsletter_elements

Type: has_many

Related object: L<ShinyCMS::Schema::Result::NewsletterElement>

=cut

__PACKAGE__->has_many(
  "newsletter_elements",
  "ShinyCMS::Schema::Result::NewsletterElement",
  { "foreign.newsletter" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-11-09 17:29:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c9r88ma1mhsdEo2NNCPY1Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
