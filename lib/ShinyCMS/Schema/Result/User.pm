package ShinyCMS::Schema::Result::User;

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

ShinyCMS::Schema::Result::User

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

=head2 active

  data_type: 'integer'
  default_value: 1
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
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-04-12 14:50:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VRxY9AzZwdcKu2NmxzXbnw


__PACKAGE__->many_to_many( roles => 'user_roles', 'role' );


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
	my @roles = $self->roles;
	foreach my $role ( @roles ) {
		return 1 if $role->role eq $wanted;
	}
	return 0;
}


=head2 recent_blog_posts

Get recent blog posts by this user that aren't future-dated

=cut

sub recent_blog_posts {
	my( $self, $count ) = @_;
	
	$count ||= 10;
	
	my $now = DateTime->now;
	
	return $self->blog_posts->search(
		{
			posted   => { '<=' => $now },
		},
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

