#!/usr/bin/env perl
# $0 freq sec type dist
use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }
use Math::Trig;    # pi

my $SAMPLE_RATE      = 44100;   # samples per second, Hz

my $BYTES_PER_SAMPLE = 2;
my $packfmt = ($BYTES_PER_SAMPLE == 2)
  ? 's<'   # signed 16-bit little-endian (I think 'v' also works)
  : ($BYTES_PER_SAMPLE == 1)
    ? 'C'  # unsigned 8-bit
    : die("unsupported BYTES_PER_SAMPLE\n");
my $MAX_AMPLITUDE = 2**(8*$BYTES_PER_SAMPLE - 1) - 1;  # signed

# maybe I should just use GetOpt...
my ($freq, $sec, $type, $dist) = @ARGV;
$freq //= 261.626;  # middle C
$sec  //= 2.5;      # time
$type //= 'sin';    # sin, square, sawtooth, triangle, rect33 (33% high pulse)
$dist //= '1:1';    # distribution of harmonics, e.g. '3:1,2:3,1:7' is 3 parts fundamental, 2 of 3rd harmonic, 1 of 7th

my @WEIGHTS   = map { ($_, undef) = split(/:/, $_); $_ } split(/,/, $dist);
my $SUM_WEIGHTS = 0;
$SUM_WEIGHTS += $_ for @WEIGHTS;
my @HARMONICS = map { (undef, $_) = split(/:/, $_); $_ } split(/,/, $dist);

if ($type =~ /^sine?$/) {
    print_sine($freq, $sec);
}
elsif ($type =~ /^saw(?:tooth)?$/) {
    print_sawtooth($freq, $sec);
}
elsif ($type =~ /^tri(?:angle)?$/) {
    print_triangle($freq, $sec);
}
elsif ($type =~ /^squ(?:are)?$/) {
    print_rectangle($freq, $sec, 50);
}
elsif ($type =~ /^rec[a-z]*(\d+)$/) {
    my $percent_high = $1;
    print_rectangle($freq, $sec, $percent_high);
}
else {
    die "unhandled type\n";
}

exit;

sub print_sine {
    my ($freq, $sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = 0;
        for (my $i=0; $i < @HARMONICS; ++$i) {
            my $harmonic = $HARMONICS[$i];
            my $f = $harmonic * $freq;
            $value += $WEIGHTS[$i] * $MAX_AMPLITUDE * sin( (2 * pi * $n * $f) / $SAMPLE_RATE );
        }
        print pack($packfmt, int($value / $SUM_WEIGHTS));
    }
}

sub print_sawtooth {
    my ($freq, $sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = 0;
        for (my $i=0; $i < @HARMONICS; ++$i) {
            my $harmonic = $HARMONICS[$i];
            my $f = $harmonic * $freq;

            # go linearly from 0 to 2 * max, subtract half that to center it
            $value += $WEIGHTS[$i] * (
                (int(2 * $MAX_AMPLITUDE * $n * $freq / $SAMPLE_RATE)
                   % (2 * $MAX_AMPLITUDE))
                  - $MAX_AMPLITUDE
            );
        }
        print pack($packfmt, int($value / $SUM_WEIGHTS));
    }
}

sub print_triangle {
    my ($freq, $sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = 0;
        for (my $i=0; $i < @HARMONICS; ++$i) {
            my $harmonic = $HARMONICS[$i];
            my $f = $harmonic * $freq;

            # absolute value of sawtooth, rescaled and offset
            $value += $WEIGHTS[$i] * (
                2 * abs(
                    (int(2 * $MAX_AMPLITUDE * $n  * $freq / $SAMPLE_RATE)
                       % (2 * $MAX_AMPLITUDE))
                      - $MAX_AMPLITUDE)
                  - $MAX_AMPLITUDE
              );
        }
        print pack($packfmt, int($value / $SUM_WEIGHTS));
    }
}

sub print_rectangle {
    my ($freq, $sec, $percent_high) = @_;

    my $samples_per_wavelength = $SAMPLE_RATE / $freq;   # samples / sec * (1/sec)
    my $num_samples = $SAMPLE_RATE * $sec;     # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = 0;
        for (my $i=0; $i < @HARMONICS; ++$i) {
            my $harmonic = int($samples_per_wavelength / $HARMONICS[$i]);

            $value += (($n % $harmonic) < ($percent_high / 100 * $harmonic))
              ?  $MAX_AMPLITUDE * $WEIGHTS[$i]
              : -$MAX_AMPLITUDE * $WEIGHTS[$i];
        }
        print pack($packfmt, int($value / $SUM_WEIGHTS));
    }
}

__END__

./synth/osc-harmonics.pl 440 2 sin '3:1,2:3,1:7' | ./synth/wav-gen.pl ~/wav/sin-440-2-harmonics3:1,2:3,1:7.wav
./synth/osc-harmonics.pl 440 2 square   '3:1,2:4,1:8' | ./synth/wav-gen.pl ~/wav/square-440-2-harmonics3:1,2:4,1:8.wav
./synth/osc-harmonics.pl 440 2 rect10   '3:1,2:4,1:8' | ./synth/wav-gen.pl ~/wav/rect10-440-2-harmonics3:1,2:4,1:8.wav
# not much difference in sawtooth or triangle
./synth/osc-harmonics.pl 440 2 sawtooth '3:1,2:4,1:8' | ./synth/wav-gen.pl ~/wav/sin-440-2-harmonics3:1,2:4,1:8.wav
./synth/osc-harmonics.pl 440 2 triangle '3:1,2:4,1:8' | ./synth/wav-gen.pl ~/wav/tri-440-2-harmonics3:1,2:4,1:8.wav
