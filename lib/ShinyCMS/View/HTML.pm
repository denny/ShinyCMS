package ShinyCMS::View::HTML;

use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::View::TT';


=head1 NAME

ShinyCMS::View::HTML

=head1 DESCRIPTION

HTML view for ShinyCMS.

=head1 SEE ALSO

L<ShinyCMS>

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

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
