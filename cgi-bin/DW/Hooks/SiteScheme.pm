# Hooks for the site scheme(s)
#
# Authors:
#     Janine Costanzo <janine@netrophic.com>
#
# Copyright (c) 2009 by Dreamwidth Studios, LLC.
#
# This program is NOT free software or open-source; you can use it as an
# example of how to implement your own site-specific extensions to the
# Dreamwidth Studios open-source code, but you cannot use it on your site
# or redistribute it, with or without modifications.
#

package DW::Hooks::SiteScheme;

use strict;

LJ::register_hook('modify_scheme_list', sub {
    my $schemesref = shift;

    @$schemesref = (
        { scheme => "tropo-red", title => "Tropospherical Red" },
        { scheme => "tropo-purple", title => "Tropospherical Purple" },
        { scheme => "celerity-local", title => "Celerity" },
        { scheme => "lynx", title => "Lynx (light mode)" },
    );
});

1;
