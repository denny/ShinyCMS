package ShinyCMS::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 200,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 200,
  },
  "display_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "display_email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 200,
  },
  "firstname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "surname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "active",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);
__PACKAGE__->has_many(
  "blogs",
  "ShinyCMS::Schema::Result::Blog",
  { "foreign.author" => "self.id" },
);
__PACKAGE__->has_many(
  "news_items",
  "ShinyCMS::Schema::Result::NewsItem",
  { "foreign.author" => "self.id" },
);
__PACKAGE__->has_many(
  "user_roles",
  "ShinyCMS::Schema::Result::UserRole",
  { "foreign.user" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_10 @ 2010-02-27 18:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WSY2mkmgW4GIs9yxiMJ3WQ


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
1;

