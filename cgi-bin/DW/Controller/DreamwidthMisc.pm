#!/usr/bin/perl
#
# DW::Controller::DreamwidthMisc
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

package DW::Controller::DreamwidthMisc;

use strict;
use warnings;
use DW::Controller;
use DW::Routing::Apache2;
use DW::Template::Apache2;

DW::Routing::Apache2->register_string( '/about', \&about_handler, app => 1 );

sub about_handler {
    return DW::Template::Apache2->render_template( 'misc/about.tt' );
}

1;
