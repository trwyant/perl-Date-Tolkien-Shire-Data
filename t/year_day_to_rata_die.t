package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __year_day_to_rata_die
    __rata_die_to_year_day
    __is_leap_year
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

use constant TOP_YEAR	=> 400;

my $want_rd = 1;

plan tests => TOP_YEAR * 3;

foreach my $year ( 1 .. TOP_YEAR ) {

    my $rata_die = __year_day_to_rata_die( $year );
    cmp_ok( $rata_die, '==', $want_rd,
	"2 Yule $year is Rata Die $want_rd" );

    my ( $yr, $da ) = __rata_die_to_year_day( $rata_die );
    cmp_ok( $yr, '==', $year, "Rata Die $rata_die is year $year" );
    cmp_ok( $da, '==', 1, "Rata Die $rata_die is day 1 of $year" );

    $want_rd += 365 + __is_leap_year( $year );
}

1;

# ex: set textwidth=72 :
