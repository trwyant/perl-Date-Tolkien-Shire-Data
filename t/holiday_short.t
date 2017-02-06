package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __holiday_short };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 7;

is( __holiday_short( 0 ), '', q<Not a holiday> );

is( __holiday_short( 1 ), '2Yu', q<Holiday 1> );

is( __holiday_short( 2 ), '1Li', q<Holiday 2> );

is( __holiday_short( 3 ), 'Myd', q<Holiday 3> );

is( __holiday_short( 4 ), 'Oli', q<Holiday 4> );

is( __holiday_short( 5 ), '2Li', q<Holiday 5> );

is( __holiday_short( 6 ), '1Yu', q<Holiday 6> );

1;

# ex: set textwidth=72 :
