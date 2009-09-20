package Reactant::View::HTML;

use Moose;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
	TEMPLATE_EXTENSION => '.tt',
	WRAPPER  => 'wrapper.tt',
);

=head1 NAME

Reactant::View::HTML

=head1 DESCRIPTION

TT View for Reactant. 

=head1 SEE ALSO

L<Reactant>

=head1 AUTHOR

Denny de la Haye <2009@denny.me>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

