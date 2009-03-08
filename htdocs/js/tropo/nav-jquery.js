/*
    js/tropo/nav-jquery.js

    Tropospherical Navigation JavaScript

    Authors:
        Mark Smith <mark@dreamwidth.org>

    Copyright (c) 2009 by Dreamwidth Studios, LLC.

    This program is NOT free software or open-source; you can use it as an
    example of how to implement your own site-specific extensions to the
    Dreamwidth Studios open-source code, but you cannot use it on your site
    or redistribute it, with or without modifications.
*/

DW.whenPageLoaded( function() {

    // used below
    var hideNavs = function() {
        $( '.topnav' ).removeClass( 'hover' );
        $( '.subnav' ).removeClass( 'hover' );
    };

    // add event listeners to the top nav items
    $( '.topnav' )

        .mouseover( function() {
            hideNavs();
            $( this ).addClass( 'hover' );
        } )

        .mouseout( function() {
            hideNavs();
        } );
} );
