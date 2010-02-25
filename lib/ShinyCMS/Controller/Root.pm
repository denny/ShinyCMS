package ShinyCMS::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


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
	
	# Redirect to CMS-controlled site
	$c->response->redirect( $c->uri_for( '/pages/' ) );
}


=head2 admin

Forward to the admin area

=cut

sub admin : Path('admin') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Redirect to admin area
	$c->response->redirect( $c->uri_for('/user/login') );
}


=head2 login

Forward to the admin area

=cut

sub login : Path('login') : Args(0) {
	my ( $self, $c ) = @_;
	
	# Redirect to admin area
	$c->response->redirect( $c->uri_for('/user/login') );
}


=head2 search

Display search form, process submitted search forms.

=cut

sub search : Path('search') : Args(0) {
    my ( $self, $c ) = @_;
	
	$c->forward( 'Root', 'build_menu' );
	
	if ( $c->request->param('search') ) {
		$c->forward( 'Pages', 'search' );
		
		# ...
	}
}


=head2 sitemap

Generate a sitemap.

=cut

sub sitemap : Path('sitemap') : Args(0) {
	my ( $self, $c ) = @_;
	
	my @sections = $c->model('DB::CmsSection')->search;
	$c->stash->{ sections } = \@sections;
	
	$c->forward( 'Root', 'build_menu' );
}


=head2 default

404 handler

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    
	$c->forward( 'Root', 'build_menu' );
	
    $c->stash->{ template } = '404.tt';
    
    $c->response->status(404);
}


=head2 build_menu

Build the menu data structure.

=cut

sub build_menu : CaptureArgs(0) {
	my ( $self, $c ) = @_;
	
	# Build up menu structure
	$c->forward( 'Pages', 'build_menu' );
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


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

