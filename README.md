ShinyCMS
========

ShinyCMS is an open source CMS built in Perl using the Catalyst framework.

It is intended for use by web designers and web developers who want to keep
a clear distinction between the markup they create and the content their
clients can edit.


Features
--------

The following functionality is either present or in progress:

* Content-managed pages, page templates, and forms
* User accounts, profiles and administration
* Blog
* News/PR section
* Newsletters (HTML mailshots)
* Online shop
* Membership system which can control access to files, pages, or even paragraphs
* Payment handling system which can handle recurring subscriptions
* Tags on blog posts, news posts, forum posts, and shop items
* Nested comment threads on blog posts, news posts, forum posts, and shop items
* 'Likes' on blog posts, shop items, and comments
* Event listings
* Forums
* Polls
* 'Shared content' - store text and HTML fragments for re-use throughout a site


Installation
------------

You can install ShinyCMS by pasting one of the commands below into a terminal:

[[[ NEED ADD DOCKER COMMANDS FOR AUTOMATIC INSTALL ]]]

[[[ NEED TEST THE FOLLOWING CPAN COMMANDS FOR MANUAL INSTALL ]]]
$ dzil authordeps --missing | cpanm -v
$ cpanm -v --installdeps .
$ cpanm -v --installdeps --force .  # Net::Akismet
$ sudo apt-get install postgresql libpq-dev
$ cpanm -v --installdeps --with-feature=postgres .
$ ./bin/database/build-with-demo-data
$ prove -lr t/

[[[ NEED AUTOMATE THE FOLLOWING COMMANDS TO GO FROM MANUAL TO AUTOMATED TESTING ]]]
$ bin/database/build
$ prove -lv t/admin-controllers/controller_Admin-Blog.t


Author
------

ShinyCMS is copyright (c) 2009-2019 Denny de la Haye, 2025 Perl Community.


Licensing
---------

ShinyCMS is free software; you can redistribute it and/or modify it under the
terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2, or (at your option) any later version, or

b) the "Artistic License"; either version 2, or (at your option) any later
   version.

https://opensource.org/licenses/GPL-2.0

https://opensource.org/licenses/Artistic-2.0

ShinyCMS includes code and content provided by other free and open-source
projects, which have their own licensing conditions; please see the file
docs/Licensing for full details.


Test Status
-----------

[![CircleCI](https://circleci.com/gh/denny/ShinyCMS.svg?style=svg)](https://circleci.com/gh/denny/ShinyCMS) (CircleCI)  [![Codecov](https://codecov.io/gh/denny/ShinyCMS/branch/main/graphs/badge.svg)](https://codecov.io/gh/denny/ShinyCMS) (Codecov) [![Maintainability](https://api.codeclimate.com/v1/badges/dd26ec3439655b40bc63/maintainability)](https://codeclimate.com/github/denny/ShinyCMS/maintainability) (CodeClimate)
