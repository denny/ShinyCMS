package ShinyCMS::Controller::Admin::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::User

=head1 DESCRIPTION

Controller for ShinyCMS admin user functions.

=head1 METHODS

=cut


=head2 base

Set up the path.

=cut

sub base : Chained( '/' ) : PathPart( 'admin/user' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'Admin::User';
}


=head2 list_users

List all users.

=cut

sub list_users : Chained( 'base' ) : PathPart( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check to make sure user has the required permissions
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
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
	return 0 unless $c->model( 'Authorisation' )->user_exists_and_can({
		action   => 'add users', 
		role     => 'User Admin',
		redirect => '/user'
	});
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->all;
	$c->stash->{ roles } = \@roles;
	
	# Stash a list of images present in the profile pics folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'user-profile-pics' );
	
	# Set the template
	$c->stash->{ template } = 'admin/user/edit_user.tt';
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $user_id ) = @_;
	
	# Stash user details
	$c->stash->{ user } = $c->model( 'DB::User' )->find({
		id => $user_id,
	});
	
	# Stash a list of images present in the profile pics folder
	$c->{ stash }->{ images } = $c->controller( 'Root' )->get_filenames( $c, 'user-profile-pics' );
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->search;
	$c->stash->{ roles } = \@roles;
}


=head2 edit_do

Update db with new user details.

=cut

sub edit_do : Chained( 'base' ) : PathPart( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the user ID for the user being edited
	my $user_id = $c->request->param( 'user_id' );
	
	# Process deletions
	if ( defined $c->request->params->{ delete } && $c->request->param( 'delete' ) eq 'Delete' ) {
		my $deluser = $c->model( 'DB::User' )->find({ id => $user_id });
		$deluser->comments->delete;
		$deluser->user_roles->delete;
		$deluser->delete;
		
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
		-mxcheck  => 1,
		-tldcheck => 1,
	);
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		$c->go( 'edit_user', $user_id ) if $user_id;
		$c->go( 'edit_user' );
	}
	
	# Get the rest of the new details
	my $username      = $c->request->param( 'username'      ) || undef;
	my $password      = $c->request->param( 'password'      ) || undef;
	my $firstname     = $c->request->param( 'firstname'     ) || undef;
	my $surname       = $c->request->param( 'surname'       ) || undef;
	my $display_name  = $c->request->param( 'display_name'  ) || undef;
	my $display_email = $c->request->param( 'display_email' ) || undef;
	my $website       = $c->request->param( 'website'       ) || undef;
	my $bio           = $c->request->param( 'bio'           ) || undef;
	my $location      = $c->request->param( 'location'      ) || undef;
	my $postcode      = $c->request->param( 'postcode'      ) || undef;
	my $profile_pic   = $c->request->param( 'profile_pic'   ) || undef;
	my $admin_notes   = $c->request->param( 'admin_notes'   ) || undef;
	
	my $user;
	if ( $user_id ) {
		# Update user info
		$user = $c->model( 'DB::User' )->find({
			id => $user_id,
		})->update({
			firstname     => $firstname,
			surname       => $surname,
			display_name  => $display_name,
			display_email => $display_email,
			website       => $website,
			location      => $location,
			postcode      => $postcode,
			bio           => $bio,
			profile_pic   => $profile_pic,
			email         => $email,
			admin_notes   => $admin_notes,
		});
	}
	else {
		# Create new user
		$user = $c->model( 'DB::User' )->create({
			username      => $username,
			password      => $password,
			firstname     => $firstname,
			surname       => $surname,
			display_name  => $display_name,
			display_email => $display_email,
			website       => $website,
			location      => $location,
			postcode      => $postcode,
			bio           => $bio,
			profile_pic   => $profile_pic,
			email         => $email,
			admin_notes   => $admin_notes,
		});
	}
	
	# Wipe existing user roles
	$user->user_roles->delete;
	
	# Extract user roles from form
	foreach my $input ( keys %{ $c->request->params } ) {
		if ( $input =~ m/^role_(\d+)$/ ) {
			$user->user_roles->create({ role => $1 });
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $user->id ) );
}


=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'base' ) : PathPart( 'change-password' ) : Args( 1 ) {
	my ( $self, $c, $user_id ) = @_;
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		id => $user_id,
	});
	
	$c->stash->{ user } = $user;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'base' ) : PathPart( 'change_password_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Check it against the db
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
			password => $password_one,
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


=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : PathPart( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# If we already have a logged-in user, bounce them to some sort of useful page
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
		$c->response->redirect( $c->uri_for( '/user', 'list' ) )
			if $c->user->has_role( 'User Admin' );
		$c->response->redirect( $c->uri_for( '/blog', 'list' ) )
			if $c->user->has_role( 'Blog Author' );
		$c->response->redirect( $c->uri_for( '/pages', 'list' ) )
			if $c->user->has_role( 'CMS Page Editor' );
		return;
	}
	
	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;
	
	# If the username and password values were found in form
	if ( $username && $password ) {
		# Attempt to log the user in
		if ( $c->authenticate( {
					username => $username,
					password => $password 
				} ) ) {
			# If successful, bounce them back to the referring page (or some useful page)
			if ( $c->request->param( 'redirect' ) 
					and $c->request->param( 'redirect' ) !~ m!admin/user/login! ) {
				$c->response->redirect( $c->request->param( 'redirect' ) );
			}
			else {
				$c->response->redirect( $c->uri_for( '/user', $username ) );
				$c->response->redirect( $c->uri_for( '/admin', 'user', 'list' ) )
					if $c->user->has_role( 'User Admin' );
				$c->response->redirect( $c->uri_for( '/blog', 'list' ) )
					if $c->user->has_role( 'Blog Author' );
				$c->response->redirect( $c->uri_for( '/pages', 'list' ) )
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

Denny de la Haye <2010@denny.me>

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

