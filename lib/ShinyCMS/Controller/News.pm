package ShinyCMS::Controller::News;

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


=head1 NAME

ShinyCMS::Controller::News

=head1 DESCRIPTION

Controller for ShinyCMS news section.

=head1 METHODS

=cut


=head2 base

=cut

sub base : Chained('/') : PathPart('news') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}


=head2 view_posts

=cut

sub view_posts : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    
    $c->forward( 'Root', 'build_menu' );
    
    # ...
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

