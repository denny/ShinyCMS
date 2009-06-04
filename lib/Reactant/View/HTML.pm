package Reactant::View::HTML;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
	TEMPLATE_EXTENSION => '.tt',
	WRAPPER => 'wrapper.tt',
);

=head1 NAME

Reactant::View::HTML

=head1 DESCRIPTION

TT View for Reactant. 

=head1 SEE ALSO

L<Reactant>

=head1 AUTHOR

Denny de la Haye <reactant.2009@contentmanaged.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

