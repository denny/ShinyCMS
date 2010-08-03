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
  size: 200

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 display_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 display_email

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

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
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "display_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "display_email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 blogs

Type: has_many

Related object: L<ShinyCMS::Schema::Result::Blog>

=cut

__PACKAGE__->has_many(
  "blogs",
  "ShinyCMS::Schema::Result::Blog",
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


# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-04 00:50:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:npRvX+uAZsb3aEcMT1CzEg


__PACKAGE__->many_to_many( roles => 'user_roles', 'role' );


# Have the 'password' column use a SHA-1 hash and 10-character salt
# with hex encoding; Generate the 'check_password" method
__PACKAGE__->add_columns(
	'password' => {
		data_type           => "VARCHAR",
		size                => 50,
		encode_column       => 1,
		encode_class        => 'Digest',
		encode_args         => { format => 'hex', salt_length => 10 },
		encode_check_method => 'check_password',
	},
);


# Check to see if the user has a particular role set
sub has_role {
	my( $self, $wanted ) = @_;
	my @roles = $self->roles;
	foreach my $role ( @roles ) {
		return 1 if $role->role eq $wanted;
	}
	return 0;
}


# EOF
__PACKAGE__->meta->make_immutable;
1;

