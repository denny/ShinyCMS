package ShinyCMS::Controller::User;

use Moose;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


use Email::Valid;
use Digest::MD5;
use URI::Encode;


=head1 NAME

ShinyCMS::Controller::User

=head1 DESCRIPTION

Controller for ShinyCMS's user-facing user features, including registration,
authentication, and session management.

=cut


has allow_registration => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has allow_registration_forwarding => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
);

has comments_default => (
	isa     => Str,
	is      => 'ro',
	default => 'No',
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

has login_ip_limit => (
	isa     => Int,
	is      => 'ro',
	default => 0,		# Unlimited login IPs - no notifications
);

has login_ip_since => (
	isa     => Int,
	is      => 'ro',
	default => 7,
);

has login_redirect => (
	isa     => Str,
	is      => 'ro',
	default => 'User Profile',
);

has login_redirect_path => (
	isa     => Str,
	is      => 'ro',
	default => '',
);

has map_search_url => (
	isa     => Str,
	is      => 'ro',
	default => 'http://maps.google.co.uk/?q=',
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

sub base : Chained( '/base' ) : PathPart( 'user' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ controller } = 'User';
}


=head2 index

Forward to user profile or site homepage.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
	}
	else {
		$c->response->redirect( $c->uri_for( '/' ) );
	}
}


# ========== ( View / Edit Profile ) ==========

=head2 view_user

View user details.

=cut

sub view_user : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $username ) = @_;

	# Get the user details from the db
	my $user = $c->model( 'DB::User' )->find({
		username => $username,
	});

	# Put the user in the stash
	$c->stash->{ user } = $user;

	# And the map URL
	$c->stash->{ map_search_url } = $self->map_search_url;
}


=head2 edit_user

Edit user details.

=cut

sub edit_user : Chained( 'base' ) : PathPart( 'edit' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# If we don't have a logged-in user, give them the login page
	unless ( $c->user_exists ) {
		$c->stash->{ error_msg } = 'You must be logged in to edit your details.';
		$c->go( 'login' );
	}

	# Stash user details
	$c->stash->{ user } = $c->model( 'DB::User' )->find({
		id => $c->user->id,
	});

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
	my $email = $c->request->param( 'email' );

	# Check it for validity
	my $email_valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => $self->email_mxcheck,
		-tldcheck => $self->email_tldcheck,
	);
	unless ( $email_valid ) {
		$c->stash->{ error_msg } = 'You must set a valid email address.';
		$c->go( 'edit_user' );
	}

	# Upload new profile pic, if one has been selected
	my $pic_filename = $user->profile_pic;
	if ( $c->request->param( 'profile_pic' ) ) {
		my $limit  = $self->profile_pic_file_size;
		my $upload = $c->request->upload( 'profile_pic' );
		# Check filesize against limit set in config file
		if ( $upload->size > $limit ) {
			my $unit = 'KB';
			my $size = $limit / 1024;
			my $mb   = $size  / 1024;
			$unit    = 'MB' if $mb >= 1;
			$size    = $mb  if $mb >= 1;
			$c->flash->{ error_msg } = "Profile pic must be less than $size $unit";
			$c->response->redirect( $c->uri_for( 'edit' ) );
			$c->detach;
		}
		my $username = $user->username;
		my $path = $c->path_to( 'root/static/cms-uploads/user-profile-pics' );
		mkdir "$path/$username" unless -d "$path/$username";
		# Remove previous files
		system( "rm -f $path/$username/*.*" ) if $path and $username;
		# Save new file
		$upload->filename =~ m{\.(\w\w\w\w?)$};
		my $pic_ext = lc $1;
		$pic_filename = "$username.$pic_ext";
		my $save_as = "$path/$username/$pic_filename";
		my $wrote_file = $upload->copy_to( $save_as );
		$c->log->warn(
			"Failed to write file '$save_as' when updating user profile pic ($!)"
		) unless $wrote_file;
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
		profile_pic   => $pic_filename,
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
	my $allowed = 0;
	my $user = $c->model( 'DB::User' )->find({ id => $c->user->id });
	$allowed = 1 if $user->check_password( $password ) or $user->forgot_password;

	# Get the new password from the form
	my $password_one = $c->request->param( 'password_one' );
	my $password_two = $c->request->param( 'password_two' );

	# Verify they're both the same
	my $matching = $password_one eq $password_two ? 1 : 0;
	if ( $allowed and $matching ) {
		# Update user info
		$user->update({
			forgot_password => 0,
			password        => $password_one,
		});

		# TODO: Delete all sessions for this user except this one
		# (to log out any attackers the password change is intended to block)

		# Shove a confirmation message into the flash and bounce back to edit page
		$c->flash->{ status_msg } = 'Password changed.';
		$c->response->redirect( $c->uri_for( '/user/edit' ) );
	}
	else {
		$c->flash->{ error_msg }  = 'Incorrect current password. ' unless $allowed;
		$c->flash->{ error_msg } .= 'Passwords did not match.'     unless $matching;
		$c->response->redirect( $c->uri_for( '/user/change-password' ) );
	}
}


=head2 forgot_details

Display password retrieval form

=cut

sub forgot_details : Chained( 'base' ) : PathPart( 'forgot-details' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
}


=head2 send_details

Process password retrieval form, despatch email

=cut

sub send_details : Chained( 'base' ) : PathPart( 'details-sent' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check if they passed the reCaptcha test
	my $result;
	if ( $c->request->param( 'g-recaptcha-response' ) ) {
		$result = $self->recaptcha_result( $c );
	}
	else {
		$c->flash->{ error_msg } = 'You must fill in the reCaptcha.';
		$c->response->redirect( $c->uri_for( 'forgot-details' ) );
		$c->detach;
	}
	unless ( $result->{ is_valid } ) {
		$c->flash->{ error_msg } =
			'You did not pass the recaptcha test - please try again.';
		$c->response->redirect( $c->uri_for( 'forgot-details' ) );
		$c->detach;
	}

	# Find the user
	my $user;
	if ( $c->request->param( 'email' ) ) {
		# Check the email address for validity
		my $email_valid = Email::Valid->address(
			-address  => $c->request->param( 'email' ),
			-mxcheck  => $self->email_mxcheck,
			-tldcheck => $self->email_tldcheck,
		);
		unless ( $email_valid ) {
			$c->flash->{ error_msg } = 'That is not a valid email address.';
			$c->response->redirect( $c->uri_for( 'forgot-details' ) );
			$c->detach;
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
		from    => $site_name .' <'. $c->config->{ site_email } .'>',
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

		# Set the user to be active, in case they weren't already
		$user->update({ active => 1 });

		# Set the 'forgot password' flag, to allow resetting password without
		# knowing old password
		$user->update({ forgot_password => 1 });

		# Log the IP address
		$c->user->user_logins->create({
			ip_address => $c->request->address,
		});

		# Redirect to change password page
		$c->response->redirect( $c->uri_for( '/user/change-password' ) );
	}
	else {
		# Display an error message
		$c->flash->{ error_msg } = 'Reconnect link not valid.';
		$c->response->redirect( $c->uri_for( '/' ) );
	}
}



# ========== ( Registration ) ==========

=head2 register

Display user registration form.

=cut

sub register : Chained( 'base' ) : PathPart( 'register' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# If we already have a logged-in user, bounce them to their profile
	if ( $c->user_exists ) {
		$c->response->redirect( $c->uri_for( '/user', $c->user->username ) );
	}

	# Check if user registration is allowed
	unless ( uc $self->allow_registration eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( $c->uri_for( '/' ) );
	}
}


=head2 registered

Process user registration form.

=cut

sub registered : Chained( 'base' ) : PathPart( 'registered' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Check if user registration is allowed
	unless ( uc $self->allow_registration eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( $c->uri_for( '/' ) );
		$c->detach;
	}

	# Stash all the user inputs in case we have to reload the form
	my $username = $c->flash->{ username  } = $c->request->param( 'username'  );
	my $email    = $c->flash->{ email     } = $c->request->param( 'email'     );
	my $password = $c->flash->{ password  } = $c->request->param( 'password'  );
	               $c->flash->{ password2 } = $c->request->param( 'password2' );

	# Check the username is valid
	if ( $username =~ m/\W/ ) {
		$c->flash->{ error_msg } = 'Usernames may only contain letters, numbers and underscores.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
	}

	# Check the username is available
	my $user_exists = $c->model( 'DB::User' )->find({
		username => $username,
	});
	if ( $user_exists ) {
		$c->flash->{ error_msg } = 'Sorry, that username is already taken.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
	}

	# Check the passwords match
	unless ( $c->request->param( 'password' ) eq $c->request->param( 'password2' ) ) {
		$c->flash->{ error_msg } = 'Passwords do not match.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
	}

	# Check if they passed the reCaptcha test
	my $result;
	if ( $c->request->param( 'g-recaptcha-response' ) ) {
		$result = $self->recaptcha_result( $c );
	}
	else {
		$c->flash->{ error_msg } = 'You must pass the recaptcha test to register.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
	}
	unless ( $result->{ is_valid } ) {
		$c->flash->{ error_msg } =
			'You did not pass the recaptcha test - please try again.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
	}

	# Check the email address for validity
	my $email_valid = Email::Valid->address(
		-address  => $email,
		-mxcheck  => $self->email_mxcheck,
		-tldcheck => $self->email_tldcheck,
	);
	unless ( $email_valid ) {
		$c->flash->{ error_msg } = 'You must set a valid email address.';
		$c->response->redirect( $c->uri_for( '/user/register' ) );
		$c->detach;
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
		from    => $site_name .' <'. $c->config->{ site_email } .'>',
		to      => $email,
		subject => 'Confirm registration on '. $site_name,
		body    => $body,
	};
	$c->forward( $c->view( 'Email' ) );

	# If form contains forwarding instructions, and config allows it,
	# forward to next stage (possibly external) instead of finishing here.
	if ( uc $self->allow_registration_forwarding eq 'YES'
			and $c->request->param( 'forward_url' ) ) {
		my $url = $c->request->param( 'forward_url' );
		my $params = $c->request->params;
		my $query_string = '';
		my $encoder = URI::Encode->new;
		foreach my $key ( keys %$params ) {
			next if $key eq 'forward_url';
			next unless $key =~ m/^forward_(\w+)$/;
			my $name  = $1;
			my $value = $params->{ $key };
			$query_string .= $name . '=' . $encoder->encode( $value ) . '&';
		}
		$url .= '?' . $query_string if $query_string;
		$c->response->redirect( $url );
	}
}


=head2 confirm

Process user registration confirmation.

=cut

sub confirm : Chained( 'base' ) : PathPart( 'confirm' ) : Args( 1 ) {
	my ( $self, $c, $code ) = @_;

	# Check if user registration is allowed
	unless ( uc $self->allow_registration eq 'YES' ) {
		$c->flash->{ error_msg } = 'User registration is disabled on this site.';
		$c->response->redirect( $c->uri_for( '/' ) );
		$c->detach;
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
		if ( uc $self->comments_default eq 'YES' ) {
			my $discussion = $c->model( 'DB::Discussion' )->create({
				resource_id   => $user->id,
				resource_type => 'User',
			});
			$user->update({ discussion => $discussion->id });
		}

		# Redirect to user profile page
		$c->response->redirect( $c->uri_for( '/user', $user->username ) );
		$c->detach;
	}
	else {
		# Display an error message
		$c->flash->{ error_msg } = 'Confirmation code not found.';
		$c->response->redirect( $c->uri_for( '/' ) );
		$c->detach;
	}
}


# ========== ( Login / Logout ) ==========

=head2 login

Login logic.

=cut

sub login : Chained( 'base' ) : PathPart( 'login' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# If we already have a logged-in user, bounce them to the post-login page
	$self->post_login_redirect( $c ) if $c->user_exists;

	# Get the username and password from form
	my $username = $c->request->param( 'username' ) || undef;
	my $password = $c->request->param( 'password' ) || undef;

	# If the username and password values were found in form
	if ( $username and $password ) {
		# Check the account is active
		my $check = $c->model( 'DB::User' )->find({ username => $username });
		unless ( $check ) {
			$c->stash->{ error_msg } = "Bad username or password.";
			$c->detach;
		}
		unless ( $check->active ) {
			$c->flash->{ error_msg } = 'Account unavailable.';
			$c->response->redirect( $c->uri_for( '/' ) );
			$c->detach;
		}
		# Attempt to log the user in
		if ( $c->authenticate({ username => $username, password => $password }) ) {
			# If successful, log the login details
			$c->user->user_logins->create({
				ip_address => $c->request->address,
			});

			# If we have a login IP limit configured, check login IP count
			$self->check_login_ip_count( $c ) if $self->login_ip_limit > 0;

			# Look for a basket on their old session and claim it
			my $basket = $c->model('DB::Basket')->search(
				{
					session => 'session:' . $c->sessionid,
					user    => undef,
				},
				{
					order_by => { -desc => 'created' },
					rows     => 1,
				}
			)->single;
			$basket->update({
				session => undef,
				user    => $c->user->id,
			}) if $basket and not $c->user->basket;

			# Then change their session ID to frustrate session hijackers
			# TODO: This breaks my logins - am I using it incorrectly?
			#$c->change_session_id;

			# Then bounce them to the configured/specified post-login page
			$self->post_login_redirect( $c );
		}
		else {
			# Set an error message
			$c->stash->{ error_msg } = 'Bad username or password.';
		}
	}
}


=head2 post_login_redirect

When a user logs in, redirect them to the homepage, or as specified in the
config file - or, if a redirect override param is set in the form, send them
there instead.

=cut

sub post_login_redirect {
	my ( $self, $c ) = @_;

	my $url = $c->uri_for( '/' );
	$url = $c->uri_for( '/user', $c->user->username )
		if $self->login_redirect eq 'User Profile';

	# If a login_redirect_path is configured, that overrides the above
	$url = $c->uri_for( $self->login_redirect_path )
		if  $self->login_redirect_path
		and $self->login_redirect_path !~ m{user/login};

	# If the login form data included a redirect param, that overrides all the above
	$url = $c->uri_for( $c->request->param( 'redirect' ) )
		if  $c->request->param( 'redirect' )
		and $c->request->param( 'redirect' ) !~ m{user/login};

	$c->response->redirect( $url );
	$c->detach;
}


=head2 check_login_ip_count

Check to see if this login has been used from too many IP addresses

=cut

sub check_login_ip_count {
	my ( $self, $c ) = @_;

	my $since_days = $self->login_ip_since;
	my $since_dt   = DateTime->now->subtract( days => $since_days );
	my $since_str  = $since_dt->ymd .' '. $since_dt->hms;

	my $ip_count = $c->user->user_logins->search(
		{
			created => { '>' => $since_str }
		},
		{
			select   => [ 'ip_address' ],
			distinct => 1
		}
	)->count;

	if ( $ip_count >= $self->login_ip_limit ) {
		# Notify site admin by email
		my $site_name  = $c->config->{ site_name  };
		my $site_email = $c->config->{ site_email };
		my $site_url   = $c->uri_for( '/' );
		my $username   = $c->user->username;
		my $id         = $c->user->id;
		my $logins_url = $c->uri_for( '/admin', 'user', 'user', $id, 'login-details' );
		my $access_url = $c->uri_for( '/admin', 'user', 'user', $id, 'file-access-logs'  );

		$site_name = chomp $site_name;
		$username  = chomp $username;

		my $body = <<EOT;
The user '$username' has logged in from $ip_count IP addresses in the last $since_days days.

Login IP details for $username: $logins_url
File access logs for $username: $access_url
EOT
		$c->stash->{ email_data } = {
			from    => $site_name .' <'. $site_email .'>',
			to      => $site_email,
			subject => "[$site_name] $username has logged in from $ip_count IP addresses",
			body    => $body,
		};
		$c->forward( $c->view( 'Email' ) );
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


# ========== ( utility methods ) ==========

=head2 generate_confirmation_code

Generate a confirmation code for account registration or recovery.

=cut

sub generate_confirmation_code {
	my ( $username, $ip_address, $timestamp ) = @_;

	my $random = rand(42);
	my $md5 = Digest::MD5->new;
	$md5->add( $username, $ip_address, $timestamp, $random );
	my $code = $md5->hexdigest;

	return $code;
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
