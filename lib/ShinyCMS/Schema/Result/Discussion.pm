use utf8;
package ShinyCMS::Schema::Result::Discussion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::Discussion

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

=head1 TABLE: C<discussion>

=cut

__PACKAGE__->table("discussion");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 resource_id

  data_type: 'integer'
  is_nullable: 0

=head2 resource_type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "resource_type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
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

=head1 RELATIONS

=head2 blog_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "ShinyCMS::Schema::Result::BlogPost",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 comments

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ShinyCMS::Schema::Result::Comment",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 forum_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ForumPost>

=cut

__PACKAGE__->has_many(
  "forum_posts",
  "ShinyCMS::Schema::Result::ForumPost",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItem>

=cut

__PACKAGE__->has_many(
  "shop_items",
  "ShinyCMS::Schema::Result::ShopItem",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: has_many

Related object: L<ShinyCMS::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "ShinyCMS::Schema::Result::User",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-08 18:42:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RI8Obj+D/TgCvADEr8N3DQ


__PACKAGE__->has_many(
	"comments",
	"ShinyCMS::Schema::Result::Comment",
	{ "foreign.discussion" => "self.id" },
	{ cascade_copy => 0, cascade_delete => 0 },
);


=head2 get_thread

Get a discussion thread.  Recurses for nested threads.

=cut

sub get_thread {
	my ( $self, $parent ) = @_;

	# Get the top-level comments from the db
	my @comments = $self->comments->search({
		discussion => $self->id,
		parent => $parent,
	});

	# Build up the thread
	foreach my $comment ( @comments ) {
		$comment->{ children } = $self->get_thread( $comment->id );
	}

	return \@comments;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

