package ShinyCMS::Controller::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


use Email::Valid;


=head1 NAME

ShinyCMS::Controller::User

=head1 DESCRIPTION

Controller for ShinyCMS's user features, including authentication and 
session management.

=head1 METHODS

=cut


=head2 base

Set up the path.

=cut

sub base : Chained( '/' ) : PathPart( 'user' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the controller name
	$c->stash->{ controller } = 'User';
}


=head2 index

Forward to profile or login page.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
    my ( $self, $c ) = @_;
	
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
	}
	else {
		$c->go( 'login' );
	}
}


=head2 view_user

View user details.

=cut

sub view_user : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $username ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		username => $username,
	});
	
	# Put the user in the stash
	$c->stash->{ user } = $user;
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'base' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash user details
	$c->stash->{ user } = $c->model( 'DB::User' )->find({
		id => $c->user->id,
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
	
	my $user = $c->model( 'DB::User' )->find({ id => $c->user->id });
	
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
		$c->go( 'edit_user' );
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
		profile_pic   => $c->request->param( 'profile_pic'   ) || undef,
		email         => $email,
		admin_notes   => $c->request->param( 'admin_notes'   ) || undef,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit' ) );
}


=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'base' ) : PathPart( 'change-password' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		id => $c->user->id,
	});
	
	$c->stash->{ user } = $user;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'base' ) : PathPart( 'change_password_do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Get the current password from the form
	my $password = $c->request->param( 'password' );
	
	# Check it against the db
	my $user = $c->model( 'DB::User' )->find({
		id => $c->user->id,
	});
	my $right_person = 1 if $user->check_password( $password );
	
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
	$c->response->redirect( $c->uri_for( 'edit' ) );
}


=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : PathPart( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# If we already have a logged-in user, bounce them to their profile
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
		return;
	}
	
	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;
	
	# If the username and password values were found in form
	if ( $username and $password ) {
		# Attempt to log the user in
		if ( $c->authenticate({ username => $username, password => $password }) ) {
			# If successful, bounce them back to the referring page or their profile
			if ( $c->request->param('redirect') and $c->request->param('redirect') !~ m{user/login} ) {
				$c->response->redirect( $c->request->param( 'redirect' ) );
			}
			else {
				$c->response->redirect( $c->uri_for( '/user', $username ) );
			}
			return;
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = 'Bad username or password.';
		}
	}
}


=head2 logout

Logout logic.

=cut

sub logout : Chained( 'base' ) : PathPart( 'logout' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Clear the user's session
	$c->logout;
	
	# Send the user to the site's homepage
	$c->response->redirect( $c->uri_for( '/' ) );
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

