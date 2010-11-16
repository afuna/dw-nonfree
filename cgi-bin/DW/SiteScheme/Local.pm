#!/usr/bin/perl
#
# DW::SiteScheme::Local
#
# Register the local sitesechemes
#
# Authors:
#      Andrea Nall <anall@andreanall.com>
#
# Copyright (c) 2010 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.
#
use DW::SiteScheme;

DW::SiteScheme->register_siteschemes(
    'celerity-local' => 'celerity',
    'dreamwidth' => 'global',
    'gradation-horizontal-local' => 'gradation-horizontal',
    'gradation-vertical-local' => 'gradation-vertical',
    'tropo-common' => 'common',
    'tropo-purple' => 'tropo-common',
    'tropo-red' => 'tropo-common'
);

DW::SiteScheme->register_default_sitescheme( 'tropo-red' );

1;

