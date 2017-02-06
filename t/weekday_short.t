package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __weekday_short };
use Test::More 0.47;	# The best we can do with Perl 5.7.2.

plan tests => 8;

is( __weekday_short( 0 ), '', q<No weekday> );

is( __weekday_short( 1 ), 'Ste', q<Weekday 1> );

is( __weekday_short( 2 ), 'Sun', q<Weekday 2> );

is( __weekday_short( 3 ), 'Mon', q<Weekday 3> );

is( __weekday_short( 4 ), 'Tre', q<Weekday 4> );

is( __weekday_short( 5 ), 'Hev', q<Weekday 5> );

is( __weekday_short( 6 ), 'Mer', q<Weekday 6> );

is( __weekday_short( 7 ), 'Hig', q<Weekday 7> );

1;

# ex: set textwidth=72 :
