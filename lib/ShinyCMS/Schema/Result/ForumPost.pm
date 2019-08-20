use utf8;
package ShinyCMS::Schema::Result::ForumPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::ForumPost

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

=head1 TABLE: C<forum_post>

=cut

__PACKAGE__->table("forum_post");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 forum

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 hidden

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 posted

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 display_order

  data_type: 'integer'
  is_nullable: 1

=head2 commented_on

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1971-01-01 01:01:01'
  is_nullable: 0

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "forum",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "hidden",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "posted",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "display_order",
  { data_type => "integer", is_nullable => 1 },
  "commented_on",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "1971-01-01 01:01:01",
    is_nullable => 0,
  },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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

=head2 discussion

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "ShinyCMS::Schema::Result::Discussion",
  { id => "discussion" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 forum

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::Forum>

=cut

__PACKAGE__->belongs_to(
  "forum",
  "ShinyCMS::Schema::Result::Forum",
  { id => "forum" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-06-21 00:20:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fvmzCbkpZ9LWHN+3OR9dfg


=head2 comment_count

Return the total number of comments on this post

=cut

sub comment_count {
	my ( $self ) = @_;

	return 0 unless $self->discussion;
	return 0 + $self->discussion->comments->count;
}


=head2 most_recent_comment

Return details of the most recent comment on this post

=cut

sub most_recent_comment {
	my( $self ) = @_;

	return unless $self->discussion;

	return $self->discussion->comments->search(
		{},
		{
			order_by => { -desc => 'posted' },
			rows => 1,
		},
	)->first;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

