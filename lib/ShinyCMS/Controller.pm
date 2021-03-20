package ShinyCMS::Controller;

use Moose;
use MooseX::Types::Moose qw/ Str /;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


use Captcha::reCAPTCHA;
use Net::Akismet;


has akismet_api_key => (
	isa     => Str,
	is      => 'ro',
	default => '',
);

our $valid_roles;


=head1 METHODS

=head2 recaptcha_result

Checks to see if a recaptcha submission is good.

=cut

sub recaptcha_result {
	my( $self, $c ) = @_;

	# Shortcut the reCaptcha check; used by test suite
	return { is_valid => 1 } if $ENV{ RECAPTCHA_OFF };

	my $rc = Captcha::reCAPTCHA->new;

	my $result = $rc->check_answer_v2(
		$c->config->{ 'recaptcha_private_key' },
		$c->request->param( 'g-recaptcha-response' ),
		$c->request->address,
	);
	return $result;
}


=head2 akismet_result

Asks Akismet whether a comment is (probably) spam or not

Returns true for spam, false for not-spam, and undef if Akismet doesn't respond
or responds with anything other than 'true' or 'false'.

=cut

sub akismet_result {
	my( $self, $c ) = @_;

	return 1 if $ENV{ AKISMET_OFF };

	my $akismet = $self->akismet_client ( $c );
	return unless $akismet;

	my $details = $self->comment_details( $c->request );
	$details = $self->add_author_details( $details, $c->request->params );
	$details = $self->add_user_details( $details, $c->user ) if $c->user_exists;

	my $response = $akismet->check( %$details );

	return $self->log_spam_comment(
		$c, $self->excerpt( $c->request->param( 'body' ) )
	) if $response eq 'true';

	return 0 if $response eq 'false';

	return $self->log_no_response( $c ) unless $response;

	$c->log->warn( "Akismet response was not 'true' or 'false' ($response)" );
	return;
}

=head2 akismet_client

Build and return a Net::Akismet client

=cut

sub akismet_client : Private {
	my ( $self, $c ) = @_;

	my $akismet = Net::Akismet->new(
		KEY => $self->akismet_api_key,
		URL => $c->config->{ domain },
	);
	$c->log->warn( 'Key verification failure!' ) unless $akismet;

	return $akismet;
}

=head2 comment_details

Set up the basic comment details that go into every Akismet check

=cut

sub comment_details :Private {
	my ( $self, $request ) = @_;

	my %details = (
	    USER_IP            => $request->address,
	    COMMENT_USER_AGENT => $request->user_agent,
	    COMMENT_CONTENT    => $request->param( 'body' ),
	    REFERRER           => $request->referer,
	);

	return \%details;
}

=head2 add_author_details

Add pseudonymous comment author details to Akismet data

=cut

sub add_author_details : Private {
	my ( $self, $details, $params ) = @_;

	return $details if $params->{ 'author_type' } eq 'Anonymous';

	$details->{ COMMENT_AUTHOR       } = $params->{ 'author_name'  };
	$details->{ COMMENT_AUTHOR_EMAIL } = $params->{ 'author_email' };

	return $details;
}

=head2 add_user_details

Add authenticated comment author details to Akismet data

=cut

sub add_user_details : Private {
	my ( $self, $details, $user ) = @_;

	$details->{ COMMENT_AUTHOR       } ||= $user->username;
	$details->{ COMMENT_AUTHOR_EMAIL } ||= $user->email;

	return $details;
}

=head2 log_no_response

Log a warning if Akismet did not respond at all (then return undef)

=cut

sub log_no_response : Private {
	my ( $self, $c ) = @_;

	$c->log->warn( 'No response from Akismet' );
	return;
}

=head2 log_spam_comment

Log details of comments marked as spam (then return 1)

=cut

sub log_spam_comment : Private {
	my ( $self, $c, $excerpt ) = @_;

	$c->log->debug( "Akismet marked a comment as spam ($excerpt)" );
	return 1;
}

=head2 excerpt

Returns the first 50 or so characters of the text you send it,
attempting to truncate neatly at a word boundary and add '...'

=cut

sub excerpt : Private {
	my( $self, $full_text ) = @_;

	my $excerpt = substr( $full_text, 0, 50 );
	$excerpt =~ s{\b.{1,10}$}{ ...} unless length( $excerpt ) < 50;

	return $excerpt;
}


=head2 make_url_slug

Create a URL slug (for blog post URLs, shop item codes, etc)

=cut

sub make_url_slug {
	my( $self, $url_slug ) = @_;

	$url_slug =~ s/\s+/-/g;      # Change spaces into hyphens
	$url_slug =~ s/[^-\w]//g;    # Remove anything that's not in: A-Z, a-z, 0-9, _ or -
	$url_slug =~ s/-+/-/g;       # Change multiple hyphens to single hyphens
	$url_slug =~ s/^-//;         # Remove hyphen at start, if any
	$url_slug =~ s/-$//;         # Remove hyphen at end, if any

	return lc $url_slug;
}


=head2 user_exists_and_can

Check if a user is logged-in and has permission to take the specified action

=cut

sub user_exists_and_can {
	my ( $self, $c, $args ) = @_;

	my $action = $args->{ action };
	die 'Attempted authorisation check without action.' unless $action;

	# Display login page if user isn't already logged in
	unless ( $c->user_exists ) {
		$c->stash( error_msg  => "You must be logged in to $action.");
		$c->go( '/admin/user/login' );
	}

	# Get role and check it is valid
	my $role = $args->{ role };
	die 'Attempted authorisation check without role.' unless $role;
	$self->_get_valid_roles( $c );
	die "Attempted authorisation check with invalid role ($role)."
		unless $valid_roles->{ $role };
	# Bounce if user doesn't have appropriate role
	unless ( $c->user->has_role( $role ) ) {
		$c->flash( error_msg => "You do not have the ability to $action.");
		my $url = $args->{ redirect } ? $args->{ redirect } : '/';
		$c->response->redirect( $c->uri_for( $url ) );
		return 0;
	}
	return 1;
}


=head2 _get_valid_roles

Get a list of valid role names

=cut

sub _get_valid_roles : Private {
	my $self = shift;
	my $c = shift;
	unless ( $valid_roles ) {
		my @roles    = $c->model('DB::Role')->all;
		$valid_roles = { map { $_->role => 1 } @roles };
	}
	return $valid_roles;
}


=head2 safe_param

Utility method to clean up code handling request params that might be missing.

=cut

sub safe_param : Private {
	my( $self, $c, $param_name, $default ) = @_;

	return $c->request->param( $param_name ) || $default;
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
