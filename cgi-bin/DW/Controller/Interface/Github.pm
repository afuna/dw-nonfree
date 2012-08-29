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

    # parse out the payload
    my $payload = JSON::jsonToObj( $r->post_args->{payload} );

    my $hook_type = exists $payload->{pull_request} ? "pull_request" :
                    exists $payload->{commits}      ? "push"         :
                    "";

    my %table = (
            pull_request => [ sub {
                my $payload = $_[0];
                my $pull_request = $payload->{pull_request};
                my $msg = sprintf( "Pull Request %d: %s (%s)\n",
                                    $payload->{number},
                                    $payload->{action},
                                    $pull_request->{user}->{login}
                                );

                $msg   .= sprintf( "%s\n\n%s\n%s",
                                    $pull_request->{html_url},
                                    $pull_request->{title},
                                    $pull_request->{body}
                                );
                warn "$msg";
            } ],
            push => [ sub {
                # post to changelog
                warn "commits hook: post to changelog";
            }, sub {
                # comment on zilla
                warn "commits hook: post to zilla";
            }, sub {
                # mark zilla as resolved
                warn "commits hook: mark as resolved";
            } ],
    );

    foreach my $action ( @{$table{$hook_type}} ) {
        $action->( $payload );
    }

    return $r->OK;
}

1;