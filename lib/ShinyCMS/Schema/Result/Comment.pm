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

=head2 uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_nullable: 1

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 author_type

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 author_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

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
  is_nullable: 1
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 1

=head2 posted

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 hidden

  data_type: 'varchar'
  is_nullable: 1
  size: 3

=cut

__PACKAGE__->add_columns(
  "uid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "parent",
  { data_type => "integer", is_nullable => 1 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "author_type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "author_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "author_email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "author_link",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "body",
  { data_type => "text", is_nullable => 1 },
  "posted",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "hidden",
  { data_type => "varchar", is_nullable => 1, size => 3 },
);
__PACKAGE__->set_primary_key("uid");

=head1 RELATIONS

=head2 discussion

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 author

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "ShinyCMS::Schema::Result::User",
  { id => "author" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 comments_like

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CommentLike>

=cut

__PACKAGE__->has_many(
  "comments_like",
  "ShinyCMS::Schema::Result::CommentLike",
  { "foreign.comment" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-05-18 14:57:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iIBVwOS+c0A3CgkEoiNTLQ


=head2 like_count

Return numbers of 'likes' this comment has received

=cut

sub like_count {
	my( $self ) = @_;
	return $self->comments_like->count || 0;
}


=head2 liked_by_user

Return true if comment is liked by specified user

=cut

sub liked_by_user {
	my( $self, $user_id ) = @_;
	my @likes = $self->comments_like;
	foreach my $like ( @likes ) {
		return 1 if $like->user and $like->user->id == $user_id;
	}
	return 0;
}


=head2 liked_by_anon

Return true if comment is liked by anon user with specified IP address

=cut

sub liked_by_anon {
	my( $self, $ip_address ) = @_;
	my @likes = $self->comments_like;
	foreach my $like ( @likes ) {
		return 1 if $like->ip_address eq $ip_address and not $like->user;
	}
	return 0;
}



# EOF
__PACKAGE__->meta->make_immutable;
1;

