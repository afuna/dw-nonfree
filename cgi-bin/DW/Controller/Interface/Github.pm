#!/usr/bin/perl
#
# DW::Controller::Interface::Github.pm
#
# DW github webhook code
#
# Authors:
#      Afuna <coder.dw@afunamatata.com>
#      Pau Amma <pauamma@dreamwidth.org>
#
# Copyright (c) 2012 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.

use strict;
use warnings;

use DW::Routing;
use JSON ();

DW::Routing->register_string( "/interface/github", \&hooks_handler,
                                app => 1, methods => { POST => 1 } );

sub hooks_handler {
    my $r = DW::Request->get;
    # my $event = JSON::decode( mumble );
    # my $hook_type = $event->{ ... }); # Whatever github uses for the hook type
    # my %table = ( ... ); # hooktype => [ sub { do stuff }, sub { do more stuff } ]
    # foreach my $action ( @{$table->{$hooktype}} ) {
    #     $action->( $event );
    # }
    return $r->OK;
}

1;