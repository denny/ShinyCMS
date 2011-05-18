package ShinyCMS::Schema::Result::CommentLike;

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

ShinyCMS::Schema::Result::CommentLike

=cut

__PACKAGE__->table("comment_like");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 comment

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 ip_address

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "comment",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "ip_address",
  { data_type => "varchar", is_nullable => 0, size => 15 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 comment

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->belongs_to(
  "comment",
  "ShinyCMS::Schema::Result::Comment",
  { uid => "comment" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "ShinyCMS::Schema::Result::User",
  { id => "user" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-05-18 14:57:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WbiNd5OkaVRkyvsQ+dx8Qw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
