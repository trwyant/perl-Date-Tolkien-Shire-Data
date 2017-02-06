package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __month_name };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 13;

is( __month_name( 0 ), '', q<A holiday> );

is( __month_name( 1 ), 'Afteryule', q<Month 1> );

is( __month_name( 2 ), 'Solmath', q<Month 2> );

is( __month_name( 3 ), 'Rethe', q<Month 3> );

is( __month_name( 4 ), 'Astron', q<Month 4> );

is( __month_name( 5 ), 'Thrimidge', q<Month 5> );

is( __month_name( 6 ), 'Forelithe', q<Month 6> );

is( __month_name( 7 ), 'Afterlithe', q<Month 7> );

is( __month_name( 8 ), 'Wedmath', q<Month 8> );

is( __month_name( 9 ), 'Halimath', q<Month 9> );

is( __month_name( 10 ), 'Winterfilth', q<Month 10> );

is( __month_name( 11 ), 'Blotmath', q<Month 11> );

is( __month_name( 12 ), 'Foreyule', q<Month 12> );

1;

# ex: set textwidth=72 :
