#!/usr/bin/perl
#
# DW::BusinessRules::InviteCodes::DWS
#
# This module implements business rules for invite code distribution that are
# specific to Dreamwidth Studios, LLC
#
# Authors:
#      Pau Amma <pauamma@cpan.org>
#
# Copyright (c) 2009 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.

package DW::BusinessRules::InviteCodes::DWS;
use strict;
use warnings;
use Carp ();
use lib "$LJ::HOME/cgi-bin";
use base 'DW::BusinessRules::InviteCodes';

use DW::InviteCodes;
use LJ::User;

=head1 NAME

DW::BusinessRules::InviteCodes - business rules for invite code distribution

=head1 DESCRIPTION

This module implements business rules for invite code distribution that are
specific to Dreamwidth Studios, LLC. Refer to DW::BusinessRules::InviteCodes
for more information and for the external API (user_classes, max_users,
search_class, and adj_invites).

=cut

# key => { search => \&search_fun [, search_arg => 'second argument' ] }
# key is also used for long cat name (invitecodes.userclass.*), and first
# argument is always max users to return.
my %user_classes = (
    paidusers       => { search => \&_search_caps, search_arg => 'paid_user' },
    permusers       => { search => \&_search_caps, search_arg => 'perm_user' },
    active30d       => { search => \&_search_ctrk, search_arg => 30 }, # days
    noinvleft       => { search => \&_search_noinvleft }, # used all invites
    noinvleft_apinv => { search => \&_search_noinvleft_apinvitee,
                         search_arg => 30 }, # same + paid/perm/active invitee
);

sub user_classes {
    my ($lang) = @_;
    $lang ||= LJ::Lang::get_effective_lang();
    my %ucname;
    $ucname{$_}= LJ::Lang::get_text( $lang, "invitecodes.userclass.$_" )
        foreach keys %user_classes;
    return \%ucname;
}

# If there are fewer invites than qualifying users, invites get up to 1 per
# user, but only if invites are at least 3/4 of users. Hence, user limit is
# 4/3 of invites + 1.
sub max_users {
    my ($ninv) = @_;

    return int( $ninv + $ninv / 3 + 1 );
}

sub search_class {
    my ($uckey, $max_nusers) = @_;
    Carp::croak( "$uckey not a known user class" )
        unless exists $user_classes{$uckey};

    my $uclass = $user_classes{uckey};
    return $uclass->{search}->( $uckey, $max_nusers, $uclass->{search_arg} );
}

# Search in "user" (unclustered) for capability.
sub _search_caps {
    my ($uckey, $max_nusers, $capkey) = @_;
    my $mask = LJ::mask_from_classes( $capkey )
        or die "$capkey not defined in \%LJ::CAP";
    my $dbslow = LJ::get_dbh( 'slow' ) or die "Can't get slow role";

    # TODO: Allow nonvalidated email addresses? We need to deal with users who
    # shouldn't be send email for some reason anyway (eg because they opted out
    # of mass mailings) by putting the notice in their inbox instead (or in
    # addition) or discarding it altogether, so might as well handle
    # nonvalidated addresses the same way. (Note that this applies to all
    # search functions, not just this one.)
    my $sth = $dbslow->prepare( "SELECT userid FROM user " .
                             "WHERE journaltype = 'P' AND status = 'A' " .
                                 "AND statusvis = 'V' AND (caps & ?) > 0 " .
                             "LIMIT ?" )
        or die $dbslow->errstr;
    my $uids = $dbslow->selectcol_arrayref( $sth, {}, $mask, $max_nusers )
        or die $dbslow->errstr;
    return $uids;
}

# Search in "clustertrack2" (clustered) for recent activity
sub _search_ctrk {
    my ($uckey, $max_nusers, $days) = @_;
    my @uids;

    LJ::foreach_cluster( sub {
        return if $max_nusers <= @uids;

        my ($cid, $dbh) = @_;
        # Can't do a join here to weed out comms/unvalidated/not visible, since
        # the table with that info is elsecluster. So do separate filtering
        # pass using _filter_pav.
        my $sth = $dbh->prepare( "SELECT userid FROM clustertrack2 " .
                                 "WHERE timeactive >= UNIX_TIMESTAMP() - ? " .
                                 "LIMIT ?" )
            or die $dbh->errstr;
        my $cuids = $dbh->selectcol_arrayref( $sth, {}, $days * 86400,
                                              $max_nusers - @uids )
            or die $dbh->errstr;
        
        push @uids, @$cuids;
    } );

    # Don't filter if too many, otherwise we lose that information
    return ($max_nusers <= scalar @uids) ? \@uids : _filter_pav( \@uids );
}

# Search "acctcode" (unclustered) for users with no invite left
sub _search_noinvleft {
    my ($uckey, $max_nusers) = @_;
    my $dbslow = LJ::get_dbh( 'slow' ) or die "Can't get slow role";

    # Second column will be all 0 here (and is unneeded anyway), but putting it
    # in HAVING and not SELECT is non-standard SQL.
    my $sth = $dbslow->prepare( "SELECT userid, count(a.rcptid) as unused " .
                             "FROM acctcode WHERE a.rcptid = 0 " .
                             "GROUP BY a.userid HAVING unused = 0 LIMIT ?" )
        or die $dbslow->errstr;
    # Keep only a.userid
    my $uids = $dbslow->selectcol_arrayref( $sth, { Columns => [1] }, $max_nusers )
        or die $dbslow->errstr;
    # Don't filter if too many, otherwise we lose that information
    return ($max_nusers <= scalar @$uids) ? $uids : _filter_pav( $uids );
}

# Search "acctcode" (unclustered) for users with no invite left, then restrict
# to those having at least one active or paid invitee
sub _search_noinvleft_apinvitee {
    my ($uckey, $max_nusers, $days) = @_;
    my $dbslow = LJ::get_dbh( 'slow' ) or die "Can't get slow role";

    # Second column will be all 0 here (and is unneeded anyway), but putting it
    # in HAVING and not SELECT is non-standard SQL.
    my $sth = $dbslow->prepare( "SELECT userid, count(rcptid) as unused " .
                             "FROM acctcode WHERE rcptid = 0 " .
                             "GROUP BY userid HAVING unused = 0 LIMIT ?" )
        or die $dbslow->errstr;
    # Keep only a.userid
    my $uids = $dbslow->selectcol_arrayref( $sth, { Columns => [1] }, $max_nusers )
        or die $dbslow->errstr;
    # Don't filter if too many, otherwise we lose that information
    return $uids if $max_nusers <= scalar @$uids;

    $uids = _filter_pav( $uids );
    my @filtered_uids;
    OWNER: foreach my $uid (@$uids) {
        my @ics = DW::InviteCodes->by_owner( userid => $uid );
        my @inv_uids;
        foreach my $code (@ics) {
            push @inv_uids, $code->recipient if $code->recipient;
        }
        my @inv_users = LJ::load_userids( @inv_uids );

        foreach my $iu (@inv_users) {
            if ($iu->in_class( 'paid_user' ) || $iu->in_class( 'perm_user' )
                    || $iu->get_timeactive >= time() - $days * 86400) {
                push @filtered_uids, $iu->id;
                next OWNER;
            }
        }
    }
    return \@filtered_uids;
}

# From a list of userids, returns those for personal, visible journals with
# validated email addresses.
sub _filter_pav {
    my ($in_uids) = @_;
    my @out_uids;

    # TODO: make magic number configurable.
    for (my $start = 0; $start < @$in_uids; $start += 1000) {
        my $end = ($start + 999 <= $#$in_uids) ? $start + 999 : $#$in_uids;
        my @slice_users = LJ::load_userids( $in_uids->[$start..$end] );
        foreach my $user (@slice_users) {
            push @out_uids, $user->{userid}
                if $user->is_person && $user->is_visible && $user->is_validated;
        }
    }

    return \@out_uids;
}

=head2 C<< DW::BusinessRules::InviteCodes::adj_invites( $ninv, $nusers ) >>

Returns an adjusted number of invites "close" to $ninv and that can be evenly
divided among $nusers recipients, or 0 if that adjustment is impossible or
would be too different from $ninv. Note that the returned value can be larger
than $inv if the site-specific business rules allow adjustement upward.

The default implementation returns the largest multiple of $ninv no larger than
$nusers.

=cut

sub adj_invites {
    my ($ninv, $nusers) = @_;

    return ($ninv <= 0 || $nusers <= 0) ? 0 : ($ninv - $ninv % $nusers);
}

1;

=head1 BUGS

Bound to have some.

=head1 AUTHORS

Pau Amma <pauamma@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by Dreamwidth Studios, LLC.

This program is NOT free software or open-source; you can use it as an example
of how to implement your own site-specific extensions to the Dreamwidth Studios
open-source code, but you cannot use it on your site or redistribute it, with
or without modifications.
