use utf8;
package ShinyCMS::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ShinyCMS::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 74

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 display_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 display_email

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 website

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 profile_pic

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 bio

  data_type: 'text'
  is_nullable: 1

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 admin_notes

  data_type: 'text'
  is_nullable: 1

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 forgot_password

  data_type: 'tinyint'
  default_value: 0
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
  "username",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 74 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "display_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "display_email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "website",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "profile_pic",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "bio",
  { data_type => "text", is_nullable => 1 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "admin_notes",
  { data_type => "text", is_nullable => 1 },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "forgot_password",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
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

=head2 C<user_username>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("user_username", ["username"]);

=head1 RELATIONS

=head2 baskets

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Basket>

=cut

__PACKAGE__->has_many(
  "baskets",
  "ShinyCMS::Schema::Result::Basket",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blog_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "ShinyCMS::Schema::Result::BlogPost",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 comments

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "ShinyCMS::Schema::Result::Comment",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 comments_like

Type: has_many

Related object: L<ShinyCMS::Schema::Result::CommentLike>

=cut

__PACKAGE__->has_many(
  "comments_like",
  "ShinyCMS::Schema::Result::CommentLike",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 confirmations

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Confirmation>

=cut

__PACKAGE__->has_many(
  "confirmations",
  "ShinyCMS::Schema::Result::Confirmation",
  { "foreign.user" => "self.id" },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 file_accesses

Type: has_many

Related object: L<ShinyCMS::Schema::Result::FileAccess>

=cut

__PACKAGE__->has_many(
  "file_accesses",
  "ShinyCMS::Schema::Result::FileAccess",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 forum_posts

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ForumPost>

=cut

__PACKAGE__->has_many(
  "forum_posts",
  "ShinyCMS::Schema::Result::ForumPost",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 news_items

Type: has_many

Related object: L<ShinyCMS::Schema::Result::NewsItem>

=cut

__PACKAGE__->has_many(
  "news_items",
  "ShinyCMS::Schema::Result::NewsItem",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "ShinyCMS::Schema::Result::Order",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poll_user_votes

Type: has_many

Related object: L<ShinyCMS::Schema::Result::PollUserVote>

=cut

__PACKAGE__->has_many(
  "poll_user_votes",
  "ShinyCMS::Schema::Result::PollUserVote",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_favourites

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemFavourite>

=cut

__PACKAGE__->has_many(
  "shop_item_favourites",
  "ShinyCMS::Schema::Result::ShopItemFavourite",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_item_views

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemView>

=cut

__PACKAGE__->has_many(
  "shop_item_views",
  "ShinyCMS::Schema::Result::ShopItemView",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 shop_items_like

Type: has_many

Related object: L<ShinyCMS::Schema::Result::ShopItemLike>

=cut

__PACKAGE__->has_many(
  "shop_items_like",
  "ShinyCMS::Schema::Result::ShopItemLike",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 transaction_logs

Type: has_many

Related object: L<ShinyCMS::Schema::Result::TransactionLog>

=cut

__PACKAGE__->has_many(
  "transaction_logs",
  "ShinyCMS::Schema::Result::TransactionLog",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_accesses

Type: has_many

Related object: L<ShinyCMS::Schema::Result::UserAccess>

=cut

__PACKAGE__->has_many(
  "user_accesses",
  "ShinyCMS::Schema::Result::UserAccess",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_logins

Type: has_many

Related object: L<ShinyCMS::Schema::Result::UserLogin>

=cut

__PACKAGE__->has_many(
  "user_logins",
  "ShinyCMS::Schema::Result::UserLogin",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<ShinyCMS::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "ShinyCMS::Schema::Result::UserRole",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-04-11 01:21:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MeywEvn17OOsU6y4/+8yJg


__PACKAGE__->many_to_many( roles  => 'user_roles',    'role'   );
__PACKAGE__->many_to_many( access => 'user_accesses', 'access' );


# Have the 'password' column use a SHA-1 hash and 10-character salt
# with hex encoding; Generate the 'check_password" method
__PACKAGE__->add_columns(
	'password' => {
		data_type           => "VARCHAR",
		size                => 74,
		encode_column       => 1,
		encode_class        => 'Digest',
		encode_args         => { format => 'hex', salt_length => 10 },
		encode_check_method => 'check_password',
	},
);


=head2 has_role

Check to see if the user has a particular role set

=cut

sub has_role {
	my( $self, $wanted ) = @_;

	my $role = $self->roles->find({
		role => $wanted,
	});

	return 0 unless $role;
	return 1;
}


=head2 has_access

Check to see if the user has a particular access level

=cut

sub has_access {
	my( $self, $wanted ) = @_;

	# Check if the user has this type of access
    my $access = $self->access->search({ 'access.access' => $wanted })->first;

    return unless $access;  # No access

    # Fetch the user access details (for checking expiry)
    my $user_access = $access->user_accesses->first;

	return 1 if not defined $user_access->expires; # Non-expiring access
    my $now = DateTime->now;
	return 1 if $user_access->expires >= $now; # In-date access

	return; # Access Expired
}


=head2 access_expires

Return expiry date of the specified access level

Returns undef if the user does not have access.  Returns 'never' if they have
non-expiring access (user_access.expires = null).

=cut

sub access_expires {
	my( $self, $wanted ) = @_;

	# Check if the user has this type of access
    my $access = $self->access->search({ 'access.access' => $wanted })->first;

    return unless $access;  # No access

	# Fetch the user access details
	my $user_access = $access->user_accesses->first;

	# Return the expiry date
	return $user_access->expires if $user_access->expires;
	return 'never';		# expiry date is NULL == non-expiring user
}


=head2 recent_blog_posts

Get recent blog posts by this user that aren't future-dated

=cut

sub recent_blog_posts {
	my( $self, $count ) = @_;

	$count ||= 10;

	return $self->blog_posts->search(
		{
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			rows     => $count,
		}
	);
}


=head2 recent_forum_posts

Get recent forum posts by this user

=cut

sub recent_forum_posts {
	my( $self, $count ) = @_;

	$count ||= 10;

	return $self->forum_posts->search(
		{},
		{
			order_by => { -desc => 'posted' },
			rows     => $count,
		}
	);
}


=head2 recent_comments

Get recent comments by this user

=cut

sub recent_comments {
	my( $self, $count ) = @_;

	$count ||= 10;

	return $self->comments->search(
		{},
		{
			order_by => { -desc => 'posted' },
			rows     => $count,
		}
	);
}


=head2 blog_post_count

Return total number of blog posts by this user

=cut

sub blog_post_count {
	my( $self ) = @_;

	return $self->blog_posts->count;
}


=head2 forum_post_count

Return total number of forum posts by this user

=cut

sub forum_post_count {
	my( $self ) = @_;

	return $self->forum_posts->count;
}


=head2 comment_count

Return total number of comments by this user

=cut

sub comment_count {
	my( $self ) = @_;

	return $self->comments->count;
}


=head2 forum_post_and_comment_count

Return total number of forum posts and comments by this user

=cut

sub forum_post_and_comment_count {
	my( $self ) = @_;

	return $self->forum_posts->count + $self->comments->count;
}



# EOF
__PACKAGE__->meta->make_immutable;
1;
