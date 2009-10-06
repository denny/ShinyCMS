package ShinyCMS::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{namespace} = '';


=head1 NAME

ShinyCMS::Controller::Root

=head1 DESCRIPTION

Root Controller for ShinyCMS.

=head1 METHODS

=cut


=head2 index

Forward to the CMS

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# Print a message to the debug log
	#$c->log->debug( 'Entering index()' );
	
	# Catalyst welcome message
	#$c->response->body( $c->welcome_message );
	
	# Redirect to CMS-controlled site
	$c->response->redirect( $c->uri_for('/page') );
}


=head2 admin

Forward to the admin area

=cut

sub admin : Path('admin') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Print a message to the debug log
	#$c->log->debug( 'Entering admin area' );
	
	# Redirect to admin area
	$c->response->redirect( $c->uri_for('/user/login') );
}


=head2 login

Forward to the admin area

=cut

sub login : Path('login') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Print a message to the debug log
	#$c->log->debug( 'Entering admin area' );
	
	# Redirect to admin area
	$c->response->redirect( $c->uri_for('/user/login') );
}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

