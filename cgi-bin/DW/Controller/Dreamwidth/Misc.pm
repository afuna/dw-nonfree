#!/usr/bin/perl
#
# DW::Controller::Dreamwidth::Misc
#
# Controller for Dreamwidth specific miscellaneous pages.
#
# Authors:
#      Mark Smith <mark@dreamwidth.org>
#
# Copyright (c) 2009 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.
#

package DW::Controller::Dreamwidth::Misc;

use strict;
use warnings;
use DW::Routing;

DW::Routing->register_static( '/about', 'misc/about.tt', app => 1 );

1;
