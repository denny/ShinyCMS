package ShinyCMS::Controller::Form;

use strict;
use warnings;

use parent 'Catalyst::Controller';

=head1 NAME

ShinyCMS::Controller::Form

=head1 DESCRIPTION

Main controller for ShinyCMS's forms.

=head1 METHODS

=cut


=head2 index

Forward to the default form if no form is specified.

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	$c->response->redirect( $c->uri_for('/form/'. default_form() ) );
}


=head2 default_form

Return the default form.

=cut

sub default_form {
	# TODO: allow users to set a default form which can be retrieved with this method ?
	return 'contact-us';
}


=head2 get_form

Fetch the form and stash it.

=cut

sub get_form : Chained('/') : PathPart('form') : CaptureArgs(1) {
	my ( $self, $c, $url_name ) = @_;
	
	# get the default page if none is specified
	$url_name ||= default_form();
	
	$c->stash->{ form } = $c->model('DB::Form')->find( { url_name => $url_name } );
	
	# TODO: 404 handler
	die "Form $url_name not found" unless $c->stash->{ form };
}


=head2 view

View a form.

=cut

sub view : Chained('get_form') : PathPart('') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Set the TT template to use
	$c->stash->{template} = 'cms_templates/'. $c->stash->{ form }->template->filename;
}


=head2 submit_do

Process a form submission.

=cut

sub submit_do : Chained('get_form') : PathPart('submit_do') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Extract details from form
	my $details = {
		foo		=> $c->request->params->{ foo },
	};
	
	# TODO: process form
	# ...
	
	# Shove a confirmation message into the flash
	$c->flash->{status_msg} = 'Done';
	
	# Bounce back to the form
	$c->response->redirect( '/form/'. $c->request->params->{ url_name } );
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

1;

