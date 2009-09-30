package ShinyCMS::Controller::User;

use strict;
use warnings;

use parent 'Catalyst::Controller';

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

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	
	$c->go('login');
}


=head2 view

View user details.

=cut

sub view : Path('view') : Args(1) {
	my ( $self, $c, $username ) = @_;
	
	# Get the user details from the db
	my $user = $c->model('DB::User')->find({
		username => $username,
	});
	
	# TODO: graceful error
	die 'User not found' unless $user;
	
	# Put the user in the stash
	$c->stash->{ user } = $user;
}


=head2 edit

Edit user details.

=cut

sub edit : Path('edit') : OptionalArgs(1) {
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


=head2 edit_do

Update db with new user details.

=cut

sub edit_do : Path('edit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Get the new email from the form
	my $email = $c->request->params->{ email };
	
	# TODO: Check it for validity
	my $email_valid = $email;
	unless ( $email_valid ) {
		$c->stash->{ error_msg } = 'You must set a valid email address.';
		$c->go('edit');
	}
	
	# Get the rest of the new details
	my $display_name  = $c->request->params->{display_name}  || '';
	my $display_email = $c->request->params->{display_email} || '';
	my $firstname     = $c->request->params->{firstname}     || '';
	my $surname       = $c->request->params->{surname }      || '';
	
	my $user_id = $c->user->id;
	# If user is an admin, check for a user_id being passed in
	if ( $c->user->has_role('User Admin') ) {
		$user_id = $c->request->params->{ user_id };
	}
	
	# Update user info
	my $user = $c->model('DB::User')->find({
		id => $user_id,
	})->update({
		display_name	=> $display_name,
		display_email	=> $display_email,
		firstname		=> $firstname,
		surname			=> $surname,
		email			=> $email,
	});
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for('/user/edit') );
}


=head2 change_password

Change user password.

=cut

sub change_password : Path('change_password') : Args(0) {
	my ( $self, $c ) = @_;
	
	my $user_id = $c->user->id;
	
	if ( $c->user->has_role('User Admin') ) {
		# TODO: check for a user_id in URL and change $user_id appropriately
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

sub change_password_do : Path('change_password_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Get the current password from the form
	my $password = $c->request->params->{ password };
	
	# Check it against the db
	my $user = $c->model('DB::User')->find({
		id => $c->user->id,
	});
	my $okay = 1 if 
		( $password eq $user->password or $c->user->has_role('User Admin') );
	
	# Get the new password from the form
	my $password_one = $c->request->params->{ password_one };
	my $password_two = $c->request->params->{ password_two };
	
	# Verify they're both the same
	my $match = 1 if $password_one eq $password_two;
	
	if ( $okay and $match ) {
		# Update user info
		$user->update({
			password => $password_one,
		});
	}
	else {
		$c->flash->{error_msg}  = 'Wrong password.  '        unless $okay;
		$c->flash->{error_msg} .= 'Passwords did not match.' unless $match;
	}
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Password changed';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for('edit') );
}


=head2 login

Login logic.

=cut

sub login : Path('login') : Args(0) {
	my ( $self, $c ) = @_;
	
	# If we have a logged-in user, bounce them to their profile
	# TODO: make this return people to whatever page they reached the login form from
	if ( $c->user_exists ) {
		$c->response->redirect( $c->main_uri_for('view') . $c->user->username )
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
			# If successful, then let them use the application
			$c->response->redirect(
				$c->uri_for(
					$c->controller('User')->action_for('view')
				) . "/$username"
			);
			return;
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = "Bad username or password.";
		}
	}
}


=head2 index

Logout logic.

=cut

sub logout : Path('logout') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Clear the user's state
	$c->logout;
	
	# Send the user to the starting point
	$c->response->redirect( $c->uri_for('/') );
}


=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

