package ShinyCMS::Schema::Result::CmsForm;

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

ShinyCMS::Schema::Result::CmsForm

=cut

__PACKAGE__->table("cms_form");

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

=head2 redirect

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 action

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 email_to

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 template

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "redirect",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "action",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "email_to",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "template",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("url_name", ["url_name"]);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-10-04 21:13:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vS9VuCRu1r9OP+mPNECSRg



# EOF
__PACKAGE__->meta->make_immutable;
1;

