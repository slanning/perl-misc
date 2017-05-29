#!/usr/bin/env perl
# $0 freq sec type
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
my ($freq, $sec, $type) = @ARGV;
$freq //= 261.626;  # middle C
$sec   //= 2.5;      # time
$type      //= 'sin';    # sin, square, sawtooth, triangle, rect33 (33% high pulse)

if ($type =~ /^sine?$/) {
    print_sine($freq, $sec);
}
elsif ($type =~ /^saw(?:tooth)?$/) {
    print_sawtooth($freq, $sec);
}
elsif ($type =~ /^tri(?:angle)?$/) {
    print_triangle($freq, $sec);
}
elsif ($type =~ /^(?:white)?noise$/) {
    print_noise($sec);
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
        my $value = $MAX_AMPLITUDE * sin( (2 * pi * $n * $freq) / $SAMPLE_RATE );
        print pack($packfmt, int($value));
    }
}

sub print_sawtooth {
    my ($freq, $sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        # go linearly from 0 to 2 * max, subtract half that to center it
        my $value = (int(2 * $MAX_AMPLITUDE * $n * $freq / $SAMPLE_RATE)
                       % (2 * $MAX_AMPLITUDE))
                    - $MAX_AMPLITUDE;
        print pack($packfmt, int($value));
    }
}

sub print_triangle {
    my ($freq, $sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        # absolute value of sawtooth, rescaled and offset
        my $value = 2 * abs(
                    (int(2 * $MAX_AMPLITUDE * $n  * $freq / $SAMPLE_RATE)
                       % (2 * $MAX_AMPLITUDE))
                    - $MAX_AMPLITUDE)
          - $MAX_AMPLITUDE;
        print pack($packfmt, int($value));
    }
}

sub print_noise {
    my ($sec) = @_;

    my $num_samples = $SAMPLE_RATE * $sec;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = int(2 * $MAX_AMPLITUDE * rand) - $MAX_AMPLITUDE;
        print pack($packfmt, int($value));
    }
}

sub print_rectangle {
    my ($freq, $sec, $percent_high) = @_;

    my $samples_per_wavelength = $SAMPLE_RATE / $freq;   # samples / sec * (1/sec)
    my $num_samples = $SAMPLE_RATE * $sec;     # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $value = (($n % $samples_per_wavelength) < ($percent_high / 100 * $samples_per_wavelength))
          ?  $MAX_AMPLITUDE
          : -$MAX_AMPLITUDE;
        print pack($packfmt, int($value));
    }
}

__END__

./synth/osc.pl 440 2 sin      | ./synth/wav-gen.pl ~/wav/sin-440-2.wav
./synth/osc.pl 440 2 sawtooth | ./synth/wav-gen.pl ~/wav/saw-440-2.wav
./synth/osc.pl 440 2 triangle | ./synth/wav-gen.pl ~/wav/tri-440-2.wav
./synth/osc.pl 440 2 noise    | ./synth/wav-gen.pl ~/wav/noise-2.wav
./synth/osc.pl 440 2 square   | ./synth/wav-gen.pl ~/wav/square-440-2.wav
./synth/osc.pl 440 2 rect10   | ./synth/wav-gen.pl ~/wav/rect10-440-2.wav
