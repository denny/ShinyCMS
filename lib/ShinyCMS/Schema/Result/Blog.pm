package ShinyCMS::Schema::Result::Blog;

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

ShinyCMS::Schema::Result::Blog

=cut

__PACKAGE__->table("blog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 blog_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "ShinyCMS::Schema::Result::BlogPost",
  { "foreign.blog" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-05 14:31:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:URu8Z5RaI3ZA+RcxwRvIug



# EOF
__PACKAGE__->meta->make_immutable;
1;

