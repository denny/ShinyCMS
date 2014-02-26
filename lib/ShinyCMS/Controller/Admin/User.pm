package ShinyCMS::Controller::Admin::User;

use Moose;
use MooseX::Types::Moose qw/ Str Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::User

=head1 DESCRIPTION

Controller for ShinyCMS user administration functions.

=cut


has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has profile_pic_file_size => (
	isa     => Int,
	is      => 'ro',
	default => 1048576,		# 1 MiB
);


=head1 METHODS

=cut


=head2 base

Set up the path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/user' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Admin::User';
}


=head2 index

Bounce to list of users.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'list_users' );
}


# ========== ( Users ) ==========

=head2 list_users

List all users.

=cut

sub list_users : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'list all users', 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Stash the list of users
	my @users = $c->model( 'DB::User' )->search(
		{},
		{
			order_by => 'username',
		},
	);
	$c->stash->{ users } = \@users;
}


=head2 add_user

Add a new user.

=cut

sub add_user : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c, $uid ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'add users', 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Find default comment setting and pass through
	$c->stash->{ comments_default_on } = 'YES' 
		if uc $self->comments_default eq 'YES';
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;
	
	# Stash the access groups
	my @access = $c->model( 'DB::Access' )->all;
	$c->stash->{ access_groups } = \@access;
	
	# Set the template
	$c->stash->{ template } = 'admin/user/edit_user.tt';
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $user_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a user', 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Stash user details
	$c->stash->{ user } = $c->model( 'DB::User' )->find({
		id => $user_id,
	});
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;
	
	# Stash the access groups
	my @access = $c->model( 'DB::Access' )->all;
	$c->stash->{ access_groups } = \@access;
}


=head2 edit_do

Update db with new user details.

=cut

sub edit_do : Chained( 'base' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => 'edit a user', 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Get the user ID for the user being edited
	my $user_id = $c->request->param( 'user_id' );
	
	unless ( $user_id ) {
		# Adding new user - check to see if username is already in use
		my $username_already_used = $c->model( 'DB::User' )->find({
			username => $c->request->params->{ 'username' },
		});
		
		if ( $username_already_used ) {
			# Shove a warning message into the flash
			$c->flash->{ error_msg } = 'That username already exists.';
		
			# Bounce back to the 'add user' page
			$c->response->redirect( $c->uri_for( 'add' ) );
			return;
		}
	}
	
	my $user = $c->model( 'DB::User' )->find({ id => $user_id });
	
	# Process deletions
	if ( defined $c->request->params->{ delete } 
			&& $c->request->param( 'delete' ) eq 'Delete' ) {
		$user->comments->delete;
		$user->user_roles->delete;
		$user->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'User deleted';
		
		# Bounce to the default page
		$c->response->redirect( $c->uri_for( 'list' ) );
		return;
	}
	
	# Get the new email from the form
	my $email = $c->request->params->{ email };
	
	# Check it for validity
	my $email_valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => 1,			# Comment out this line if developing offline
		-tldcheck => 1,			# Comment out this line if developing offline
	);
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		$c->go( 'edit_user', $user_id ) if $user_id;
		$c->go( 'edit_user' );
	}
	
	# Upload new profile pic, if one has been selected
	my $profile_pic;
	$profile_pic = $user->profile_pic if $user;
	if ( $c->request->param( 'profile_pic' ) ) {
		my $file = $c->request->upload( 'profile_pic' );
		my $limit = $self->profile_pic_file_size;
		my $unit = 'KB';
		my $size = $limit / 1024;
		my $mb   = $size  / 1024;
		$unit    = 'MB' if $mb >= 1;
		$size    = $mb  if $mb >= 1;
		if ( $file->size > $limit ) {
			$c->flash->{ error_msg } = 'Profile pic must be less than '. $size .' '. $unit;
			$c->response->redirect( $c->uri_for( 'edit' ) );
			return;
		}
		$profile_pic = $file->filename;
		# Save file to appropriate location
		my $username;
		$username = $user->username if $user;
		$username = $c->request->param( 'username' ) unless $user;
		my $path = $c->path_to( 'root', 'static', $c->stash->{ upload_dir }, 'user-profile-pics', $username );
		mkdir $path unless -d $path;
		my $save_as = $path .'/'. $profile_pic;
		$file->copy_to( $save_as ) or die "Failed to write file '$save_as' because: $!,";
	}
	
	# Update or create user record
	if ( $user_id ) {
		# Remove confirmation code if manually activating user
		if ( $c->request->param( 'active' ) == 1 and not $user->active ) {
			$user->confirmations->delete;
		}
		# Update user info
		$user->update({
			firstname     => $c->request->param( 'firstname'     ) || undef,
			surname       => $c->request->param( 'surname'       ) || undef,
			display_name  => $c->request->param( 'display_name'  ) || undef,
			display_email => $c->request->param( 'display_email' ) || undef,
			website       => $c->request->param( 'website'       ) || undef,
			location      => $c->request->param( 'location'      ) || undef,
			postcode      => $c->request->param( 'postcode'      ) || undef,
			bio           => $c->request->param( 'bio'           ) || undef,
			profile_pic   => $profile_pic                          || undef,
			email         => $email,
			admin_notes   => $c->request->param( 'admin_notes'   ) || undef,
			active        => $c->request->param( 'active'        ) || 0,
		});
	}
	else {
		# Create new user
		$user = $c->model( 'DB::User' )->create({
			username      => $c->request->param( 'username'      ) || undef,
			password      => $c->request->param( 'password'      ) || undef,
			firstname     => $c->request->param( 'firstname'     ) || undef,
			surname       => $c->request->param( 'surname'       ) || undef,
			display_name  => $c->request->param( 'display_name'  ) || undef,
			display_email => $c->request->param( 'display_email' ) || undef,
			website       => $c->request->param( 'website'       ) || undef,
			location      => $c->request->param( 'location'      ) || undef,
			postcode      => $c->request->param( 'postcode'      ) || undef,
			bio           => $c->request->param( 'bio'           ) || undef,
			profile_pic   => $profile_pic                          || undef,
			email         => $email,
			admin_notes   => $c->request->param( 'admin_notes'   ) || undef,
			active        => $c->request->param( 'active'        ) || 0,
		});
	}
	
	# Create a related discussion thread, if requested
	if ( $c->request->param( 'allow_comments' ) and not $user->discussion ) {
		my $discussion = $c->model( 'DB::Discussion' )->create({
			resource_id   => $user->id,
			resource_type => 'User',
		});
		$user->update({ discussion => $discussion->id });
	}
	# Disconnect the related discussion thread, if requested
	# (leaves the comments orphaned, rather than deleting them)
	elsif ( $user->discussion and not $c->request->param( 'allow_comments' ) ) {
		$user->update({ discussion => undef });
	}
	
	# Wipe existing user roles
	$user->user_roles->delete;
	
	# Extract user roles from form
	foreach my $input ( keys %{ $c->request->params } ) {
		if ( $input =~ m/^role_(\d+)$/ ) {
			$user->user_roles->create({ role => $1 });
		}
	}
	
	# Wipe existing user access
	$user->user_accesses->delete;
	
	# Extract desired user access from form
	foreach my $input ( keys %{ $c->request->params } ) {
		if ( $input =~ m/^date_group_(\d+)$/ ) {
			my $group_id = $1;
			my $expires_date = $c->request->params->{ $input };
			if ( lc $expires_date eq 'never' ) {
				# Non-expiring access
				$user->user_accesses->create({
					access  => $group_id,
					expires => undef,
				});
			}
			elsif ( $expires_date ) {
				# We have an expiry date
				my $expires_time = $c->request->params->{ 'time_group_' . $group_id };
				my( $y, $mo, $d ) = split '-', $expires_date;
				my( $h, $mi, $s ) = split ':', $expires_time;
				my $bits = {
					year   => $y,
					month  => $mo,
					day    => $d,
				};
				$bits->{ hour   } = $h  if $h;
				$bits->{ minute } = $mi if $mi;
				$bits->{ second } = $s  if $s;
				my $expires = DateTime->new( $bits );
				$user->user_accesses->create({
					access  => $group_id,
					expires => $expires,
				});
			}
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $user->id ) );
}


=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'base' ) : PathPart( 'change-password' ) : Args( 1 ) {
	my ( $self, $c, $user_id ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => "change a user's password", 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		id => $user_id,
	});
	
	$c->stash->{ user } = $user;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'base' ) : PathPart( 'change-password-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $self->user_exists_and_can($c, {
		action   => "change a user's password", 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Fetch the user
	my $user = $c->model( 'DB::User' )->find({
		id => $c->request->param( 'user_id' ),
	});
	
	# Get the new password from the form
	my $password_one = $c->request->param( 'password_one' );
	my $password_two = $c->request->param( 'password_two' );
	
	# Verify they're both the same
	my $matching_passwords = 1 if $password_one eq $password_two;
	
	if ( $matching_passwords ) {
		# Update password in database
		$user->update({
			password        => $password_one,
			forgot_password => 0,
		});
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Password changed';
	}
	else {
		# Shove an error message into the flash
		$c->flash->{ error_msg } = 'Passwords did not match';
	}
	
	# Bounce back to the user list
	$c->response->redirect( $c->uri_for( 'list' ) );
}


# ========== ( Roles ) ==========

=head2 list_roles

List all the roles.

=cut

sub list_roles : Chained( 'base' ) : PathPart( 'role/list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view roles
	return 0 unless $self->user_exists_and_can($c, {
		action => 'view the list of roles', 
		role   => 'User Admin',
	});
	
	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;
}


=head2 add_role

Add a role.

=cut

sub add_role : Chained( 'base' ) : PathPart( 'role/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add roles
	return 0 unless $self->user_exists_and_can($c, {
		action => 'add a new role', 
		role   => 'User Admin',
	});
	
	$c->stash->{ template } = 'admin/user/edit_role.tt';
}


=head2 add_role_do

Process adding a new role.

=cut

sub add_role_do : Chained( 'base' ) : PathPart( 'role/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add roles
	return 0 unless $self->user_exists_and_can($c, {
		action => 'add a new role', 
		role   => 'User Admin',
	});
	
	# Create role
	my $role = $c->model( 'DB::Role' )->create({
		role => $c->request->param( 'role' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Role added';
	
	# Bounce back to the list of roles
	$c->response->redirect( $c->uri_for( 'role/list' ) );
}


=head2 get_role

Stash details of a role.

=cut

sub get_role : Chained( 'base' ) : PathPart( 'role' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $role_id ) = @_;
	
	$c->stash->{ role } = $c->model( 'DB::Role' )->find({ id => $role_id });
	
	unless ( $c->stash->{ role } ) {
		$c->flash->{ error_msg } = 
			'Specified role not found - please select from the options below';
		$c->go('list_roles');
	}
}


=head2 edit_role

Edit a role.

=cut

sub edit_role : Chained( 'get_role' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in and a user admin
	return 0 unless $self->user_exists_and_can($c, {
		action => 'edit a role', 
		role   => 'User Admin',
	});
}


=head2 edit_role_do

Process a role edit.

=cut

sub edit_role_do : Chained( 'get_role' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit roles
	return 0 unless $self->user_exists_and_can($c, {
		action => 'edit a role', 
		role   => 'User Admin',
	});
	
	# Process deletions
	if ( $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ role }->user_roles->delete;
		$c->stash->{ role }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Role deleted';
		
		# Bounce to the 'view all roles' page
		$c->response->redirect( $c->uri_for( 'role/list' ) );
		return;
	}
	
	# Update role
	$c->stash->{ role }->update({
		role => $c->request->param( 'role' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Role updated';
	
	# Bounce back to the list of roles
	$c->response->redirect( $c->uri_for( 'role/list' ) );
}


# ========== ( Access ) ==========

=head2 list_access

List all the access groups.

=cut

sub list_access : Chained( 'base' ) : PathPart( 'access/list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the right to view access groups
	return 0 unless $self->user_exists_and_can($c, {
		action => 'view the list of access groups', 
		role   => 'User Admin',
	});
	
	my @access = $c->model( 'DB::Access' )->all;
	$c->stash->{ access } = \@access;
}


=head2 add_access

Add an access group.

=cut

sub add_access : Chained( 'base' ) : PathPart( 'access/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add access groups
	return 0 unless $self->user_exists_and_can($c, {
		action => 'add a new access group', 
		role   => 'User Admin',
	});
	
	$c->stash->{ template } = 'admin/user/edit_access.tt';
}


=head2 add_access_do

Process adding a new access group.

=cut

sub add_access_do : Chained( 'base' ) : PathPart( 'access/add-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to add access groups
	return 0 unless $self->user_exists_and_can($c, {
		action => 'add a new access group', 
		role   => 'User Admin',
	});
	
	# Create access group
	my $access = $c->model( 'DB::Access' )->create({
		access => $c->request->param( 'access' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Access group added';
	
	# Bounce back to the list of access types
	$c->response->redirect( $c->uri_for( 'access/list' ) );
}


=head2 get_access

Stash details of an access type.

=cut

sub get_access : Chained( 'base' ) : PathPart( 'access' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $access_id ) = @_;
	
	$c->stash->{ access } = $c->model( 'DB::Access' )->find({ id => $access_id });
	
	unless ( $c->stash->{ access } ) {
		$c->flash->{ error_msg } = 
			'Specified access group not found - please select from the options below';
		$c->go('list_access');
	}
}


=head2 edit_access

Edit an access group.

=cut

sub edit_access : Chained( 'get_access' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Bounce if user isn't logged in and a user admin
	return 0 unless $self->user_exists_and_can($c, {
		action => 'edit an access group', 
		role   => 'User Admin',
	});
}


=head2 edit_access_do

Process an access group edit.

=cut

sub edit_access_do : Chained( 'get_access' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to see if user is allowed to edit access groups
	return 0 unless $self->user_exists_and_can($c, {
		action => 'edit an access group', 
		role   => 'User Admin',
	});
	
	# Process deletions
	if ( $c->request->param( 'delete' ) eq 'Delete' ) {
		$c->stash->{ access }->user_accesses->delete;
		$c->stash->{ access }->delete;
		
		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Access deleted';
		
		# Bounce to the 'view all access groups' page
		$c->response->redirect( $c->uri_for( 'access/list' ) );
		return;
	}
	
	# Update access
	$c->stash->{ access }->update({
		access => $c->request->param( 'access' ),
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Access updated';
	
	# Bounce back to the list of access groups
	$c->response->redirect( $c->uri_for( 'access/list' ) );
}


# ========== ( Login ) ==========

=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : PathPart( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# If we already have a logged-in user, bounce them to some sort of useful page
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
		$c->response->redirect( $c->uri_for( '/admin', 'user', 'list' ) )
			if $c->user->has_role( 'User Admin' );
		$c->response->redirect( $c->uri_for( '/events', 'list' ) )
			if $c->user->has_role( 'Events Admin' );
		$c->response->redirect( $c->uri_for( '/blog', 'list' ) )
			if $c->user->has_role( 'Blog Author' );
		$c->response->redirect( $c->uri_for( '/admin', 'pages', 'list' ) )
			if $c->user->has_role( 'CMS Page Editor' );
		return;
	}
	
	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;
	
	# If the username and password values were found in form
	if ( $username && $password ) {
		# Check the account is active
		my $check = $c->model( 'DB::User' )->find({ username => $username });
		unless ( $check ) {
			$c->stash->{ error_msg } = "Bad username or password.";
			return;
		}
		unless ( $check->active ) {
			$c->flash->{ error_msg } = 'Account unavailable.';
			$c->response->redirect( $c->uri_for( '/' ) );
			return;
		}
		# Attempt to log the user in
		if ( $c->authenticate({ username => $username, password => $password }) ) {
			# If successful, change their session ID to frustrate session hijackers
			# TODO: This breaks my logins - am I using it incorrectly?
			#$c->change_session_id;
			# Then, bounce them back to the referring page (or some useful page)
			if ( $c->request->param( 'redirect' ) 
					and $c->request->param( 'redirect' ) !~ m!admin/user/login! ) {
				$c->response->redirect( $c->request->param( 'redirect' ) );
			}
			else {
				$c->response->redirect( $c->uri_for( '/user', $username ) );
				$c->response->redirect( $c->uri_for( '/admin', 'user', 'list' ) )
					if $c->user->has_role( 'User Admin' );
				$c->response->redirect( $c->uri_for( '/events', 'list' ) )
					if $c->user->has_role( 'Events Admin' );
				$c->response->redirect( $c->uri_for( '/blog', 'list' ) )
					if $c->user->has_role( 'Blog Author' );
				$c->response->redirect( $c->uri_for( '/admin', 'pages', 'list' ) )
					if $c->user->has_role( 'CMS Page Editor' );
			}
			return;
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = "Bad username or password.";
		}
	}
}



=head1 AUTHOR

Denny de la Haye <2014@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2014 Shiny Ideas (www.shinyideas.co.uk).

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at 
your option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

