package Date::Tolkien::Shire::Data;

use 5.006002;

use strict;
use warnings;

use Carp ();
use POSIX ();
use Text::Abbrev();

# We can't use 'use Exporter qw{ import }' because we need to run under
# Perl 5.6.2, and since as I write this the Perl porters are working on
# a security flaw in 'use base', I'm doing a Paleolithic subclass.
use Exporter ();
our @ISA = qw{ Exporter };

our $VERSION = '0.000_006';

our @EXPORT_OK = qw{
    __date_to_day_of_year
    __day_of_year_to_date
    __day_of_week
    __format
    __is_leap_year
    __holiday_name __holiday_name_to_number __holiday_short
    __month_name __month_name_to_number __month_short
    __on_date
    __on_date_accented
    __quarter
    __rata_die_to_year_day
    __trad_weekday_name __trad_weekday_short
    __weekday_name __weekday_short
    __week_of_year
    __year_day_to_rata_die
    GREGORIAN_RATA_DIE_TO_SHIRE
};
our %EXPORT_TAGS = (
    all	=> \@EXPORT_OK,
);

use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};

use constant MIDYEAR_DAY_OF_YEAR	=> 183;
use constant OVERLITHE_DAY_NUMBER	=> 4;
use constant OVERLITHE_DAY_OF_YEAR	=> 184;

# See the documentation below for where the value came from.

use constant GREGORIAN_RATA_DIE_TO_SHIRE	=> 1995694;

{

    my @holiday = ( undef, 1, 7, 0, 0, 1, 7 );
    my @month_zero = ( undef, 0, 2, 4, 6, 1, 3, 0, 2, 4, 6, 1, 3 );

    sub __day_of_week {
	my ( $month, $day ) = @_;
	$month
	    or return $holiday[$day];
	return ( $month_zero[$month] + $day ) % 7 + 1;
    }
}

{
    my @holiday_day = ( undef, 1, 182, 183, OVERLITHE_DAY_OF_YEAR, 185, 366 );
    my @month_zero = ( undef, 1, 31, 61, 91, 121, 151, 185, 215, 245,
	275, 305, 335 );

    sub __date_to_day_of_year {
	my ( $year, $month, $day ) = @_;

	my $yd = $month ? $month_zero[$month] + $day :
	$holiday_day[$day];

	unless ( __is_leap_year( $year ) ) {
	    not $month
		and OVERLITHE_DAY_NUMBER == $day
		and Carp::croak( 'Overlithe only occurs in a leap year' );
	    $yd >= OVERLITHE_DAY_OF_YEAR
		and --$yd;
	}
	return $yd;
    }

    sub __day_of_year_to_date {
	my ( $year, $yd ) = @_;

	unless ( __is_leap_year( $year ) ) {
	    $yd >= OVERLITHE_DAY_OF_YEAR
		and $yd++;
	}
	$yd > 0
	    and $yd <= 366
	    or Carp::croak( "Invalid year day $yd" );

	for ( my $day = 1; $day < @holiday_day; $day++ ) {
	    $yd == $holiday_day[$day]
		and return ( 0, $day );
	}

	$yd -= 2;
	$yd > 180
	    and $yd -= 4;
	my $day = $yd % 30;
	my $month = ( $yd - $day ) / 30;
	return ( $month + 1, $day + 1 );
    }
}

{
    use constant FORMAT_DATE_ERROR => 'Date must be object or hash';

    sub __format {
	my ( $date, $tplt ) = @_;

	my $ref = ref $date
	    or Carp::croak( FORMAT_DATE_ERROR );

	if ( HASH_REF eq $ref ) {
	    my %hash = %{ $date };
	    $date = bless \%hash, join '::', __PACKAGE__, 'Date';
	}

	{
	    local $@ = undef;
	    eval {
		$date->can( 'isa' );
		1;
	    } or Carp::croak( FORMAT_DATE_ERROR );
	}

	$tplt =~ s/ % (?: [{]  ( \w+ ) [}]	# method ($1)
	    | [{]{2} ( .*? ) [}]{2}		# condition ($2)
	    | ( [0-9]+ ) N			# %nnnN ($3)
	    | ( [EO]? . )			# conv spec ($4)
	) /
	    $1 ? ( $date->can( $1 ) ? $date->$1() : "%{$1}" ) :
	    $2 ? _fmt_cond( $date, $2 ) :
	    $4 ? _fmt_conv( $date, $4 ) :
	    _fmt_nano( $date, $3 )
	/smxeg;

	return $tplt;
    }
}

sub _fmt_cond {
    my ( $date, $tplt ) = @_;
    my @cond = split qr< [|]{2} >smx, $tplt;
    foreach my $inx ( 1, 2 ) {
	defined $cond[$inx]
	    and '' ne $cond[$inx]
	    or $cond[$inx] = undef;
    }

    my $inx = 0;
    defined $cond[1]
	and not $date->month()
	and $inx = 1;
    defined $cond[2]
	and not __day_of_week( _fmt_get_md( $date ) )
	and $inx = 2;

    return __format( $date, $cond[$inx] );
}

sub _fmt_get_md {
    my ( $date ) = @_;
    my $month = $date->month() || 0;
    my $day = $month ? $date->day() : $date->holiday();
    return ( $month, $day );
}

{
    my %spec = (
	A	=> sub { __weekday_name( $_[0]->day_of_week() ) },
	a	=> sub { __weekday_short( $_[0]->day_of_week() ) },
	B	=> sub { __month_name( $_[0]->month() ) },
	b	=> sub { __month_short( $_[0]->month() ) },
	C	=> sub { sprintf '%02d', int( $_[0]->year() / 100 ) },
	c	=> sub { __format( $_[0], '%{{%a %x||||%x}} %X' ) },
	D	=> sub { __format( $_[0], '%{{%m/%d||%Ee}}/%y' ) },
	d	=> sub { sprintf '%02d', $_[0]->day() || $_[0]->holiday() },
	EA	=> sub { __trad_weekday_name( $_[0]->day_of_week() ) },
	Ea	=> sub { __trad_weekday_short( $_[0]->day_of_week() ) },
	ED	=> sub {
	    my $d = __on_date( _fmt_get_md( $_[0] ) );
	    defined $d
		and $d = "\n$d";
	    return $d;
	},
	Ed	=> sub { __on_date( _fmt_get_md( $_[0] ) ) },
	EE	=> sub { __holiday_name( $_[0]->holiday() || 0 ) },
	Ee	=> sub { __holiday_short( $_[0]->holiday() || 0 ) },
	Ex	=> sub { __format( $_[0],
		'%{{%A %e %B %Y||%A %EE %Y||%EE %Y}}' ) },
	e	=> sub { sprintf '%2d', $_[0]->day() || $_[0]->holiday() },
	F	=> sub { __format( $_[0], '%Y-%{{%m-%d||%Ee}}' ) },
#	G	Same as Y by definition of Shire calendar
	H	=> sub { sprintf '%02d', $_[0]->hour() || 0 },
#	h	Same as b by definition of strftime()
	I	=> sub { sprintf '%02d', ( $_[0]->hour() || 0 ) % 12 || 12 },
	j	=> sub { sprintf '%03d', __date_to_day_of_year(
		$_[0]->year(), _fmt_get_md( $_[0] ) ) },
	k	=> sub { sprintf '%2d', $_[0]->hour() || 0 },
	l	=> sub { sprintf '%2d', ( $_[0]->hour() || 0 ) % 12 || 12 },
	M	=> sub { sprintf '%02d', $_[0]->minute() || 0 },
	m	=> sub { sprintf '%02d', $_[0]->month() || 0 },
	N	=> \&_fmt_nano,
	n	=> sub { "\n" },
	P	=> sub { ( $_[0]->hour() || 0 ) > 11 ? 'pm' : 'am' },
	p	=> sub { ( $_[0]->hour() || 0 ) > 11 ? 'PM' : 'AM' },
	R	=> sub { __format( $_[0], '%H:%M' ) },
	r	=> sub { __format( $_[0], '%I:%M:%S %p' ) },
	S	=> sub { sprintf '%02s', $_[0]->second() || 0 },
	s	=> sub { $_[0]->epoch() },
	T	=> sub { __format( $_[0], '%H:%M:%S' ) },
	t	=> sub { "\t" },
	U	=> sub { sprintf '%02d', __week_of_year(
		_fmt_get_md( $_[0] ) ) },
	u	=> sub { $_[0]->day_of_week() },
#	V	Same as U by definition of Shire calendar
#	W	Same as U by definition of Shire calendar
#	X	Same as r, I think
	x	=> sub { __format( $_[0], '%{{%e %b %Y||%Ee %Y}}' ) }, 
	Y	=> sub { $_[0]->year() },
	y	=> sub { sprintf '%02d', $_[0]->year() % 100 },
	Z	=> sub { $_[0]->time_zone_short_name() },
	z	=> sub { _fmt_offset( $_[0]->offset() ) },
    );
    $spec{G} = $spec{Y};	# By definition of Shire calendar.
    $spec{h} = $spec{b};	# By definition of strftime().
    $spec{V} = $spec{U};	# By definition of Shire calendar.
    $spec{W} = $spec{U};	# By definition of Shire calendar.
    $spec{w} = $spec{u};	# Because the strftime() definition of
				# %w makes no sense to me in terms of
				# the Shire calendar.
    $spec{X} = $spec{r};	# I think this is right ...

    sub _fmt_conv {
	my ( $date, $rslt ) = @_;
	my $code;
	if ( $code = $spec{$rslt} ) {
	    $rslt = $code->( $date );
	} elsif ( 1 < length $rslt and $code = $spec{ substr $rslt, 1 } ) {
	    $rslt = $code->( $date );
	}
	return defined $rslt ? $rslt : '';
    }
}

sub _fmt_offset {
    my ( $offset ) = @_;
    defined $offset
	and $offset =~ m/ \A [+-]? [0-9]+ \z /smx
	or return '';
    my $sign = $offset < 0 ? '-' : '+';
    $offset = abs $offset;
    my $sec = $offset % 60;
    $offset = POSIX::floor( ( $offset - $sec ) / 60 );
    my $min = $offset % 60;
    my $hr = POSIX::floor( ( $offset - $min ) / 60 );
    return $sec ?
	sprintf( '%s%02d%02d%02d', $sign, $hr, $min, $sec ) :
	sprintf( '%s%02d%02d', $sign, $hr, $min );
}

sub _fmt_nano {
    my ( $date, $places ) = @_;
    $places ||= 9;
    return substr sprintf( '%09u', $date->nanosecond() || 0 ), 0, $places;
}

{
    my @name = ( '',
	'2 Yule', '1 Lithe', q<Midyear's day>, 'Overlithe', '2 Lithe',
	'1 Yule',
    );

    sub __holiday_name {
	my ( $holiday ) = @_;
	return $name[ $holiday || 0 ];
    }

    my $lookup = _make_lookup_hash( @name, 'myd', 'olithe' );
    my @map = ( 0 .. 6, 3, 4 );
    foreach ( values %{ $lookup } ) {
	$_ = $map[$_];
    }
    $lookup->{m} = 3;
    $lookup->{o} = 4;

    sub __holiday_name_to_number {
	my ( $holiday ) = _normalize_for_lookup( @_ );
	$holiday =~ m/ \A [0-9]+ \z /smx
	    and return $holiday;
	return $lookup->{$holiday} || 0;
    }
}

{
    my @name = ( '',
	'2Yu', '1Li', 'Myd', 'Oli', '2Li', '1Yu',
    );

    sub __holiday_short {
	my ( $holiday ) = @_;
	return $name[ $holiday || 0 ];
    }
}

sub __is_leap_year {
    my ( $year ) = @_;
    return $year % 4 ? 0 : $year % 100 ? 1 : $year % 400 ? 0 : 1;
}

{
    my @name = ( '',
	'Afteryule', 'Solmath', 'Rethe', 'Astron', 'Thrimidge',
	'Forelithe', 'Afterlithe', 'Wedmath', 'Halimath', 'Winterfilth',
	'Blotmath', 'Foreyule',
    );

    sub __month_name {
	my ( $month ) = @_;
	return $name[ $month || 0 ];
    }

    my $lookup = _make_lookup_hash( @name, qw{ ayule flithe alithe fyule
	} );
    my @map = ( 0 .. 12, 1, 6, 7, 12 );
    foreach ( values %{ $lookup } ) {
	$_ = $map[$_];
    }

    sub __month_name_to_number {
	my ( $month ) = _normalize_for_lookup( @_ );
	$month =~ m/ \A [0-9]+ \z /smx
	    and return $month;
	return $lookup->{$month} || 0;
    }
}

{
    my @name = ( '', 'Ayu', 'Sol', 'Ret', 'Ast', 'Thr', 'Fli', 'Ali',
	'Wed', 'Hal', 'Win', 'Blo', 'Fyu' );

    sub __month_short {
	my ( $month ) = @_;
	return $name[ $month || 0 ];
    }
}

{
    my @on_date;

    $on_date[0][3]   = "Wedding of King Elessar and Arwen, 1419.\n";

    $on_date[1][8]   = "The Company of the Ring reaches Hollin, 1419.\n";
    $on_date[1][13]  = "The Company of the Ring reaches the West-gate of Moria at nightfall, 1419.\n";
    $on_date[1][14]  = "The Company of the Ring spends the night in Moria hall 21, 1419.\n";
    $on_date[1][15]  = "The Bridge of Khazad-dum, and the fall of Gandalf, 1419.\n";
    $on_date[1][17]  = "The Company of the Ring comes to Caras Galadhon at evening, 1419.\n";
    $on_date[1][23]  = "Gandalf pursues the Balrog to the peak of Zirakzigil, 1419.\n";
    $on_date[1][25]  = "Gandalf casts down the Balrog, and passes away.\n" .
		       "His body lies on the peak of Zirakzigil, 1419.\n";

    $on_date[2][14]  = "Frodo and Sam look in the Mirror of Galadriel, 1419.\n" .
		       "Gandalf returns to life, and lies in a trance, 1419.\n";
    $on_date[2][16]  = "Company of the Ring says farewell to Lorien --\n" .
		       "Gollum observes departure, 1419.\n";
    $on_date[2][17]  = "Gwaihir the eagle bears Gandalf to Lorien, 1419.\n";
    $on_date[2][25]  = "The Company of the Ring pass the Argonath and camp at Parth Galen, 1419.\n" .
		       "First battle of the Fords of Isen -- Theodred son of Theoden slain, 1419.\n";
    $on_date[2][26]  = "Breaking of the Fellowship, 1419.\n" .
		       "Death of Boromir; his horn is heard in Minas Tirith, 1419.\n" .
		       "Meriadoc and Peregrin captured by Orcs -- Aragorn pursues, 1419.\n" .
		       "Eomer hears of the descent of the Orc-band from Emyn Muil, 1419.\n" .
		       "Frodo and Samwise enter the eastern Emyn Muil, 1419.\n";
    $on_date[2][27]  = "Aragorn reaches the west-cliff at sunrise, 1419.\n" .
		       "Eomer sets out from Eastfold against Theoden's orders to pursue the Orcs, 1419.\n";
    $on_date[2][28]  = "Eomer overtakes the Orcs just outside of Fangorn Forest, 1419.\n";
    $on_date[2][29]  = "Meriodoc and Pippin escape and meet Treebeard, 1419.\n" .
		       "The Rohirrim attack at sunrise and destroy the Orcs, 1419.\n" .
		       "Frodo descends from the Emyn Muil and meets Gollum, 1419.\n" .
		       "Faramir sees the funeral boat of Boromir, 1419.\n";
    $on_date[2][30]  = "Entmoot begins, 1419.\n" .
		       "Eomer, returning to Edoras, meets Aragorn, 1419.\n";

    $on_date[3][1]   = "Aragorn meets Gandalf the White, and they set out for Edoras, 1419.\n" .
		       "Faramir leaves Minas Tirith on an errand to Ithilien, 1419.\n";
    $on_date[3][2]   = "The Rohirrim ride west against Saruman, 1419.\n" .
		       "Second battle at the Fords of Isen; Erkenbrand defeated, 1419.\n" .
		       "Entmoot ends.  Ents march on Isengard and reach it at night, 1419.\n";
    $on_date[3][3]   = "Theoden retreats to Helm's Deep; battle of the Hornburg begins, 1419.\n" .
		       "Ents complete the destruction of Isengard.\n";
    $on_date[3][4]   = "Theoden and Gandalf set out from Helm's Deep for Isengard, 1419.\n" .
		       "Frodo reaches the slag mound on the edge of the of the Morannon, 1419.\n";
    $on_date[3][5]   = "Theoden reaches Isengard at noon; parley with Saruman in Orthanc, 1419.\n" .
		       "Gandalf sets out with Peregrin for Minas Tirith, 1419.\n";
    $on_date[3][6]   = "Aragorn overtaken by the Dunedain in the early hours, 1419.\n";
    $on_date[3][7]   = "Frodo taken by Faramir to Henneth Annun, 1419.\n" .
		       "Aragorn comes to Dunharrow at nightfall, 1419.\n";
    $on_date[3][8]   = "Aragorn takes the \"Paths of the Dead\", and reaches Erech at midnight, 1419.\n" .
		       "Frodo leaves Henneth Annun, 1419.\n";
    $on_date[3][9]   = "Gandalf reaches Minas Tirith, 1419.\n" .
		       "Darkness begins to flow out of Mordor, 1419.\n";
    $on_date[3][10]  = "The Dawnless Day, 1419.\n" .
		       "The Rohirrim are mustered and ride from Harrowdale, 1419.\n" .
		       "Faramir rescued by Gandalf at the gates of Minas Tirith, 1419.\n" .
		       "An army from the Morannon takes Cair Andros and passes into Anorien, 1419.\n";
    $on_date[3][11]  = "Gollum visits Shelob, 1419.\n" .
		       "Denethor sends Faramir to Osgiliath, 1419.\n" .
		       "Eastern Rohan is invaded and Lorien assaulted, 1419.\n";
    $on_date[3][12]  = "Gollum leads Frodo into Shelob's lair, 1419.\n" .
		       "Ents defeat the invaders of Rohan, 1419.\n";
    $on_date[3][13]  = "Frodo captured by the Orcs of Cirith Ungol, 1419.\n" .
		       "The Pelennor is overrun and Faramir is wounded, 1419.\n" .
		       "Aragorn reaches Pelargir and captures the fleet of Umbar, 1419.\n";
    $on_date[3][14]  = "Samwise finds Frodo in the tower of Cirith Ungol, 1419.\n" .
		       "Minas Tirith besieged, 1419.\n";
    $on_date[3][15]  = "Witch King breaks the gates of Minas Tirith, 1419.\n" .
		       "Denethor, Steward of Gondor, burns himself on a pyre, 1419.\n" .
		       "The battle of the Pelennor occurs as Theoden and Aragorn arrive, 1419.\n" .
		       "Thranduil repels the forces of Dol Guldur in Mirkwood, 1419.\n" .
		       "Lorien assaulted for second time, 1419.\n";
    $on_date[3][17]  = "Battle of Dale, where King Brand and King Dain Ironfoot fall, 1419.\n" .
		       "Shagrat brings Frodo's cloak, mail-shirt, and sword to Barad-dur, 1419.\n";
    $on_date[3][18]  = "Host of the west leaves Minas Tirith, 1419.\n" .
		       "Frodo and Sam overtaken by Orcs on the road from Durthang to Udun, 1419.\n";
    $on_date[3][19]  = "Frodo and Sam escape the Orcs and start on the road toward Mount Doom, 1419.\n";
    $on_date[3][22]  = "Lorien assaulted for the third time, 1419.\n";
    $on_date[3][24]  = "Frodo and Sam reach the base of Mount Doom, 1419.\n";
    $on_date[3][25]  = "Battle of the Host of the West on the slag hill of the Morannon, 1419.\n" .
		       "Gollum siezes the Ring of Power and falls into the Cracks of Doom, 1419.\n" .
		       "Downfall of Barad-dur and the passing of Sauron!, 1419.\n" .
		       "Birth of Elanor the Fair, daughter of Samwise, 1421.\n" .
		       "Fourth age begins in the reckoning of Gondor, 1421.\n";
    $on_date[3][27]  = "Bard II and Thorin III Stonehelm drive the enemy from Dale, 1419.\n";
    $on_date[3][28]  = "Celeborn crosses the Anduin and begins destruction of Dol Guldur, 1419.\n";

    $on_date[4][6]   = "The mallorn tree flowers in the party field, 1420.\n";
    $on_date[4][8]   = "Ring bearers are honored on the fields of Cormallen, 1419.\n";
    $on_date[4][12]  = "Gandalf arrives in Hobbiton, 1418\n";

    $on_date[5][1]   = "Crowning of King Elessar, 1419.\n" .
		       "Samwise marries Rose, 1420.\n";

    $on_date[6][20]  = "Sauron attacks Osgiliath, 1418.\n" .
		       "Thranduil is attacked, and Gollum escapes, 1418.\n";

    $on_date[7][4]   = "Boromir sets out from Minas Tirith, 1418\n";
    $on_date[7][10]  = "Gandalf imprisoned in Orthanc, 1418\n";
    $on_date[7][19]  = "Funeral Escort of King Theoden leaves Minas Tirith, 1419.\n";

    $on_date[8][10]  = "Funeral of King Theoden, 1419.\n";

    $on_date[9][18]  = "Gandalf escapes from Orthanc in the early hours, 1418.\n";
    $on_date[9][19]  = "Gandalf comes to Edoras as a beggar, and is refused admittance, 1418\n";
    $on_date[9][20]  = "Gandalf gains entrance to Edoras.  Theoden commands him to go:\n" .
		       "\"Take any horse, only be gone ere tomorrow is old\", 1418.\n";
    $on_date[9][21]  = "The hobbits return to Rivendell, 1419.\n";
    $on_date[9][22]  = "Birthday of Bilbo and Frodo.\n" .
		       "The Black Riders reach Sarn Ford at evening;\n" .
		       "  they drive off the guard of Rangers, 1418.\n" .
		       "Saruman comes to the Shire, 1419.\n";
    $on_date[9][23]  = "Four Black Riders enter the shire before dawn.  The others pursue \n" .
		       "the Rangers eastward and then return to watch the Greenway, 1418.\n" .
		       "A Black Rider comes to Hobbiton at nightfall, 1418.\n" .
		       "Frodo leaves Bag End, 1418.\n" .
		       "Gandalf having tamed Shadowfax rides from Rohan, 1418.\n";
    $on_date[9][26]  = "Frodo comes to Bombadil, 1418\n";
    $on_date[9][28]  = "The Hobbits are captured by a barrow-wight, 1418.\n";
    $on_date[9][29]  = "Frodo reaches Bree at night, 1418.\n" .
		       "Frodo and Bilbo depart over the sea with the three Keepers, 1421.\n" .
		       "End of the Third Age, 1421.\n";
    $on_date[9][30]  = "Crickhollow and the inn at Bree are raided in the early hours, 1418.\n" .
		       "Frodo leaves Bree, 1418.\n";

    $on_date[10][3]  = "Gandalf attacked at night on Weathertop, 1418.\n";
    $on_date[10][5]  = "Gandalf and the Hobbits leave Rivendell, 1419.\n";
    $on_date[10][6]  = "The camp under Weathertop is attacked at night and Frodo is wounded, 1418.\n";
    $on_date[10][11] = "Glorfindel drives the Black Riders off the Bridge of Mitheithel, 1418.\n";
    $on_date[10][13] = "Frodo crosses the Bridge of Mitheithel, 1418.\n";
    $on_date[10][18] = "Glorfindel finds Frodo at dusk, 1418.\n" .
		       "Gandalf reaches Rivendell, 1418.\n";
    $on_date[10][20] = "Escape across the Ford of Bruinen, 1418.\n";
    $on_date[10][24] = "Frodo recovers and wakes, 1418.\n" .
		       "Boromir arrives at Rivendell at night, 1418.\n";
    $on_date[10][25] = "Council of Elrond, 1418.\n";
    $on_date[10][30] = "The four Hobbits arrive at the Brandywine Bridge in the dark, 1419.\n";

    $on_date[11][3]  = "Battle of Bywater and passing of Saruman, 1419.\n" .
		       "End of the War of the Ring, 1419.\n";

    $on_date[12][25] = "The Company of the Ring leaves Rivendell at dusk, 1418.\n";


    sub __on_date {
	my ( $month, $day ) = @_;
	return $on_date[ $month][$day];
    }
}

{
    my @holiday_quarter = ( undef, 1, 2, 0, 0, 3, 4 );

    sub __quarter {
	my ( $month, $day ) = @_;
	return $month ?
	    POSIX::floor( ( $month - 1 ) / 3 ) + 1 :
	    $holiday_quarter[$day];
    }
}

# TODO In a leap year, day 366 is assigned to the wrong year.
sub __rata_die_to_year_day {
    my ( $rata_die ) = @_;

    --$rata_die;	# The algorithm is simpler with zero-based days.
    my $cycle = POSIX::floor( $rata_die / 146097 );
    my $day_of_cycle = $rata_die - $cycle * 146097;
    my $year = POSIX::floor( ( $day_of_cycle -
	    POSIX::floor( $day_of_cycle / 1460 ) +
	    POSIX::floor( $day_of_cycle / 36524 ) -
	    POSIX::floor( $day_of_cycle / 146096 ) ) / 365 ) +
	    400 * $cycle + 1;
    # We pay here for the zero-based day by having to add back 2 rather
    # than 1.
    my $year_day = $rata_die - __year_day_to_rata_die( $year ) + 2;
    return ( $year, $year_day );
}

{
    my @name = ( '', 'Sterrendei', 'Sunnendei', 'Monendei',
	'Trewesdei', 'Hevenesdei', 'Meresdei', 'Highdei' );

    sub __trad_weekday_name {
	my ( $weekday ) = @_;
	return $name[ $weekday || 0 ];
    }
}

{
    my @name = ( '', 'Ste', 'Sun', 'Mon', 'Tre', 'Hev', 'Mer', 'Hig' );

    sub __trad_weekday_short {
	my ( $weekday ) = @_;
	return $name[ $weekday || 0 ];
    }
}

{
    my @holiday = ( undef, 1, 26, 0, 0, 27, 52 );
    my @month_offset = ( undef, ( 0 ) x 6, ( 2 ) x 6 );

    sub __week_of_year {
	my ( $month, $day ) = @_;
	$month
	    or return $holiday[$day];
	return int( (
		( $month - 1 ) * 30 + $month_offset[$month] + $day
	    ) / 7 ) + 1;
    }
}

{
    my @name = ( '', 'Sterday', 'Sunday', 'Monday', 'Trewsday',
	'Hevensday', 'Mersday', 'Highday' );

    sub __weekday_name {
	my ( $weekday ) = @_;
	return $name[ $weekday || 0 ];
    }
}

{
    my @name = ( '', 'Ste', 'Sun', 'Mon', 'Tre', 'Hev', 'Mer', 'Hig' );

    sub __weekday_short {
	my ( $weekday ) = @_;
	return $name[ $weekday || 0 ];
    }
}

sub __year_day_to_rata_die {
    my ( $year, $day ) = @_;
    --$year;
    $day ||= 1;
    return $year * 365 + POSIX::floor( $year / 4 ) -
	POSIX::floor( $year / 100 ) + POSIX::floor( $year / 400 ) +
	$day;
}

sub _normalize_for_lookup {
    my @data = @_;
    foreach ( @data ) {
	( $_ = lc $_ ) =~ s/ [\s[:punct:]]+ //smxg;
    }
    return @data;
}

sub _make_lookup_hash {
    my @data = _normalize_for_lookup( @_ );
    my %index;
    for ( my $inx = 0; $inx < @data; $inx++ ) {
	$index{$data[$inx]} = $inx;
    }
    my %hash = Text::Abbrev::abbrev( @data );
    delete $hash{ '' };
    foreach ( values %hash ) {
	$_ = $index{$_};
    }
    return wantarray ? %hash : \%hash;
}

# Create methods for the hash wrapper

{
    my %calc = (
	day_of_week	=> sub {
	    return __day_of_week(
		$_[0]->month(),
		$_[0]->day() || $_[0]->holiday(),
	    );
	},
    );

    foreach my $method ( qw{
	year month day holiday hour minute second nanosecond
	epoch offset time_zone_short_name day_of_week
    } ) {
	my $fqn = join '::', __PACKAGE__, 'Date', $method;
	if ( my $code = $calc{$method} ) {
	    no strict qw{ refs };
	    *$fqn = sub {
		defined $_[0]->{$method}
		    or $_[0]->{$method} = $code->( $_[0] );
		return $_[0]->{$method};
	    };
	} else {
	    no strict qw{ refs };
	    *$fqn = sub { $_[0]->{$method} };
	}
    }
}

1;

__END__

=head1 NAME

Date::Tolkien::Shire::Data - Data functionality for Shire calendars.

=head1 SYNOPSIS

 use Date::Tolkien::Shire::Data;
 
 say __on_date( 1, 2 ) // "Nothing happened\n";

=head1 DESCRIPTION

This Perl module carries common functionality for implementations of the
Shire calendar as described in Appendix D of J. R. R. Tolkien's novel
"Lord Of The Rings". What it really contains is anything that was common
to L<Date::Tolkien::Shire|Date::Tolkien::Shire> and
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
and I felt like factoring out.

The Shire calendar has 12 months of 30 days each, plus 5 holidays (6 in
a leap year) that are not part of any month. Two of these holidays
(Midyear's day and the Overlithe) are also part of no week.

In all of the following, years are counted from the founding of the
Shire. Months are numbered C<1-12>, and days in months from C<1-30>.
Holidays are specified by giving a month of C<0> and the holiday number,
as follows:

=over

=item 1 - 2 Yule

=item 2 - 1 Lithe

=item 3 - Midyear's day

=item 4 - Overlithe (which occurs in leap years only)

=item 5 - 2 Lithe (so numbered even in non-leap years)

=item 6 - 1 Yule

=back

=head1 SUBROUTINES

This class supports the following public subroutines. Anything
documented below is public unless its documentation explicitly states
otherwise. The names begin with double underscores because it is
anticipated that, although they are public as far as this package is
concerned, they will be package-private for the purposes of any code
that uses this package.

All of the following are exportable to your name space, but none are
exported by default.

=head2 __date_to_day_of_year

 say __date_to_day_of_year( 1420, 3, 25 );

This subroutine takes as input a year, month, and day and returns the
day number in the year. An exception will be thrown if you specify the
Overlithe ("month" 0, day 4) and it is not a leap year.

=head2 __day_of_week

 say '3 Astron is day ', __day_of_week( 4, 3 );

Given a month number and day number in the month, computes the day of
the week that day falls on, as a number from 1 to 7, 1 being C<Sterday>.
If the day is Midyear's day or the Overlithe (month C<0>, days C<3> or
C<4>) the result is C<0>.

=head2 __day_of_year_to_date

 my ( $month, $day ) = __day_of_year_to_date( 1419, 182 );

Given a year and a day number in the year (from 1), compute the month
and day of month. An exception will be thrown unless the day number is
between C<1> and C<365>, or C<366> in a leap year.

=head2 __format

 say __format( $date, '%c' );

This method formats a date, in a manner similar to C<strftime()>. The
C<$date> is either an object that supports the necessary methods, or a
reference to a hash having the necessary keys (same as the
methods). The methods (or keys) used are:

  year
  month
  day
  holiday
  hour
  minute
  second
  day_of_week
  nanosecond
  epoch
  offset
  time_zone_short_name

The first seven are heavily used. The last four are used only by
C<'%N'>, C<'%s'>, C<'%z'>, and C<'%Z'> respectively.

The following conversion specifications (to use C<strftime()>
terminology) or patterns (to use L<DateTime|DateTime> terminology) are
supported. Note that these have been extended by the use of C<'%E*'>
patterns, which generally represent holidays. E-prefixed patterns not
defined below are (consistent with C<strftime()>) implemented as if the
C<'E'> were not present, but this use is discouraged because additional
E-prefixed (or O-prefixed, which C<strftime()> also allows) patterns may
prove to be necessary.

=over

=item %A

The full weekday name, or C<''> for holidays that are part of no week.

=item %a

The abbreviated weekday name, or C<''> for holidays that are part of no
week.

=item %B

The full month name, or C<''> for holidays.

=item %b

The abbreviated month name, or C<''> for holidays.

=item %C

The century number (year/100) as a 2-digit integer.

=item %c

For normal days this is the abbreviated weekday name (C<'%a'>), the day
number (C<'%e'>), the abbreviated month name (C<%b>), and the full year
(C<'%Y'>), followed by the time of day.

For holidays the abbreviated holiday name (C<'%Ee'>) replaces the day
and month, and the weekday name is omitted if the holiday is part of no
week. So (assuming times for all events):

 Sun 25 Ret 1419  3:00:00 PM # Ring destroyed
 Myd 1419 12:00:OO PM        # Wedding of Aragorn and Arwen

=item %D

The equivalent of C<'%m/%d/%y'>, or C<'%Ee/%y'> on holidays. This format
is discouraged, because it may not be clear whether it is month/day/year
(as the United States does it) or day/month/year (as Europe does it).

=item %d

The day of the month as a decimal number, zero-filled (range C<01> to
C<30>). On holidays it is the holiday number, zero-filled (range C<01>
to C<06>).

=item %EA

The full traditional weekday name, or C<''> for holidays that are part
of no week.

=item %Ea

The abbreviated traditional weekday name, or C<''> for holidays that are
part of no week.

=item %ED

The L<__on_date()|/__on_date> text for the given date, with a leading
"\n" if there is in fact an event on that date. This makes '%Ex%n%ED'
produce exactly the same text as L<__on_date()|/__on_date>.

=item %Ed

The L<__on_date()|/__on_date> text for the given date.

=item %EE

The full holiday name, or C<''> for non-holidays.

=item %Ee

The abbreviated holiday name, or C<''> for non-holidays.

=item %Ex

Like C<'%c'>, but without the time of day, and with full names rather
than abbreviations.

=item %e

The day of the month as a decimal number, space-filled (range C<' 1'> to
C<'30'>). On holidays it is the holiday number, space-filled (range
C<' 1'> to C<' 6'>).

=item %F

For normal dates this is equivalent to C<'%Y-%m-%d'> (i.e. the ISO 8601
date format). For holidays it is equivalent to C<'%Y-%Er'>, which is
something ISO had nothing to do with.

=item %G

The ISO 8601 year number. Given how the Shire calendar is defined, the
ISO year number is the same as the calendar year (i.e. C<'%Y'>).

=item %H

The hour, zero-filled, in the range C<'00'> to C<'23'>.

=item %h

Equivalent to C<'%b'>.

=item %I

The hour, zero-filled, in the range C<'01'> to C<'12'>.

=item %j

The day of the year, zero-filled, in the range C<'001'> to C<'366'>.

=item %k

The hour, blank-filed, in the range C<' 0'> to C<'23'>.

=item %l

The hour, blank-filled, in the range C<' 1'> to C<'12'>.

=item %M

The minute, zero-filled, in the range C<'00'> to C<'59'>.

=item %m

The month number, zero filled, in the range C<'01'> to C<'12'>. On
holidays it is C<'00'>.

=item %N

The fractional seconds. A decimal digit may appear between the percent
sign and the C<'N'> to specify the precision: C<'3'> gives milliseconds,
C<'6'> microseconds, and C<'9'> nanoseconds. The default is C<'9'>.

=item %n

A newline character.

=item %P

The meridian indicator, C<'am'> or C<'pm'>.

=item %p

The meridian indicator, C<'AM'> or C<'PM'>.

=item %R

The time in hours and minutes, on a 24-hour clock. Equivalent to
C<'%H:%M'>.

=item %r

The time in hours, minutes and seconds on a 12-hour clock. Equivalent
to C<'%I:%M:%S %p'>.

=item %S

The second, zero-filled, in the range C<'00'> to C<'61'>, though only to
C<'59'> unless you are dealing with times when the leap second has been
invented.

=item %s

The number of seconds since the epoch.

=item %T

The time in hours, minutes and seconds on a 24-hour clock. Equivalent to
C<'%H:%M:%S'>.

=item %t

A tab character.

=item %U

The week number in the current year, zero-filled, in the range C<'01'>
to C<'52'>, or C<''> if the day is not part of a week.

=item %u

The day of the week, as a number in the range C<'1'> to C<'7'>, or C<''>
if the day is not part of a week.

=item %V

I have made this the same as C<'%U'>, because all Shire years start on
the same day of the week, and I do not think the hobbits would
understand or condone the idea of different starting days to a week.

=item %W

I have made this the same as C<'%U'>. For my reasoning, see above under
C<'%V'>.

=item %w

I have made this the same as C<'%u'>, my argument being similar to the
argument for making C<'%V'> the same as C<'%U'>.

=item %X

I have made this the same as C<'%r'>. We know the hobbits had clocks,
because in "The Hobbit" Thorin Oakenshield left Bilbo Baggins a note
under the clock on the mantelpiece. We know they spoke of time as
"o'clock" because in the chapter "Of Herbs and Stewed Rabbit" in "The
Lord Of The Rings", Sam Gamgee speaks of the time as being nine o'clock.
But this was in the morning, and we have no evidence that I know of
whether mid-afternoon would be three o'clock or fifteen o'clock. But my
feeling is for the former. If I get evidence to the contrary this
implementation will change.

=item %x

I have made this day, abbreviated month, and full year. Holidays are
abbreviated holiday name and year.

=item %Y

The year number.

=item %y

Year of century, zero filled, in the range C<'00'> to C<'99'>.

=item %Z

The time zone abbreviation.

=item %z

The time zone offset.

=item %%

A literal percent sign.

=item %{method_name}

Any method actually implemented by the C<$date> object can be specified.
This method will be called without arguments and its results replace the
conversion specification. If the method does not exist, the pattern is
left as-is.

=item %{{format||format||format}}

The formatter chooses the first format for normal days (i.e. part of a
month), the second for holidays that are part of a week (i.e. 2 Yule, 1
Lithe, 2 Lithe and 1 Yule), or the third for holidays that are not part
of a week (i.e. Midyear's day and the Overlithe). If the second or third
formats are omitted, the preceding format is used. Trailing C<||>
operators can also be omitted. If you need to specify more than one
right curly bracket or vertical bar as part of a format, separate them
with percent signs (i.e. C<'|%|%|'>.

=back

=head2 __holiday_name

 say __holiday_name( 3 );

Given a holiday number C<(1-6)>, this subroutine returns that holiday's
name. If the holiday number is C<0> (i.e. the day is not a holiday), an
empty string is returned. Otherwise, C<undef> is returned.

=head2 __holiday_name_to_number

 say __holiday_name_to_number( 'overlithe' );

Given a holiday name, this subroutine normalizes it by converting it to
lower case and removing spaces and punctuation, and then returns the
number of the holiday. Unique abbreviations of names or short names
(a.k,a. abbreviations) are allowed. Arguments consisting entirely of
digits are returned unmodified. Anything unrecognized causes C<0> to be
returned.

=head2 __holiday_short

 say __holiday_short( 3 );

Given a holiday number C<(1-6)>, this subroutine returns that holiday's
three-letter abbreviation. If the holiday number is C<0> (i.e. the day
is not a holiday), an empty string is returned. Otherwise, C<undef> is
returned.


=head2 __is_leap_year

 say __is_leap_year( 1420 );  # 1

Given a year number, this subroutine returns C<1> if it is a leap year
and C<0> if it is not.

=head2 __month_name

 say __month_name( 3 );

Given a month number C<(1-12)>, this subroutine returns that month's
name. If the month number is C<0> (i.e. a holiday), the empty string is
returned. Otherwise C<undef> is returned.

=head2 __month_name_to_number

 say __month_name_to_number( 'forelithe' );

Given a month name, this subroutine normalizes it by converting it to
lower case and removing spaces and punctuation, and then returns the
number of the month. Unique abbreviations of names or short names
(a.k,a. abbreviations) are allowed. Arguments consisting entirely of
digits are returned unmodified. Anything unrecognized causes C<0> to be
returned.

=head2 __month_short

 say __month_short( 3 );

Given a month number C<(1-12)>, this subroutine returns that month's
three-letter abbreviation. If the month number is C<0> (i.e. a holiday),
the empty string is returned. Otherwise C<undef> is returned.


=head2 __on_date

 say __on_date( $month, $day );

Given month and day numbers, returns text representing the events during
and around the War of the Ring that occurred on that date. If nothing
happened or any argument is out of range, C<undef> is returned.

The actual text returned is from Appendix B of "Lord Of The Rings", and
is copyright J. R. R. Tolkien, renewed by Christopher R. Tolkien et al.

=head2 __quarter

 say __quarter( $month, $day );

Given month and day numbers, returns the relevant quarter number. If the
date specified is Midyear's day or the Overlithe ("month" C<0>, days
C<3-4>), the result is C<0>; otherwise it is a number in the range
C<1-4>.

There is nothing I know of about hobbits using calendar quarters in
anything Tolkien wrote. But if they did use them I suspect they would be
rationalized this way.

=head2 __rata_die_to_year_day

 my ( $year, $day ) = __rata_die_to_year_day( $rata_die );

Given a Rata Die day, returns the year and day of the year corresponding
to that Rata Die day.

The algorithm used was inspired by Howard Hinnant's "C<chrono>-Compatible
Low-Level Date Algorithms" at
L<http://howardhinnant.github.io/date_algorithms.html>, and in
particular his C<civil_from_days()> algorithm at
L<http://howardhinnant.github.io/date_algorithms.html#civil_from_days>.

This subroutine assumes no particular calendar, though it does assume
the Gregorian year-length rules, which have also been adopted for the
Shire calendar. If you feed it am honest-to-God Rata Die day (i.e. days
since December 31 of proleptic Gregorian year 0) you get back the
Gregorian year and the day of that year (C<1-366>). If you feed it a
so-called Shire Rata Die (i.e. days since 1 Yule of Shire year 0) you
get back the Shire year and the day of that year.

=head2 __trad_weekday_name

 say 'Day 1 is ', __trad_weekday_name( 1 );

This subroutine computes the traditional (i.e. old-style) name of a
weekday given its number (1-7). If the weekday number is C<0> (i.e.
Midyear's day or the Overlithe) the empty string is returned. Otherwise,
C<undef> is returned.

=head2 __trad_weekday_short

 say 'Day 1 is ', __trad_weekday_short( 1 );

This subroutine computes the three-letter abbreviation of a traditional
(i.e. old-style) weekday given its number (1-7). If the weekday number
is C<0> (i.e.  Midyear's day or the Overlithe) the empty string is
returned. Otherwise, C<undef> is returned.


=head2 __weekday_name

 say 'Day 1 is ', __weekday_name( 1 );

This subroutine computes the name of a weekday given its number (1-7).
If the weekday number is C<0> (i.e. Midyear's day or the Overlithe) the
empty string is returned. Otherwise, C<undef> is returned.

=head2 __weekday_short

 say 'Day 1 is ', __weekday_short( 1 );

This subroutine computes the three-letter abbreviation of a weekday
given its number (1-7). If the weekday number is C<0> (i.e. Midyear's
day or the Overlithe) the empty string is returned. Otherwise, C<undef>
is returned.

=head2 __week_of_year

 say '25 Rethe is in week ', __week_of_year( 3, 25 );

This subroutine computes the week number of the given month and day.
Weeks start on Sterday, and the first week of the year is week 1. If the
date is part of no week (i.e. Midyear's day or the Overlithe), C<0> is
returned.

=head2 __year_day_to_rata_die

Given the year and day of the year, this subroutine returns the Rata Die
day of the given year and day. The day of the year defaults to C<1>.

This subroutine assumes no particular calendar, though it does assume
the Gregorian year-length rules, which have also been adopted for the
Shire calendar. If you feed it a Gregorian year, you get an
honest-to-God Rata Die, as in days since December 31 of proleptic
Gregorian year 0. If you feed it a Shire year, you get a so-called Shire
Rata Die, as in the days since 1 Yule of Shire year 0.

=head1 MANIFEST CONSTANTS

The following manifest constants are exportable to your name space. None
is exported by default.

=head2 GREGORIAN_RATA_DIE_TO_SHIRE

This manifest constant represents the number of days to add to a real
Rata Die value (days since December 31 of proleptic Gregorian year 0) to
get a so-called Shire Rata Die (days since 1 Yule of Shire year 0.)

The value was determined by the following computation.

  my $dts = DateTime::Fiction::JRRTolkien::Shire->new(
      year    => 1,
      holiday => 1,
  );
  my $gdt = DateTime->new(
      year    => 1,
      month   => 1,
      day     => 1,
  );
  my $rd_to_shire = ( $gdt->utc_rd_values() )[0] -
      ( $dts->utc_rd_values() )[0];

using
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
version 0.21. This is after I adopted that module but before I started
messing with the computational internals.

=head1 SEE ALSO

L<Date::Tolkien::Shire|Date::Tolkien::Shire>

L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
