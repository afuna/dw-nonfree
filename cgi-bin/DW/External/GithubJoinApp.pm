#!/usr/bin/perl
#
# Authors:
#      Afuna <coder.dw@afunamatata.com>
#
# Copyright (c) 2014 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.

package DW::External::GithubJoinApp;

use strict;
use LJ::JSON;
use Net::OAuth2::Profile::WebServer;


=head1 NAME

DW::External::GithubJoinApp -  Join a team on Github

=head1 SYNOPSIS

=cut

sub new {
    my $class = $_[0];
    return bless { auth => Net::OAuth2::Profile::WebServer->new(
        name            => 'Join Dreamwidth Team',
        client_id       => $LJ::GITHUB{join_app}->{client_id},
        client_secret   => $LJ::GITHUB{join_app}->{client_secret},
        site            => 'https://github.com',
        state           => LJ::challenge_generate( 300 ), # 5 minute auth token
        authorize_path  => '/login/oauth/authorize',
        access_token_path => '/login/oauth/access_token',
        protected_resource_url => 'https://api.github.com/user',
        protected_resource_method => "GET",
    ) }, $class;
}

sub redirect_to_authorize {
    my ( $self, $r ) = @_;
    my $auth = $self->{auth};
    return $r->redirect( $auth->authorize );
}

sub get_github_login {
    my ( $self, $code ) = @_;
    my $auth = $self->{auth};

    my $access_token = $auth->get_access_token( $code );
    my $response = $access_token->get( $auth->protected_resource_url );

    my $userinfo = from_json( $response->decoded_content );
    return $userinfo->{login};
}

1;