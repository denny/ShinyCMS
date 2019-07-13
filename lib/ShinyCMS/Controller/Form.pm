package ShinyCMS::Controller::Form;

use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Form

=head1 DESCRIPTION

Controller for ShinyCMS's form-handling.

=cut


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


=head1 METHODS

=head2 base

Set up path and stash some useful stuff.

=cut

sub base : Chained( '/base' ) : PathPart( 'form' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the controller name
	$c->stash->{ controller } = 'Form';
}


=head2 index

Forward to the site homepage if no form handler is specified.

=cut

sub index : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	$c->response->redirect( $c->uri_for( '/' ) );
}


=head2 process

Process a form submission.

=cut

sub process : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $url_name ) = @_;

	# If we don't have a referer, build a fallback redirect URL
	my $goto = $c->request->referer ? $c->request->referer : $c->uri_for( '/' );

	# Get the form
	my $form = $c->model( 'DB::CmsForm' )->search({
		url_name => $url_name,
	})->single;
	unless ( $form ) {
		$c->flash->{ error_msg } = "Could not find form handler for $url_name";
		$c->response->redirect( $goto );
		$c->detach;
	}
	$c->stash->{ form } = $form;

	# Check for reCaptcha
	if ( $form->has_captcha ) {
		my $result;
		if ( $c->request->param( 'g-recaptcha-response' ) ) {
			$result = $self->recaptcha_result( $c );
			unless ( $result->{ is_valid } ) {
				$c->flash->{ error_msg } =
					'You did not pass the recaptcha test - please try again.';
			}
		}
		else {
			$c->flash->{ error_msg } = 'You must fill in the reCaptcha.';
		}
	}

	# Dispatch to the appropriate form-handling method
	unless ( $c->flash->{ error_msg } ) {
		if ( $form->action eq 'Email' ) {
			if ( $form->template ) {
				$c->forward( 'send_email_with_template' );
			}
			else {
				$c->forward( 'send_email_without_template' );
			}
		}
	}

	# Redirect user to an appropriate page
	if ( $c->flash->{ error_msg } ) {
		# Validation failed - repopulate form params and attempt to go back there
		my $params = $c->request->params;
		foreach my $param ( keys %$params ) {
			$c->flash->{ $param } = $params->{ $param };
		}
	}
	elsif ( $form->redirect ) {
		# Validation succeeded; set specified post-form redirect
		$goto = $c->uri_for( $form->redirect );
	}
	# Redirect to form handler redirect setting if one is set and validation
	# passsed, otherwise to referer if available, or fall back to homepage.
	$c->response->redirect( $goto );
	$c->detach;
}


# ========== ( utility methods ) ==========

=head2 send_email_with_template

Process a form submission that sends an email using a template.

=cut

sub send_email_with_template : Private {
	my ( $self, $c ) = @_;

	# Build the email
	my $sender;
	if ( $c->request->param( 'email_from' ) ) {
		if ( $c->request->param( 'email_from_name' ) ) {
			$sender = '"'. $c->request->param( 'email_from_name' ) .'" '.
						'<'. $c->request->param( 'email_from' ) .'>';
		}
		else {
			$sender = $c->request->param( 'email_from' );
		}
	}
	$sender = $sender ? $sender : $c->config->{ site_email };
	my $sender_valid = Email::Valid->address(
		-address  => $sender,
		-mxcheck  => $self->email_mxcheck,
		-tldcheck => $self->email_tldcheck,
	);
	unless ( $sender_valid ) {
		$c->flash->{ error_msg } = 'Invalid email address.';
		return;
	}
	my $recipient = $c->stash->{ form }->email_to ?
		$c->stash->{ form }->email_to :
		$c->config->{ site_email };
	my $subject = $c->request->param( 'email_subject' ) ?
		$c->request->param( 'email_subject' ) :
		'Email from '. $c->config->{ site_name };

	my $email_data = {
		from     => $sender,
		to       => $recipient,
		subject  => $subject,
		template => $c->stash->{ form }->template,
	};
	$c->stash->{ email_data } = $email_data;

	# Send the email
	$c->forward( $c->view( 'Email::Template' ) );
}


=head2 send_email_without_template

Process a form submission that sends an email without using a template.

=cut

sub send_email_without_template : Private {
	my ( $self, $c ) = @_;

	# Build the email
	my $sender;
	if ( $c->request->param( 'email_from' ) ) {
		if ( $c->request->param( 'email_from_name' ) ) {
			$sender = '"'. $c->request->param( 'email_from_name' ) .'" '.
						'<'. $c->request->param( 'email_from' ) .'>';
		}
		else {
			$sender = $c->request->param( 'email_from' );
		}
	}
	$sender = $sender ? $sender : $c->config->{ site_email };
	my $recipient = $c->stash->{ form }->email_to ?
		$c->stash->{ form }->email_to :
		$c->config->{ site_email };
	my $subject = $c->request->param( 'email_subject' ) ?
		$c->request->param( 'email_subject' ) :
		'Email from '. $c->config->{ site_name };

	my $body = "Form data from your website:\n\n";

	# Loop through the submitted params, building the message body
	foreach my $key ( sort keys %{ $c->request->params } ) {
		next if $key eq 'email_from';
		next if $key eq 'email_from_name';
		next if $key eq 'email_subject';
		next if $key eq 'x'; # created by image buttons
		next if $key eq 'y'; # created by image buttons
		next if $key =~ m/^recaptcha_\w+_field$/;
		$body .= $key .":\n". $c->request->param( $key ) ."\n\n";
	}

	my $email_data = {
		from    => $sender,
		to      => $recipient,
		subject => $subject,
		body    => $body,
	};
	$c->stash->{ email_data } = $email_data;

	# Send the email
	$c->forward( $c->view( 'Email' ) );
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
