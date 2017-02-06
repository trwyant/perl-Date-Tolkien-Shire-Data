package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __month_short };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 13;

is( __month_short( 0 ), undef, q<Invalid month> );

is( __month_short( 1 ), 'Ayu', q<Month 1> );

is( __month_short( 2 ), 'Sol', q<Month 2> );

is( __month_short( 3 ), 'Ret', q<Month 3> );

is( __month_short( 4 ), 'Ast', q<Month 4> );

is( __month_short( 5 ), 'Thr', q<Month 5> );

is( __month_short( 6 ), 'Fli', q<Month 6> );

is( __month_short( 7 ), 'Ali', q<Month 7> );

is( __month_short( 8 ), 'Wed', q<Month 8> );

is( __month_short( 9 ), 'Hal', q<Month 9> );

is( __month_short( 10 ), 'Win', q<Month 10> );

is( __month_short( 11 ), 'Blo', q<Month 11> );

is( __month_short( 12 ), 'Fyu', q<Month 12> );

1;

# ex: set textwidth=72 :
