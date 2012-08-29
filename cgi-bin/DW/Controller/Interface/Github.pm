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
use XMLRPC::Lite;

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

                my $bugzilla = $LJ::GITHUB{bugzilla};
                my $username = $bugzilla->{username};
                my $password = $bugzilla->{password};
                my $server = $bugzilla->{server};
                return unless defined $username && defined $password && defined $server;

                my $pull_request = $payload->{pull_request};

                # we're looking for anything that looks like a bug id
                # in the form of: "close / fix / address bug 123, 456, and 789"
                my $pull_text = "$pull_request->{title} $pull_request->{body}";
                my ( $closes, $bugs ) =
                    ( $pull_text =~ /(?:(close|fix|address)e?(?:s|d)? )?bugs?:? *([\d ,\+&#and]+)/i );
                my @bug_ids = grep { $_ + 0 } split( /(\d+)/, $bugs );
                return unless @bug_ids;

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

                my $xmlrpc = XMLRPC::Lite->new;
                $xmlrpc->proxy(
                        "http://$server/xmlrpc.cgi",
                        agent => "$LJ::SITENAME Changelog Hook ($LJ::ADMIN_EMAIL)"
                );

                foreach my $id ( @bug_ids ) {
                    my $res = $xmlrpc->call( "Bug.add_comment", {
                        id => $id, comment => $msg,
                        Bugzilla_login =>  $username,
                        Bugzilla_password => $password
                    } );
                }
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