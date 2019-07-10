ShinyCMS - Developer Notes
==========================

Some things to bear in mind if you are going to be hacking on ShinyCMS and
contributing your changes back to the main project.


Database Changes
----------------

Please do not hand-edit the ShinyCMS::Schema::Result::* modules.  They are
generated using the utility script `bin/dev-tools/regenerate-db-modules`.  If
you want to make changes to the database structure, make your changes using
the tools supplied by your database provider (e.g. alter tables or insert new
tables using the mysql command line interface) and then regenerate the modules
using the supplied script.

Note that the database schema file in `documents/database/schema.sql` is
documentation, not a development tool.  Keeping it up to date is encouraged,
but modifying it does not achieve anything useful in and of itself.


Tests
-----

ShinyCMS has steadily improving test coverage.  Currently this is almost
entirely in the form of integration tests AKA controller tests.  If you would
like to improve the test coverage further, your contributions will be very
gratefully received!  At minimum, please don't make it worse - when you add
new code, add tests for it too  :)

You can view our current test coverage here:  
https://codecov.io/gh/denny/ShinyCMS


General
-------

If you remove functionality that other people are using, your changes are
unlikely to be integrated back into the main project.  It's usually a good
idea to speak to other users and developers on #shinycms on irc.freenode.net
before you start making major changes to existing code.
