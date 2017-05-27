#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }

use Math::Trig;    # pi

my $SAMPLE_RATE      = 44100;   # samples per second, Hz

my $BYTES_PER_SAMPLE = 2;
my $MAX_AMPLITUDE = 2**(8*$BYTES_PER_SAMPLE - 1) - 1;  # signed

my ($frequency, $seconds, $type) = @ARGV;
$frequency //= 261.626;  # middle C
$seconds   //= 2.5;      # time
$type      //= 'sin';    # sin, square, sawtooth, triangle, rect33 (33% high pulse)

if ($type eq 'sin') {
    print_sin($frequency, $seconds);
}
elsif ($type eq 'square') {
    print_rectangle($frequency, $seconds, 50);
}
elsif ($type eq 'sawtooth') {
    print_sawtooth($frequency, $seconds);
}
elsif ($type eq 'triangle') {
    print_triangle($frequency, $seconds);
}
elsif ($type =~ /^rect(\d+)$/) {
    my $percent_high = $1;
    print_rectangle($frequency, $seconds, $percent_high);
}
else {
    die "unhandled type\n";
}

exit;

sub print_sin {
    my ($frequency, $seconds) = @_;

    my $num_samples = $SAMPLE_RATE * $seconds;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $amplitude = $n / $num_samples * $MAX_AMPLITUDE;
        my $value     = sin( (2 * pi * $n * $frequency) / $SAMPLE_RATE );

        print pack('v', int($amplitude * $value));
    }
}

sub print_sawtooth {
    my ($frequency, $seconds) = @_;

    my $num_samples = $SAMPLE_RATE * $seconds;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {

    }
}

sub print_triangle {
    my ($frequency, $seconds) = @_;

    my $num_samples = $SAMPLE_RATE * $seconds;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {

    }
}

sub print_rectangle {
    my ($frequency, $seconds, $percent_high) = @_;

    my $num_samples = $SAMPLE_RATE * $seconds;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {

    }
}
