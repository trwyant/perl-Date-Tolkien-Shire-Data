package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __quarter };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 366;

foreach my $spec (
    [  0, 1,  1, 1 ],
    [  1, 1, 30, 1 ],
    [  2, 1, 30, 1 ],
    [  3, 1, 30, 1 ],
    [  4, 1, 30, 2 ],
    [  5, 1, 30, 2 ],
    [  6, 1, 30, 2 ],
    [  0, 2,  2, 2 ],
    [  0, 3,  4, undef ],
    [  0, 5,  5, 3 ],
    [  7, 1, 30, 3 ],
    [  8, 1, 30, 3 ],
    [  9, 1, 30, 3 ],
    [ 10, 1, 30, 4 ],
    [ 11, 1, 30, 4 ],
    [ 12, 1, 30, 4 ],
    [  0, 6,  6, 4 ],
) {
    my ( $month, $start, $finish, $want ) = @{ $spec };
    for ( my $day = $start; $day <= $finish; $day++ ) {
	my $title = $month ? "Month $month, day $day" : "Holiday $day";
	$title .= defined $want ?
	    " is quarter $want" :
	    ' is not part of any quarter';
	is( __quarter( $month, $day ), $want, $title );
    }
}

1;

# ex: set textwidth=72 :
