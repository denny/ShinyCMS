use utf8;
package ShinyCMS::Schema::Result::Forum;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Forum

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

=head1 TABLE: C<forum>

=cut

__PACKAGE__->table("forum");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 section

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 display_order

  data_type: 'integer'
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "section",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "display_order",
  { data_type => "integer", is_nullable => 1 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<forum_url_name>

=over 4

=item * L</section>

=item * L</url_name>

=back

=cut

__PACKAGE__->add_unique_constraint("forum_url_name", ["section", "url_name"]);

=head1 RELATIONS

=head2 forum_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ForumPost>

=cut

__PACKAGE__->has_many(
  "forum_posts",
  "ShinyCMS::Schema::Result::ForumPost",
  { "foreign.forum" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 section

Type: belongs_to

Related object: L<ShinyCMS::Schema::Result::ForumSection>

=cut

__PACKAGE__->belongs_to(
  "section",
  "ShinyCMS::Schema::Result::ForumSection",
  { id => "section" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-07 13:21:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fcTFGCv6ZndCOFmIGVLTRg


=head2 post_count

Return total count of top-level posts in this forum.

=cut

sub post_count {
	my( $self ) = @_;
	return $self->forum_posts->count;
}


=head2 comment_count

Return total count of comments in this forum.

=cut

sub comment_count {
	my( $self ) = @_;

	return $self->forum_posts->search_related('discussion')
		->search_related('comments')->count;
}


=head2 sticky_posts

Return associated posts with a specified display order.

=cut

sub sticky_posts {
	my( $self ) = @_;
	return $self->forum_posts->search(
		{
            display_order => { '!=' => undef },
            posted        => { '<=' => \'current_timestamp' },
        },
		{
            order_by => 'display_order',
        }
	);
}


=head2 non_sticky_posts

Return associated posts that don't have a specified display order.

=cut

sub non_sticky_posts {
	my( $self ) = @_;
	return $self->forum_posts->search({
        display_order => undef,
        posted        => { '<=' => \'current_timestamp' },
    });
}


=head2 most_recent_comment

Returns details of the most recent comment on a post in this forum

=cut

sub most_recent_comment {
	my( $self ) = @_;

	my $most_recent_comment = $self->forum_posts
			->search_related('discussion')->search_related('comments')->search(
		{},
		{
			order_by => { -desc => 'posted' },
		}
	)->first;

	return 0 unless $most_recent_comment;

	my $most_recent_post = $most_recent_comment->discussion
		->search_related('forum_posts')->first;

	my $mrc = {};
	$mrc->{ comment } = $most_recent_comment;
	$mrc->{ post    } = $most_recent_post;
	return $mrc;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;
