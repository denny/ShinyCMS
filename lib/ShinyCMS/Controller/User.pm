package ShinyCMS::Controller::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use Email::Valid;
use Digest::MD5;


=head1 NAME

ShinyCMS::Controller::User

=head1 DESCRIPTION

Controller for ShinyCMS's user-facing user features, including registration, 
authentication, and session management.

=head1 METHODS

=cut


=head2 base

Set up the path.

=cut

sub base : Chained( '/base' ) : PathPart( 'user' ) : CaptureArgs( 0 ) {
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


# ========== ( View / Edit Profile ) ==========

=head2 view_user

View user details.

=cut

sub view_user : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $username ) = @_;
	
	# Build the CMS section of the menu
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
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# If we don't have a logged-in user, give them the login page
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit your details.';
		$c->go( 'login' );
	}
	
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
	
	# If we don't have a logged-in user, give them the login page
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit your details.';
		$c->go( 'login' );
	}
	
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
	
	# Upload new profile pic, if one has been selected
	my $profile_pic = $user->profile_pic;
	if ( $c->request->param( 'profile_pic' ) ) {
		my $file = $c->request->upload( 'profile_pic' );
		my $limit = $c->config->{ User }->{ profile_pic_file_size };
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
		my $path = $c->path_to( 'root', 'static', $c->stash->{ upload_dir }, 'user-profile-pics', $user->username );
		mkdir $path unless -d $path;
		my $save_as = $path .'/'. $profile_pic;
		$file->copy_to( $save_as ) or die "Failed to write file '$save_as' because: $!,";
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
	});
	
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
	
	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit' ) );
}


# ========== ( Passwords ) ==========

=head2 change_password

Change user password.

=cut

sub change_password : Chained( 'base' ) : PathPart( 'change-password' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		id => $c->user->id,
	});
	
	$c->stash->{ user } = $user;
}


=head2 change_password_do

Update db with new password.

=cut

sub change_password_do : Chained( 'base' ) : PathPart( 'change-password-do' ) : Args( 0 ) {
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
		
		# TODO: Delete all sessions for this user except this one
		# (to log out any attackers the password change is intended to block)
		
		# Shove a confirmation message into the flash
		$c->flash->{status_msg} = 'Password changed.';
	}
	else {
		$c->flash->{error_msg}  = 'Wrong password.  '        unless $right_person;
		$c->flash->{error_msg} .= 'Passwords did not match.' unless $matching_passwords;
	}
	
	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit' ) );
}


=head2 forgot_details

Display password retrieval form

=cut

sub forgot_details : Chained( 'base' ) : PathPart( 'forgot-details' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
}


=head2 send_details

Process password retrieval form, despatch email

=cut

sub send_details : Chained( 'base' ) : PathPart( 'details-sent' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Check if they passed the reCaptcha test
	my $result;
	if ( $c->request->param( 'recaptcha_challenge_field' ) ) {
		my $rc = Captcha::reCAPTCHA->new;
		
		$result = $rc->check_answer(
			$c->stash->{ 'recaptcha_private_key' },
			$c->request->address,
			$c->request->param( 'recaptcha_challenge_field' ),
			$c->request->param( 'recaptcha_response_field'  ),
		);
	}
	else {
		$c->flash->{ error_msg } = 'You must fill in the reCaptcha.';
		$c->response->redirect( $c->uri_for( 'forgot-details' ) );
		return;
	}
	unless ( $result->{ is_valid } ) {
		$c->flash->{ error_msg } = 
			'You did not enter the two words correctly, please try again.';
		$c->response->redirect( $c->uri_for( 'forgot-details' ) );
		return;
	}
	
	# Find the user
	my $user;
	if ( $c->request->params->{ email } ) {
		# Check the email address for validity
		my $email_valid = Email::Valid->address(
			-address  => $c->request->params->{ email },
			-mxcheck  => 1,
			-tldcheck => 1,
		);
		unless ( $email_valid ) {
			$c->flash->{ error_msg } = 'That is not a valid email address.';
			$c->response->redirect( $c->uri_for( 'forgot-details' ) );
			return;
		}
		# Find user by email
		$user = $c->model( 'DB::User' )->search({
			email => $c->request->param( 'email' ),
		})->first;
		$c->stash->{ email_exists } = 'TRUE' if $user;
	}
	else {
		# Find user by username
		$user = $c->model( 'DB::User' )->find({
			username => $c->request->param( 'username' ),
		});
		$c->stash->{ username } = $c->request->param( 'username' );
		$c->stash->{ username_exists } = 'TRUE' if $user;
	}
	unless ( $user ) {
		$c->detach;
	}
	
	# Create an entry in the confirmation table
	my $now = DateTime->now;
	my $code = generate_confirmation_code(
		$user->username,
		$c->request->address,
		$now->datetime
	);
	$user->confirmations->create({
		code => $code,
	});
	
	# Send an email to the user
	my $site_name   = $c->config->{ site_name };
	my $site_url    = $c->uri_for( '/' );
	my $login_url = $c->uri_for( '/user', 'reconnect', $code );
	my $body = <<EOT;
You (or someone pretending to be you) just told us that you've forgotten 
your login details for $site_name. 

If it was you, please click here to log straight into the site:
$login_url

(Remember to set a new password once you're logged in!)

If it wasn't you, then just ignore this email.  The login link was only 
sent to you, and it expires in 1 hour.

-- 
$site_name
$site_url
EOT
	$c->stash->{ email_data } = {
		from    => $site_name .' <'. $c->config->{ email_from } .'>',
		to      => $user->email,
		subject => 'Log back in to '. $site_name,
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 reconnect

Log user straight in and redirect to 'change password' page.

=cut

sub reconnect : Chained( 'base' ) : PathPart( 'reconnect' ) : Args( 1 ) {
	my ( $self, $c, $code ) = @_;
	
	# Check the code
	my $confirm = $c->model( 'DB::Confirmation' )->find({ code => $code });
	if ( $confirm ) {
		# Log the user in
		# TODO: set_authenticated is marked as 'internal use only' - 
		# TODO: mst says to ask jayk if there's a better approach here
		my $user = $c->find_user({ username => $confirm->user->username });
		$c->set_authenticated( $user );
		
		# Delete the confirmation record
		$confirm->delete;
		
		# Redirect to change password page
		$c->response->redirect( $c->uri_for( '/user', 'change-password' ) );
		return;
	}
	else {
		# Display an error message
		$c->flash->{ error_msg } = 'Reconnect link not valid.';
		$c->response->redirect( $c->uri_for( '/' ) );
		return;
	}
}



# ========== ( Registration ) ==========

=head2 register

Display user registration form.

=cut

sub register : Chained( 'base' ) : PathPart( 'register' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Check if user registration is allowed
	unless ( uc $c->config->{ allow_user_registration } eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( '/' );
		return;
	}
}


=head2 registered

Process user registration form.

=cut

sub registered : Chained( 'base' ) : PathPart( 'registered' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Check if user registration is allowed
	unless ( uc $c->config->{ allow_user_registration } eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( '/' );
		return;
	}
	
	# Stash all the user inputs in case we have to reload the form
	my $username = $c->flash->{ username  } = $c->request->params->{ username  };
	my $email    = $c->flash->{ email     } = $c->request->params->{ email     };
	my $password = $c->flash->{ password  } = $c->request->params->{ password  };
	               $c->flash->{ password2 } = $c->request->params->{ password2 };
	
	# Check the username is available
	my $user_exists = $c->model( 'DB::User' )->find({
		username => $username,
	});
	if ( $user_exists ) {
		$c->flash->{ error_msg } = 'Sorry, that username is already taken.';
		$c->response->redirect( $c->uri_for( '/user', 'register' ) );
		return;
	}
	
	# Check the passwords match
	unless ( $c->request->params->{ password } eq $c->request->params->{ password2 } ) {
		$c->flash->{ error_msg } = 'Passwords do not match.';
		$c->response->redirect( $c->uri_for( '/user', 'register' ) );
		return;
	}
	
	# Check the email address for validity
	my $email_valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => 1,
		-tldcheck => 1,
	);
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		$c->response->redirect( $c->uri_for( '/user', 'register' ) );
		return;
	}
	
	# Check if they passed the reCaptcha test
	my $result;
	if ( $c->request->param( 'recaptcha_challenge_field' ) ) {
		my $rc = Captcha::reCAPTCHA->new;
		
		$result = $rc->check_answer(
			$c->stash->{ 'recaptcha_private_key' },
			$c->request->address,
			$c->request->param( 'recaptcha_challenge_field' ),
			$c->request->param( 'recaptcha_response_field'  ),
		);
	}
	else {
		$c->flash->{ error_msg } = 'You must enter the two words to register.';
		$c->response->redirect( $c->uri_for( '/user', 'register' ) );
		return;
	}
	unless ( $result->{ is_valid } ) {
		$c->flash->{ error_msg } = 
			'You did not enter the two words correctly, please try again.';
		$c->response->redirect( $c->uri_for( '/user', 'register' ) );
		return;
	}
	
	# Create the to-be-confirmed user
	my $user = $c->model( 'DB::User' )->create({
		username => $username,
		password => $password,
		email    => $email,
		active   => 0,
	});
	
	# Create an entry in the confirmation table
	my $now = DateTime->now;
	my $code = generate_confirmation_code( $username, $c->request->address, $now->datetime );
	$user->confirmations->create({
		code => $code,
	});
	
	# Send out the confirmation email
	my $site_name   = $c->config->{ site_name };
	my $site_url    = $c->uri_for( '/' );
	my $confirm_url = $c->uri_for( '/user', 'confirm', $code );
	my $body = <<EOT;
Somebody using this email address just registered on $site_name. 

If it was you, please click here to complete your registration:
$confirm_url

If you haven't recently registered on $site_name, please ignore this 
email - without confirmation, the account will remain locked, and will 
eventually be deleted.

-- 
$site_name
$site_url
EOT
	$c->stash->{ email_data } = {
		from    => $site_name .' <'. $c->config->{ email_from } .'>',
		to      => $email,
		subject => 'Confirm registration on '. $site_name,
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );
}


=head2 generate_confirmation_code

Generate a confirmation code.

=cut

sub generate_confirmation_code {
	my ( $username, $ip_address, $timestamp ) = @_;
	
	my $md5 = Digest::MD5->new;
	$md5->add( $username, $ip_address, $timestamp );
	my $code = $md5->hexdigest;
	
	return $code;
}


=head2 confirm

Process user registration confirmation.

=cut

sub confirm : Chained( 'base' ) : PathPart( 'confirm' ) : Args( 1 ) {
	my ( $self, $c, $code ) = @_;
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Check if user registration is allowed
	unless ( uc $c->config->{ allow_user_registration } eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( '/' );
		return;
	}
	
	# Check the code
	my $confirm = $c->model( 'DB::Confirmation' )->find({ code => $code });
	if ( $confirm ) {
		# Log the user in
		# TODO: set_authenticated is marked as 'internal use only' - 
		# TODO: mst says to ask jayk if there's a better approach here
		my $user = $c->find_user({ username => $confirm->user->username });
		$c->set_authenticated( $user );
		
		# Delete the confirmation record
		$confirm->delete;
		
		# Set the user to be active
		$user->update({ active => 1 });
		
		# If user profile comments are enabled by default, turn them on
		if ( uc $c->config->{ User }->{ comments_default } eq 'YES' ) {
			my $discussion = $c->model( 'DB::Discussion' )->create({
				resource_id   => $user->id,
				resource_type => 'User',
			});
			$user->update({ discussion => $discussion->id });
		}
		
		# Redirect to user profile page
		$c->response->redirect( $c->uri_for( '/user', $user->username ) );
		return;
	}
	else {
		# Display an error message
		$c->flash->{ error_msg } = 'Confirmation code not found.';
		$c->response->redirect( $c->uri_for( '/' ) );
		return;
	}
}


# ========== ( Utility functions ) ==========

=head2 user_count

Return total number of users.

=cut

sub user_count {
	my( $self, $c ) = @_;
	
	my $count = $c->model( 'DB::User' )->count;
	
	return $count;
}


# ========== ( Login / Logout ) ==========

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
	
	# Build the CMS section of the menu
	$c->forward( 'Root', 'build_menu' );
	
	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;
	
	# If the username and password values were found in form
	if ( $username and $password ) {
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
	
	# Set a status message
	$c->stash->{ status_msg } = 'You have been logged out.';
	
	# Send the user to the site's homepage
	$c->response->redirect( $c->uri_for( '/' ) );
}



=head1 AUTHOR

Denny de la Haye <2011@denny.me>

=head1 COPYRIGHT

ShinyCMS is copyright (c) 2009-2011 Shiny Ideas (www.shinyideas.co.uk).

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

