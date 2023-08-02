#!/usr/bin/env perl
use 5.016_000;
use warnings;
use POSIX qw(ceil floor);

# demo of various max value of data of graphs,
# with a y-axis maxHeight a bit above that
foreach my $peak (0.1, 0.9, 2.1, 9.9, 11, 22.22, 35, 111, 265, 999, 1020, 120010) {
    my $h = maxheight_for_peak($peak);
    say "$peak\t$h";
}

sub maxheight_for_peak {
    my ($peak) = @_;

    # one less than the magnitude of the peak,
    # e.g. base is 100 for 1020
    my $base = 10**( floor(log($peak)/log(10)) - 1 );

    # round up the height up to the next base
    my $h = ceil($peak/$base) * $base;

    # avoid peak == max, so there's some extra space on top
    $h += $base if $h == $peak;

    return $h;
}

__END__
0.1	0.11
0.9	0.91
2.1	2.2
9.9	10
11	12
22.22	23
35	36
111	120
265	270
999	1000
1020	1100
120010	130000
