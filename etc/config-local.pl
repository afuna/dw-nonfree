#!/usr/bin/perl
# -*-perl-*-

# Dreamwidth configuration file.  Copy this out of the documentation
# directory to etc/config-local.pl and edit as necessary.  The reason
# it's not in the etc directory already is to protect it from
# getting clobbered when you upgrade to the newest Dreamwidth code in
# the future.

# This, and config-private.pl should be the only files you need to 
# change to get the Dreamwidth code to run on your site. Variables
# which are set by $DW::PRIVATE::... should be configured in 
# config-private.pl instead.

# Use the  checkconfig.pl utility to find any other config variables 
# that might not be documented here. You should be able to set config 
# values here and have the DW code run; if you have to modify the
# code itself, it's a bug and you should report it.

{
    package LJ;

    # keep this enabled only if this site is a development server
    $IS_DEV_SERVER = 1;
    $ENABLE_BETA_TOOLS = 1;

    # home directory
    $HOME = $ENV{'LJHOME'};

    # the base domain of your site.
    $DOMAIN = $DW::PRIVATE::DOMAIN;

    # human readable name of this site as well as shortened versions
    # CHANGE THIS
    $SITENAME = "Dreamwidth Studios";
    $SITENAMESHORT = "Dreamwidth";
    $SITENAMEABBREV = "DW";
    $SITECOMPANY = "Dreamwidth Studios, LLC";

    # MemCache information, if you have MemCache servers running
    @MEMCACHE_SERVERS = ('127.0.0.1:11211');
    #$MEMCACHE_COMPRESS_THRESHOLD = 1_000; # bytes

    # optional SMTP server if it is to be used instead of sendmail
    $SMTP_SERVER = "localhost";
    $MAIL_TO_THESCHWARTZ = 1;

    # setup recaptcha
    %RECAPTCHA = (
            public_key  => $DW::PRIVATE::RECAPTCHA{public_key},
            private_key => $DW::PRIVATE::RECAPTCHA{private_key},
        );

    # If enabled, disable people coming in over Tor exits from using various parts of the site.
    $USE_TOR_CONFIGS = 0;

    # Configure what you want blocked here.  Requires $USE_TOR_CONFIGS to be on.
    %TOR_CONFIG = (
        shop => 1,     # Disallow Tor users from accessing the Shop.
    );

    # PayPal configuration.  If you want to use PayPal, uncomment this
    # section and make sure to fill in the fields at the bottom of config-private.pl.
    #%PAYPAL_CONFIG = (
    #        # express checkout URL, the token gets appended to this
    #        url       => 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=',
    #        api_url   => 'https://api-3t.sandbox.paypal.com/nvp',

    #        # credentials for the API
    #        user      => $DW::PRIVATE::PAYPAL{user},
    #        password  => $DW::PRIVATE::PAYPAL{password},
    #        signature => $DW::PRIVATE::PAYPAL{signature},

    #        # set this to someone who is responsible for getting emails about
    #        # various PayPal related events
    #        email     => $DW::PRIVATE::PAYPAL{email},
    #    );

    # if you define these, little help bubbles appear next to common
    # widgets to the URL you define:
    %HELPURL = (
        paidaccountinfo => "http://www.dreamwidth.org/support/faqbrowse.bml?faqid=4",
    );

    # Configuration for suggestions community & adminbot
    $SUGGESTIONS_COMM = "dw_suggestions";
    $SUGGESTIONS_USER = "suggestions_bot";

    # 404 page
    # Uncomment if you don't want the (dw-free) default, 404-error.bml
    # (Note: you need to provide your own 404-error-local.bml)
    $PAGE_404 = "404-error-local.bml";

    # merchandise link
    $MERCH_URL = "http://www.zazzle.com/dreamwidth*";

    # shop/pricing configuration
    %SHOP = (
        # key => [ $USD, months, account type, cost in points ],
        prem6  => [  20,  6, 'premium', 200 ],
        prem12 => [  40, 12, 'premium', 400 ],
        paid1  => [   3,  1, 'paid', 30    ],
        paid2  => [   5,  2, 'paid', 50    ],
        paid6  => [  13,  6, 'paid', 130   ],
        paid12 => [  25, 12, 'paid', 250   ],
        seed   => [ 200, 99, 'seed', 2000   ],
        points => [],
    );

    %LJ::BETA_FEATURES = (
        "journaljquery" => {
            start_time  => 0,
            end_time    => "Inf",
        },
    );

    %GITHUB = (
        bugzilla => {
            username => '',
            password => '',
            server   => 'bugs.dwscoalition.org',
        },
        changelog => {
            username => '',
            password => '',
        }
    );


}

1;
