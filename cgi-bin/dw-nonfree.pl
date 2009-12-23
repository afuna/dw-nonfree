#!/usr/bin/perl
#
# THIS IS NOT LICENSED FOR USE.
#

LJ::Hooks::register_hook("journal_base", sub {
    my ($u, $vhost) = @_;
    return undef unless $LJ::ONLY_USER_VHOSTS;
    return "#" unless $u;

    # rule format:
    #    accounttype => [$use_user_vhost_if_no_underscore, $domain_to_use_otherwise]

    my $rules = {
        'P' => [1, "users.$LJ::DOMAIN"],
        'Y' => [1, "syndicated.$LJ::DOMAIN"],
        'C' => [1, "community.$LJ::DOMAIN"],
    };
    my $rule = $rules->{$u->{journaltype}} || $rules->{'P'};

    my $use_user_vhost =
        $rule->[0] && $u->{user} !~ /^\_/ && $u->{user} !~ /\_$/;

    if ($use_user_vhost) {
        my $udom = $u->{user};
        $udom =~ s/\_/-/g;
        return "http://$udom.$LJ::DOMAIN";
    } else {
        return "http://$rule->[1]/$u->{user}";
    }
});

