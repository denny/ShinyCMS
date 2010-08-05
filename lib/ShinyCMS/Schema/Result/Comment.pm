package ShinyCMS::Schema::Result::Comment;

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

ShinyCMS::Schema::Result::Comment

=cut

__PACKAGE__->table("comment");

=head1 ACCESSORS

=head2 discussion

  data_type: 'integer'
  is_nullable: 0

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_nullable: 1

=head2 author_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 author_type

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 author_email

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 author_link

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 posted

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "discussion",
  { data_type => "integer", is_nullable => 0 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "parent",
  { data_type => "integer", is_nullable => 1 },
  "author_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "author_type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "author_email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "author_link",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "posted",
  { data_type => "datetime", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("discussion", "id");


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-05 21:13:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3oHz+d3HRGyGxWa7KUu+KQ



# EOF
__PACKAGE__->meta->make_immutable;
1;

