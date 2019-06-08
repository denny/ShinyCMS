package ShinyCMS::Controller::Admin::Form;

use Moose;
use namespace::autoclean;

BEGIN { extends 'ShinyCMS::Controller'; }


=head1 NAME

ShinyCMS::Controller::Admin::Form

=head1 DESCRIPTION

Controller for ShinyCMS form administration actions.

=cut


=head1 METHODS

=head2 base

Set up path and stash some useful stuff.

=cut

sub base : Chained( '/base' ) : PathPart( 'admin/form' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;

	# Check to make sure user has the right to view CMS forms
	return 0 unless $self->user_exists_and_can( $c, {
		action   => 'add/edit/delete form handlers',
		role     => 'CMS Form Admin',
		redirect => '/admin'
	});

	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };

	# Stash the controller name
	$c->stash->{ admin_controller } = 'Form';
}


=head2 list_forms

List forms for admin interface.

=cut

sub list_forms : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	my @forms = $c->model( 'DB::CmsForm' )->search;
	$c->stash->{ forms } = \@forms;
}


=head2 add_form

Add a new form.

=cut

sub add_form : Chained( 'base' ) : PathPart( 'add' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Fetch the list of available templates
	$c->stash->{ templates } = $c->forward( 'get_template_filenames' );

	# Set the TT template to use
	$c->stash->{template} = 'admin/form/edit_form.tt';
}


=head2 edit_form

Edit an existing form.

=cut

sub edit_form : Chained( 'base' ) : PathPart( 'edit' ) : Args( 1 ) {
	my ( $self, $c, $form_id ) = @_;

	# Get the form
	my $form = $c->model( 'DB::CmsForm' )->find({
		id => $form_id,
	});
	$c->stash->{ form } = $form;

	# Fetch the list of available templates
	$c->stash->{ templates } = $c->forward( 'get_template_filenames' );
}


=head2 edit_form_do

Process a form edit.

=cut

sub edit_form_do : Chained( 'base' ) : PathPart( 'edit-form-do' ) : Args( 0 ) {
	my ( $self, $c ) = @_;

	# Fetch the form, if one was specified
	my $form;
	if ( $c->request->param( 'form_id' ) ) {
		$form = $c->model( 'DB::CmsForm' )->find({
			id => $c->request->param( 'form_id' ),
		});

		# Process deletions
		if ( defined $c->request->param( 'delete' ) ) {
			$form->delete;

			# Shove a confirmation message into the flash
			$c->flash->{ status_msg } = 'Form deleted';

			# Bounce to the list of CMS forms
			$c->response->redirect( $c->uri_for( '/admin/form' ) );
			return;
		}
	}

	# Sanitise the url_name
	my $url_name = $c->request->param(  'url_name' );
	$url_name  ||= $c->request->param(  'name'     );
	$url_name    = $self->make_url_slug( $url_name );

	# Extract form details from request
	my $has_captcha = 0;
	$has_captcha = 1 if $c->request->param( 'has_captcha' );
	my $details = {
		name        => $c->request->param( 'name'     ),
		url_name    => $url_name,
		redirect    => $c->request->param( 'redirect' ),
		action      => $c->request->param( 'action'   ),
		email_to    => $c->request->param( 'email_to' ),
		template    => $c->request->param( 'template' ),
		has_captcha => $has_captcha || 0,
	};

	if ( $form ) {
		$form->update( $details );
	}
	else {
		$form = $c->model( 'DB::CmsForm' )->create ( $details );
	}

	# Shove a confirmation message into the flash
	$c->flash->{ status_msg } = 'Details updated';

	# Bounce back to the 'edit' page
	$c->response->redirect( $c->uri_for( 'edit', $form->id ) );
}


=head2 get_template_filenames

Get a list of available template filenames.

=cut

sub get_template_filenames : Private {
	my ( $self, $c ) = @_;

	my $template_dir = $c->path_to( 'root/emails' );
	opendir( my $template_dh, $template_dir )
		or die "Failed to open template directory $template_dir: $!";
	my @templates;
	foreach my $filename ( readdir( $template_dh ) ) {
		next unless $filename =~ m{\.tt$}; # only show TT files
		push @templates, $filename;
	}

	return \@templates;
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
