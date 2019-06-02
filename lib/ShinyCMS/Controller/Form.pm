package ShinyCMS::Controller::Form;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Form

=head1 DESCRIPTION

Controller for ShinyCMS's form-handling.

=cut


=head1 METHODS

=head2 base

Set up path and stash some useful stuff.

=cut

sub base : Chained( '/base' ) : PathPart( 'form' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };

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

	# Get the form
	my $form = $c->model( 'DB::CmsForm' )->find({
		url_name => $url_name,
	});
	$c->stash->{ form } = $form;

	# Check for reCaptcha
	if ( $form->has_captcha ) {
		my $result;
		if ( $c->request->param( 'g-recaptcha-response' ) ) {
			$result = $self->_recaptcha_result( $c );
		}
		else {
			$c->flash->{ error_msg } = 'You must fill in the reCaptcha.';
			$c->response->redirect( $c->request->referer );
			return;
		}
		unless ( $result->{ is_valid } ) {
			$c->flash->{ error_msg } =
				'You did not pass the recaptcha test - please try again.';
				$c->response->redirect( $c->request->referer );
			return;
		}
	}

	# Dispatch to the appropriate form-handling method
	if ( $form->action eq 'Email' ) {
		if ( $form->template ) {
			$c->forward( 'send_email_with_template' );
		}
		else {
			$c->forward( 'send_email_without_template' );
		}
	}
	else {
		warn "We don't have any other types of form-handling yet!";
	}

	# Redirect user to an appropriate page
	if ( $c->flash->{ error_msg } ) {
		# Validation failed - repopulate and reload form
		my $params = $c->request->params;
		foreach my $param ( keys %$params ) {
			$c->flash->{ $param } = $params->{ $param };
		}
		$c->response->redirect( $c->request->referer );
	}
	elsif ( $form->redirect ) {
		# Redirect to specified destination page, if one is set
		$c->response->redirect( $form->redirect );
	}
	elsif ( $c->request->referer ) {
		# Otherwise, bounce to referring page
		$c->response->redirect( $c->request->referer );
	}
	else {
		# User's browser is hiding referring page info - bounce them to /
		$c->response->redirect( '/' );
	}
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
	$sender ||= $c->config->{ site_email };
	my $sender_valid = Email::Valid->address(
		-address  => $sender,
		-mxcheck  => 1,
		-tldcheck => 1,
	);
	unless ( $sender_valid ) {
		$c->flash->{ error_msg } = 'Invalid email address.';
		return;
	}
	my $recipient = $c->stash->{ form }->email_to;
	$recipient  ||= $c->config->{ site_email };
	my $subject   = $c->request->param( 'email_subject' );
	$subject    ||= 'Email from '. $c->config->{ site_name };

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
	$sender ||= $c->config->{ site_email };
	my $recipient = $c->stash->{ form }->email_to;
	$recipient  ||= $c->config->{ site_email };
	my $subject   = $c->request->param( 'email_subject' );
	$subject    ||= 'Email from '. $c->config->{ site_name };

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
