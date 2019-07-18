package ShinyCMS::Controller::Admin::Users;

use Moose;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Users

=head1 DESCRIPTION

Controller for ShinyCMS user administration functions.

=cut


has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'Yes',
);

has email_mxcheck => (
	isa     => Int,
	is      => 'ro',
	default => 1,
);

has email_tldcheck => (
	isa     => Int,
	is      => 'ro',
	default => 1,
);

has page_size => (
	isa     => Int,
	is      => 'ro',
	default => 20,
);

has profile_pic_file_size => (
	isa     => Int,
	is      => 'ro',
	default => 1048576,		# 1 MiB
);


=head1 METHODS

=head2 base

Set up the path.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/users' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	unless ( $c->action->name eq 'login' ) {
		# Check to make sure user has the required permissions
		return 0 unless $self->user_exists_and_can( $c, {
			action   => 'administrate CMS users, roles, and access groups',
			role     => 'User Admin',
			redirect => '/admin'
		});
	}

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Users';
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
	
	# Stash the list of users
	my $users = $c->model( 'DB::User' )->search(
		{},
		{
			order_by => 'username',
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		},
	);
	$c->stash->{ users } = $users;
}


=head2 search_users

Search users.

=cut

sub search_users : Chained( 'base' ) : PathPart( 'search' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of users
	my $users = $c->model( 'DB::User' )->search(
		{
			-or => [
				username => { -like => '%'. $c->request->param( 'query' ) .'%' },
				email    => { -like => '%'. $c->request->param( 'query' ) .'%' }
			]
		},
		{
			order_by => 'username',
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		},
	);
	$c->stash->{ users } = $users;

	# Re-use the list-users template
	$c->stash->{ template } = 'admin/users/list_users.tt';
}


=head2 add_user

Add a new user.

=cut

sub add_user : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c, $uid ) = @_;

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
	$c->stash->{ template } = 'admin/users/edit_user.tt';
}


=head2 get_user

Get user details and stash them

=cut

sub get_user : Chained( 'base' ) : PathPart( 'user' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $user_id ) = @_;

	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		id => $user_id,
	});

	$c->stash->{ user } = $user;
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'get_user' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;

	# Stash the access groups
	my @access = $c->model( 'DB::Access' )->all;
	$c->stash->{ access_groups } = \@access;
}


=head2 save_user

Update db with new user details.

=cut

sub save_user : Chained( 'base' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

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
			$c->detach;
		}
	}

	my $user = $c->model( 'DB::User' )->find({ id => $user_id });

	# Process deletions, including deleting user-generated content and metadata
	if ( defined $c->request->param( 'delete' ) ) {
		# TODO: Divorce some types of user-generated content from their account,
		# but still keep them visible and attributed (change to pseudonymous)
		#$user->blog_posts->delete;
		#$user->comments->delete;
		#$user->forum_posts->delete;
		#$user->news_items->delete;
		# Don't delete financial data, for legal/audit reasons
		$user->orders->update({ user => undef });
		$user->transaction_logs->update({ user => undef });
		# Delete 'trivial' user-generated content
		$user->baskets->delete;
		$user->comments_like->delete;
		$user->poll_user_votes->delete;
		$user->shop_item_favourites->delete;
		$user->shop_items_like->delete;
		# Delete user-related metadata
		$user->confirmations->delete;
		$user->shop_item_views->delete;
		$user->file_accesses->delete;
		$user->user_accesses->delete;
		$user->user_logins->delete;
		$user->user_roles->delete;
		# Stash details of their profile discussion, AKA 'wall'
		my $wall = $user->discussion;
		# Delete the user
		$user->delete;
		# Delete the profile discussion and its comments
		if ( $wall ) {
			$wall->comments->delete;
			$wall->delete;
		}

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'User deleted';

		# Bounce to the default page
		$c->response->redirect( $c->uri_for( '/admin/users' ) );
		return;
	}

	# Get the new email from the form
	my $email = $c->request->params->{ email };

	# Check it for validity
	my $email_valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => $self->email_mxcheck,
		-tldcheck => $self->email_tldcheck,
	);
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		my $uri = $c->uri_for( '/admin/users/add' );
		$uri = $c->uri_for( '/admin/users/user', $user_id, 'edit' ) if $user_id;
		$c->response->redirect( $uri );
		$c->detach;
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
		my $path = $c->path_to( 'root', 'static', 'cms-uploads', 'user-profile-pics', $username );
		mkdir $path unless -d $path;
		my $save_as = $path .'/'. $profile_pic;
		$file->copy_to( $save_as ) or die "Failed to write file '$save_as' because: $!,";
	}

	# Update or create user record
	if ( $user_id ) {
		# Remove confirmation code if manually activating user
		if ( defined $c->request->param( 'active' ) and not $user->active ) {
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
			my $expires_date = $c->request->param( $input );
			if ( lc $expires_date eq 'never' ) {
				# Non-expiring access
				$user->user_accesses->create({
					access  => $group_id,
					expires => undef,
				});
			}
			elsif ( $expires_date ) {
				# We have an expiry date
				my $expires_time = $c->request->param( 'time_group_' . $group_id );
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
	$c->response->redirect( $c->uri_for( 'user', $user->id, 'edit' ) );
}


=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'get_user' ) : PathPart( 'change-password' ) : Args( 0 ) {
	my ( $self, $c, $user_id ) = @_;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'get_user' ) : PathPart( 'save-password' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Get the new password from the form
	my $password_one = $c->request->param( 'password_one' );
	my $password_two = $c->request->param( 'password_two' );

	# Verify they're both the same
	if ( $password_one eq $password_two ) {
		# Update password in database
		$c->stash->{ user }->update({
			password        => $password_one,
			forgot_password => 0,
		});

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Password changed';
		$c->response->redirect( $c->uri_for( '/admin/users' ) );
	}
	else {
		# Shove an error message into the flash
		$c->flash->{ error_msg } = 'Passwords did not match';
		my $uri = $c->uri_for( '/admin/users/user', $c->stash->{ user }->id, 'change-password' );
		$c->response->redirect( $uri );
	}
}


# ========== ( User Tracking ) ==========

=head2 login_details

View user tracking info: login times and IP addresses

=cut

sub login_details : Chained( 'get_user' ) : PathPart( 'login-details' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Get the tracking info from the db and stash it
	$c->stash->{ logins  } = $c->stash->{ user }->user_logins->search(
		{},
		{
			order_by => { -desc => 'created' },
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
}


=head2 file_access_logs

View user tracking info: restricted file access logs

=cut

sub file_access_logs : Chained( 'get_user' ) : PathPart( 'file-access-logs' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Get the tracking info from the db and stash it
	$c->stash->{ access_logs } = $c->stash->{ user }->file_accesses->search(
		{},
		{
			order_by => { -desc => 'created' },
			rows     => $self->page_size,
			page     => $c->request->param('page') || 1,
		}
	);
}


# ========== ( Roles ) ==========

=head2 list_roles

List all the roles.

=cut

sub list_roles : Chained( 'base' ) : PathPart( 'roles' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;
}


=head2 add_role

Add a role.

=cut

sub add_role : Chained( 'base' ) : PathPart( 'role/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ template } = 'admin/users/edit_role.tt';
}


=head2 save_new_role

Save details of a new role.

=cut

sub save_new_role : Chained( 'base' ) : PathPart( 'role/save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Create role
	my $role = $c->model( 'DB::Role' )->create({
		role => $c->request->param( 'role' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Role added';

	# Redirect to the edit page for the new role
	my $uri = $c->uri_for( '/admin/users/role', $role->id, 'edit' );
	$c->response->redirect( $uri );
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
}


=head2 save_role

Save changes to a role.

=cut

sub save_role : Chained( 'get_role' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->stash->{ role }->user_roles->delete;
		$c->stash->{ role }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Role deleted';

		# Bounce to the 'view all roles' page
		$c->response->redirect( $c->uri_for( '/admin/users/roles' ) );
		$c->detach;
	}

	# Update role
	$c->stash->{ role }->update({
		role => $c->request->param( 'role' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Role updated';

	# Bounce back to the list of roles
	$c->response->redirect( $c->uri_for( '/admin/users/roles' ) );
}


# ========== ( Access ) ==========

=head2 list_access_groups

List all the access groups.

=cut

sub list_access_groups : Chained( 'base' ) : PathPart( 'access-groups' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @access = $c->model( 'DB::Access' )->all;
	$c->stash->{ access } = \@access;
}


=head2 add_access_group

Add an access group.

=cut

sub add_access_group : Chained( 'base' ) : PathPart( 'access-group/add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->stash->{ template } = 'admin/users/edit_access_group.tt';
}


=head2 save_new_access_group

Save details of a new access group.

=cut

sub save_new_access_group : Chained( 'base' ) : PathPart( 'access-group/save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Create access group
	my $access = $c->model( 'DB::Access' )->create({
		access => $c->request->param( 'access' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Access group added';

	# Redirect to the edit page for the new access group
	my $uri = $c->uri_for( '/admin/users/access-group', $access->id, 'edit' );
	$c->response->redirect( $uri );
}


=head2 get_access

Stash details of an access type.

=cut

sub get_access : Chained( 'base' ) : PathPart( 'access-group' ) : CaptureArgs( 1 ) {
	my ( $self, $c, $access_id ) = @_;

	$c->stash->{ access } = $c->model( 'DB::Access' )->find({ id => $access_id });

	unless ( $c->stash->{ access } ) {
		$c->flash->{ error_msg } =
			'Specified access group not found - please select from the options below';
		$c->go( 'list_access_groups' );
	}
}


=head2 edit_access_group

Edit an access group.

=cut

sub edit_access_group : Chained( 'get_access' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 save_access_group

Save changes to an access group.

=cut

sub save_access_group : Chained( 'get_access' ) : PathPart( 'save' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Process deletions
	if ( defined $c->request->param( 'delete' ) ) {
		$c->stash->{ access }->user_accesses->delete;
		$c->stash->{ access }->delete;

		# Shove a confirmation message into the flash
		$c->flash->{ status_msg } = 'Access group deleted';

		# Bounce to the 'view all access groups' page
		my $uri = $c->uri_for( '/admin/users/access-groups' );
		$c->response->redirect( $uri );
		$c->detach;
	}

	# Update access group
	$c->stash->{ access }->update({
		access => $c->request->param( 'access' ),
	});

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Access group updated';

	# Reload edit page
	my $uri = $c->uri_for( '/admin/users/access-group', $c->stash->{ access }->id, 'edit' );
	$c->response->redirect( $uri );
}


# ========== ( Login ) ==========

=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : PathPart( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# If we already have a logged-in user, redirect them somewhere more useful
	$self->post_login_redirect( $c ) if $c->user_exists;

	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;

	# If the username and password values were found in form
	if ( $username && $password ) {
		# Check the account is active
		my $check = $c->model( 'DB::User' )->find({ username => $username });
		unless ( $check ) {
			$c->flash->{ error_msg } = "Bad username or password.";
			$c->detach;
		}
		unless ( $check->active ) {
			$c->flash->{ error_msg } = 'Account unavailable.';
			$c->response->redirect( $c->uri_for( '/' ) );
			$c->detach;
		}
		# Attempt to log the user in
		if ( $c->authenticate({ username => $username, password => $password }) ) {
			# If successful, change their session ID to frustrate session hijackers
			# TODO: This breaks my logins - am I using it incorrectly?
			#$c->change_session_id;
			# Then, bounce them back to the referring page (or some useful page)
			$self->post_login_redirect( $c );
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = "Bad username or password.";
		}
	}
}


=head2 post_login_redirect

When an admin logs in, redirect them to the 'most useful' admin area that
they have access to - or, if a redirect override param is set in the form,
send them there instead.

=cut

sub post_login_redirect {
	my ( $self, $c ) = @_;

	my $url;
	# Specified post-login redirect location overrides everything else
	if ( $c->request->param(    'redirect' ) and
			$c->request->param( 'redirect' ) !~ m{/user/login} ) {
		$url = $c->uri_for( $c->request->param( 'redirect' ) );
	}
	# Otherwise, redirect to the most 'useful' area that they have access to
	elsif ( $c->user->has_role( 'CMS Page Editor'    ) ) {
		$url = $c->uri_for(     '/admin/pages'       );
	}
	elsif ( $c->user->has_role( 'Blog Author'        ) ) {
		$url = $c->uri_for(     '/admin/blog'        );
	}
	elsif ( $c->user->has_role( 'News Admin'         ) ) {
		$url = $c->uri_for(     '/admin/news'        );
	}
	elsif ( $c->user->has_role( 'Newsletter Admin'   ) ) {
		$url = $c->uri_for(     '/admin/newsletters' );
	}
	elsif ( $c->user->has_role( 'Shop Admin'         ) ) {
		$url = $c->uri_for(     '/admin/shop'        );
	}
	elsif ( $c->user->has_role( 'Forums Admin'       ) ) {
		$url = $c->uri_for(     '/admin/forums'      );
	}
	elsif ( $c->user->has_role( 'Poll Admin'         ) ) {
		$url = $c->uri_for(     '/admin/polls'       );
	}
	elsif ( $c->user->has_role( 'Events Admin'       ) ) {
		$url = $c->uri_for(     '/admin/events'      );
	}
	elsif ( $c->user->has_role( 'FileServer Admin'   ) ) {
		$url = $c->uri_for(     '/admin/fileserver'  );
	}
	elsif ( $c->user->has_role( 'User Admin'         ) ) {
		$url = $c->uri_for(     '/admin/users'       )
	}
	elsif ( $c->user->has_role( 'Shared Content Editor' ) ) {
		$url = $c->uri_for(     '/admin/shared'         );
	}
	# If all else fails, pass them on to the non-admin post-login method
	else {
		$c->go( 'Users', 'login' );
	}

	$c->response->redirect( $url );
	$c->detach;
}



=head1 AUTHOR

Denny de la Haye <2019@denny.me>

=head1 COPYRIGHT

Copyright (c) 2009-2019 Denny de la Haye.

=head1 LICENSING

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://www.gnu.org/licenses/gpl-2.0.en.html
https://opensource.org/licenses/Artistic-2.0

=cut

__PACKAGE__->meta->make_immutable;

1;
