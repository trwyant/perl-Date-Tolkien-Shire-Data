package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __holiday_name };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 7;

is( __holiday_name( 0 ), undef, q<Invalid holiday> );

is( __holiday_name( 1 ), '2 Yule', q<Holiday 1> );

is( __holiday_name( 2 ), '1 Lithe', q<Holiday 2> );

is( __holiday_name( 3 ), q<Midyear's day>, q<Holiday 3> );

is( __holiday_name( 4 ), 'Overlithe', q<Holiday 4> );

is( __holiday_name( 5 ), '2 Lithe', q<Holiday 5> );

is( __holiday_name( 6 ), '1 Yule', q<Holiday 6> );

1;

# ex: set textwidth=72 :
