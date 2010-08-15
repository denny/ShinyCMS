package ShinyCMS::Controller::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::User

=head1 DESCRIPTION

Main controller for ShinyCMS's user features, including authentication and 
session management.

=head1 METHODS

=cut


=head2 index

Forward to login page.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	$c->go( 'login' );
}


=head2 base

=cut

sub base : Chained( '/' ) : PathPart( 'user' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->stash->{ controller } = 'User';
}


=head2 view

View user details.

=cut

sub view_user : Chained( 'base' ) : Path( '' ) : Args( 1 ) {
	my ( $self, $c, $username ) = @_;
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		username => $username,
	});
	
	# Put the user in the stash
	$c->stash->{ user } = $user;
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 list_users

List all users.

=cut

sub list_users : Chained( 'base' ) : Path( 'list' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the list of users
	my @users = $c->model( 'DB::User' )->search(
		{},
		{
			order_by => 'username',
		},
	);
	$c->stash->{ users } = \@users;
}


=head2 add

Add a new user.

=cut

sub add_user : Chained( 'base' ) : Path( 'add' ) : Args( 0 ) {
	my ( $self, $c, $uid ) = @_;
	
	die unless $c->user->has_role( 'User Admin' );	# TODO
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->search;
	$c->stash->{ roles } = \@roles;
	
	$c->stash->{ template } = 'user/edit_user.tt';
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'base' ) : Path( 'edit' ) : OptionalArgs( 1 ) {
	my ( $self, $c, $uid ) = @_;
	
	my $user_id = $c->user->id;
	# If user is an admin, check for a user_id being passed in
	if ( $c->user->has_role( 'User Admin' ) ) {
		$user_id = $uid if $uid;
	}
	
	# Stash user details
	$c->stash->{ user } = $c->model( 'DB::User' )->find({
		id => $user_id,
	});
	
	# Stash the list of roles
	my @roles = $c->model( 'DB::Role' )->search;
	$c->stash->{ roles } = \@roles;
}


=head2 edit_do

Update db with new user details.

=cut

sub edit_do : Chained( 'base' ) : Path( 'edit-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the new email from the form
	my $email = $c->request->params->{ email };
	
	# TODO: Check it for validity
	my $email_valid = $email;
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		$c->go('edit');
	}
	
	# Get the rest of the new details
	my $username      = $c->request->param('username'     ) || undef;
	my $password      = $c->request->param('password'     ) || undef;
	my $display_name  = $c->request->param('display_name' ) || undef;
	my $display_email = $c->request->param('display_email') || undef;
	my $firstname     = $c->request->param('firstname'    ) || undef;
	my $surname       = $c->request->param('surname'      ) || undef;
	
	my $user_id = $c->user->id;
	# If user is an admin, check for a user_id being passed in
	if ( $c->user->has_role('User Admin') ) {
		$user_id = $c->request->param('user_id');
	}
	
	my $user;
	if ( $user_id ) {
		# Update user info
		$user = $c->model('DB::User')->find({
			id => $user_id,
		})->update({
			display_name	=> $display_name,
			display_email	=> $display_email,
			firstname		=> $firstname,
			surname			=> $surname,
			email			=> $email,
		});
	}
	else {
		# Create new user
		$user = $c->model('DB::User')->create({
			username        => $username,
			password        => $password,
			display_name	=> $display_name,
			display_email	=> $display_email,
			firstname		=> $firstname,
			surname			=> $surname,
			email			=> $email,
		});
	}
	
	# Wipe existing user roles
	$user->user_roles->delete;
	
	# Extract user roles from form
	foreach my $input ( keys %{$c->request->params} ) {
		if ( $input =~ m/^role_(\d+)$/ ) {
			warn $1;
			$user->user_roles->create({ role => $1 });
		}
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit' ) );
	$c->response->redirect( $c->uri_for( 'edit', $user->id ) ) 
		if $user->id != $c->user->id;
}


=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'base' ) : Path( 'change_password' ) : OptionalArgs( 1 ) {
	my ( $self, $c, $uid ) = @_;
	
	my $user_id = $c->user->id;
	# If user is an admin, check for a user_id being passed in
	if ( $c->user->has_role('User Admin') ) {
		$user_id = $uid if $uid;
	}
	
	# Get the user details from the db
	my $user = $c->model('DB::User')->find({
		id => $user_id,
	});
	
	$c->stash->{ user } = $user;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'base' ) : Path( 'change_password_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the current password from the form
	my $password = $c->request->params->{ password };
	
	# Check it against the db
	my $user = $c->model('DB::User')->find({
		id => $c->user->id,
	});
	my $right_person = 1 if 
		( $password eq $user->password or $c->user->has_role('User Admin') );
	
	# Get the new password from the form
	my $password_one = $c->request->params->{ password_one };
	my $password_two = $c->request->params->{ password_two };
	
	# Verify they're both the same
	my $matching_passwords = 1 if $password_one eq $password_two;
	
	if ( $right_person and $matching_passwords ) {
		# Update user info
		$user->update({
			password => $password_one,
		});
		
		# Shove a confirmation message into the flash
		$c->flash->{status_msg} = 'Password changed';
	}
	else {
		$c->flash->{error_msg}  = 'Wrong password.  '        unless $right_person;
		$c->flash->{error_msg} .= 'Passwords did not match.' unless $matching_passwords;
	}
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for('edit') );
}


=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : Path( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# If we already have a logged-in user, bounce them to some sort of useful page
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
		$c->response->redirect( $c->uri_for( '/user', 'list' ) )
			if $c->user->has_role('User Admin');
		$c->response->redirect( $c->uri_for( '/pages', 'list' ) )
			if $c->user->has_role('CMS Page Editor');
		return;
	}
	
	# Get the username and password from form
	my $username = $c->request->params->{username} || "";
	my $password = $c->request->params->{password} || "";
	
	# If the username and password values were found in form
	if ( $username && $password ) {
		# Attempt to log the user in
		if ( $c->authenticate( {
					username => $username,
					password => $password 
				} ) ) {
			# If successful, bounce them back to the referring page (or some useful page)
			if ( $c->request->param('redirect') and $c->request->param('redirect') !~ m!user/login! ) {
				$c->response->redirect( $c->request->param('redirect') );
			}
			else {
				$c->response->redirect( $c->uri_for( '/user', $username ) );
				$c->response->redirect( $c->uri_for( '/user', 'list' ) )
					if $c->user->has_role('User Admin');
				$c->response->redirect( $c->uri_for( '/pages', 'list' ) )
					if $c->user->has_role('CMS Page Editor');
			}
			return;
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = "Bad username or password.";
		}
	}
}


=head2 logout

Logout logic.

=cut

sub logout : Chained( 'base' ) : Path( 'logout' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Clear the user's state
	$c->logout;
	
	# Send the user to the starting point
	$c->response->redirect( $c->uri_for('/') );
}



=head1 AUTHOR

Denny de la Haye <2010@denny.me>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU Affero General Public License as published by 
the Free Software Foundation, either version 3 of the License, or (at your 
option) any later version.

You should have received a copy of the GNU Affero General Public License 
along with this program (see docs/AGPL-3.0.txt).  If not, see 
http://www.gnu.org/licenses/

=cut

__PACKAGE__->meta->make_immutable;

1;

