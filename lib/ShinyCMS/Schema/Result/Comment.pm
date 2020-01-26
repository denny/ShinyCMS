use utf8;
package ShinyCMS::Schema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Comment

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

=head1 TABLE: C<comment>

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
  is_foreign_key: 1
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

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 spam

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "uid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "id",
  { data_type => "integer", is_nullable => 0 },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "spam",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</uid>

=back

=cut

__PACKAGE__->set_primary_key("uid");

=head1 RELATIONS

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
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 comments

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ShinyCMS::Schema::Result::Comment",
  { "foreign.parent" => "self.uid" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 discussion

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 parent

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "ShinyCMS::Schema::Result::Comment",
  { uid => "parent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-26 21:06:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wog207geJGYRKXrt0URsTQ


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
	return unless $self->comments_like->count > 0;
	return $self->comments_like->search({ user => $user_id })->count;
}


=head2 liked_by_anon

Return true if comment is liked by anon user with specified IP address

=cut

sub liked_by_anon {
	my( $self, $ip_address ) = @_;
	return unless $self->comments_like->count > 0;
	return $self->comments_like->search({
		ip_address => $ip_address,
		user       => undef,
	})->count;
}


=head2 mark_as_spam

Set the spam flag to true, and return the previous status.

=cut

sub mark_as_spam {
	my( $self ) = @_;

	my $prev = $self->spam;

	$self->update({ spam => 1 });

    return $prev;
}


=head2 mark_as_not_spam

Set the spam flag to false, and return the previous status.

=cut

sub mark_as_not_spam {
	my( $self ) = @_;

	my $prev = $self->spam;

	$self->update({ spam => 0 });

    return $prev;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
