#!/usr/bin/perl
#
# DW::Controller::Interface::Github
#
# Webhook that github pings when certain events happen
#
# Authors:
#      Afuna <coder.dw@afunamatata.com>
#
# Copyright (c) 2014 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.

package DW::Controller::Interface::Github;

use strict;

use DW::Routing;
use LJ::JSON;
use Digest::HMAC_SHA1 ();
use HTTP::Request;
use List::MoreUtils qw/ none /;

DW::Routing->register_string( "/interface/github", \&hooks_handler,
                                app => 1,
                                prefer_ssl => 1,
                                methods => { POST => 1 },
                            );

my %table = (
    ping            => [ \&respond_to_ping ],
    issue_comment   => [ \&label_from_comment, \&claim_issue ],
    issues          => [ \&label_from_new_issue ],
    pull_request    => [ \&label_from_new_pull_request ],
);

sub respond_to_ping {
    my $r = DW::Request->get;
    $r->print( "pinged" );
}

# matches "claim", "claimed", "claiming"
sub matches_claim {
    my $text = $_[0];
    return $text =~ /\bclaim(?:ed|ing)?\b/i;
}

sub claim_issue {
    my $payload = $_[0];
    my $comment = $payload->{comment};

    if ( matches_claim( $comment->{body} ) ) {
        my $edit_url = $payload->{issue}->{url};
        my $assignee = $comment->{user}->{login};

        _call_github_api( $edit_url,
                to_json( { assignee => $assignee } ),
                method => "PATCH"
        );

        _call_github_api( $payload->{issue}->{url} . "/labels",
                to_json( [ "status: claimed" ] ),
                method => "POST"
        );
        return;
    }
}

sub label_from_comment {
    my $payload = $_[0];

    my @labels = _extract_labels( $payload->{comment}->{body} );
    my $is_pull_request = exists $payload->{issue}->{pull_request};
    my $current_status = $payload->{issue}->{assignee} ? "status: claimed" : "status: unclaimed";

    # if we're commenting on an issue (not a pull request), we may want to update the claimed/unclaimed status
    unless ( $is_pull_request ) {
        my @current_labels = map { $_->{name} } @{$payload->{issue}->{labels}};

        # so we don't make unnecessary API calls, only update if the claimed status has changed and no longer matches existing labels
        if ( none { $_ eq $current_status } @current_labels ) {
            # and since we replace all labels, get a list of the current labels -- sans automatically generated tags
            @labels = grep { $_ ne "status: claimed" && $_ ne "status: unclaimed" && $_ !~ /type: / } @current_labels;
        }
    }

    # add the current status to the list of labels, if we have any other labels that needed replacing
    push @labels, $current_status if @labels;

    _replace_labels( $payload->{issue}->{url}, $is_pull_request, @labels );
}

sub label_from_new_issue {
    my $payload = $_[0];
    return unless $payload->{action} eq "opened";

    my $issue = $payload->{issue};

    my @labels = _extract_labels( $issue->{body} );
    push @labels, "status: untriaged" unless @labels;
    push @labels, $payload->{issue}->{assignee} ? "status: claimed" : "status: unclaimed";

    _replace_labels( $issue->{url}, 0, @labels );
}

sub label_from_new_pull_request {
    my $payload = $_[0];
    return unless $payload->{action} eq "opened";

    my $pr = $payload->{pull_request};

    my @labels = _extract_labels( $pr->{body} );
    push @labels, "status: untriaged" unless @labels;

    _replace_labels( $pr->{issue_url}, 1, @labels );
}

# labels are in the form of: "##label" "##prefix:label"
sub _extract_labels {
    my ( $text ) = @_;

    my @labels_from_comment = ( $text =~ m/\#\#((?:
                                            \w      # word character
                                            |
                                            (?::[ ])  # colon followed by a space
                                        )+)
                                        /gx );
    my @valid_labels = (
            "from: suggestions", "from: support",
            "is: bug", "is: feature", "is: upkeep",
        );

    my %mapped_labels = (
        "effort: lower"     => "effort: (1) lower",
        "effort: average"   => "effort: (2) average",
        "effort: higher"    => "effort: (3) higher",

        "severity: minor"       => "severity: (1) minor",
        "severity: major"       => "severity: (2) major",
        "severity: critical"    => "severity: (3) critical",

    );
    $mapped_labels{$_} = $_ foreach @valid_labels;

    my @normalized_labels = grep { $_ }
                                map { $mapped_labels{$_} } @labels_from_comment;
    return @normalized_labels;
}

sub _replace_labels {
    my ( $issue_url, $is_pull_request, @labels ) = @_;
    return unless @labels;

    # automatically add labels (but only if we're modifying labels in the first place)
    push @labels, ( $is_pull_request ? "type: pull request" : "type: issue" );

    # replace all labels in the issue
    return _call_github_api( "$issue_url/labels", to_json( \@labels ) );
}

sub _call_github_api {
    my ( $api_url, $content, %opts ) = @_;
    my $http_method = $opts{method} || "PUT";

    my $r = DW::Request->get;
    $r->print( "$http_method: $api_url\n" . $content . "\n");

    my $ua = LJ::get_useragent( role => 'github' );
    $ua->agent( $LJ::SITENAME );

    my $request = HTTP::Request->new( $http_method => $api_url,
                                      [ Authorization => "token $LJ::GITHUB{api}->{token}" ],
                                      $content
                                    );
    my $res = $ua->request( $request );
    $r->print("API response: " . $res->message);
    $r->print("\n\n");

    return $res && $res->is_success ? 1 : 0;
}

sub hooks_handler {
    my $r = DW::Request->get;
    my $body = $r->content;

    # Check received SHA1 digest if shared secret configured
    my $salt = $LJ::GITHUB{api}->{gh_signature};
    if ( defined $salt ) {
        my $received_SHA1 = $r->header_in( 'X-Hub-Signature' );
        if ( defined $received_SHA1 and $received_SHA1 =~ s/^sha1=//i ) {
            return $r->FORBIDDEN
                if lc( $received_SHA1 )
                   ne lc( Digest::HMAC_SHA1::hmac_sha1_hex( $body, $salt ) );
        } else {
            die "Missing or malformed signature header: ", $received_SHA1 // '';
        }
    }

    # parse out the payload
    my $payload = from_json( $body );

    my $hook_type = $r->header_in( 'X-GitHub-Event' );

    if ( $table{$hook_type} ) {
        foreach my $action ( @{$table{$hook_type}} ) {
                $action->( $payload );
        }
    }

    return $r->OK;
}

1;