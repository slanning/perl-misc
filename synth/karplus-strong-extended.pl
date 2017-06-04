#!/usr/bin/env perl
# http://www.cs.nuim.ie/~matthewh/VST.html
use strict;
use warnings;

my $SAMPLE_RATE      = 44100;   # samples per second, Hz

my $BYTES_PER_SAMPLE = 2;
my $packfmt = ($BYTES_PER_SAMPLE == 2)
  ? 's<'   # signed 16-bit little-endian (I think 'v' also works)
  : ($BYTES_PER_SAMPLE == 1)
    ? 'C'  # unsigned 8-bit
    : die("unsupported BYTES_PER_SAMPLE\n");
my $MAX_AMPLITUDE = 2**(8*$BYTES_PER_SAMPLE - 1) - 1;  # signed

my ($freq, $sec, $tau, $vel, $u) = @ARGV;
$freq  //= 261.626;  # middle C
$sec   //= 2.5;      # duration
$tau   //= $sec;     # time in seconds where waveform loses 60dB
$vel   //= 64;       # pick velocity, 0 - 127
$u = 0.5;            # position of pluck along string, 0 < u <= 0.5; 0.5 = half-string point (flute-like)

# here the signal is assumed to be normalized (-1,1);
# later it gets scaled to $MAX_AMPLITUDE

# 1. excitation and delay line
my $N = my $delta = int(($SAMPLE_RATE / $freq) - 0.5 - 0.001);
my @r = map(2 * (rand(1) - 0.5), 1 .. $N);
my @d = (0) x $N;

# 2. loss and tuning filter
my $t = (1 - $delta) / (1 + $delta);   # fractional delay
my $g = 10**(-6 / ($freq * $tau));
my $b0 = 0.5 * $g * $t;
my $b1 = 0.5      * ($t + 1);
my $b2 = 0.5 * $g;
my $a = $t;
my $f0 = 0;  # not sure how to initialize these
my $f1 = 0;

# 3. velocity filter: -1 < v <= 0
my $vmin = 0.01;   # should be a "small" value
my $v = $vmin**(1 - $vel / 128) - 1;
my $w = 0;

# 4. plucking-point filter
my $P = (int($u*$N) > 1) ? int($u*$N) : 1;   # max(int(uN), 1)
my $wt = 2500;   # arbitrary, but see the link "best results"
my $rho = sqrt((2 * $u * $N * $wt) / ($u * $N * $wt - sin($u * $N * $wt)));
my @q = (0) x $P;   # initialized to zero?

my $num_samples = $SAMPLE_RATE * $sec;
foreach my $n (0 .. $num_samples - 1) {
    my $y;
    my $nmod = $n % $N;
    if ($n < $N) {
        $y = $r[$n];
    }
    else {
        my $x = $d[$nmod];

        # F(x)
        $y = $b0 * $x + $f0;
        $f0 = $b1 * $x + $f1 - $a * $y;
        $f1 = $b2 * $x;
    }
    $d[$nmod] = $y;

    # V(y)
    $y = (1 + $v) * $y - $v * $w;
    $w = $y;

    # P(V(y))
    my $pmod = $n % $P;
    my $z = $rho * ($y - $q[$pmod]);
    $q[$pmod] = $y;
    $y = $z;

    # renormalize
    $y = int($MAX_AMPLITUDE * $y);
    if ($y > $MAX_AMPLITUDE) {
        $y = $MAX_AMPLITUDE;
    }
    elsif ($y < -$MAX_AMPLITUDE) {
        $y = -$MAX_AMPLITUDE;
    }

    print pack($packfmt, $y);
}

__END__

# this sounds pretty good,
# but it's a slightly different pitch than "./pluck.pl 41 2 7 0.99"
./synth/karplus-strong-extended.pl 41 2 5 | ./synth/wav-gen.pl ~/wav/kps-ext-41-5.wav

# It still seems off for higher frequencies...
# very brief
./synth/karplus-strong-extended.pl 882 2 10 | ./synth/wav-gen.pl ~/wav/kps-ext-882-10.wav
# more like a xylophone tap
./synth/karplus-strong-extended.pl 2222 2 10 | ./synth/wav-gen.pl ~/wav/kps-ext-2222-10.wav
