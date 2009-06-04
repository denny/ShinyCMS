package Reactant::Controller::Discussion;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Reactant::Controller::Discussion - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Reactant::Controller::Discussion in Discussion.');
}






=head1 AUTHOR

Denny de la Haye <reactant.2009@contentmanaged.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

