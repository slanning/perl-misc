#!/usr/bin/env perl
# Karplus-Strong algorithm to generate a pluck sound
# $0 freq sec delay decay
use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }

my $SAMPLE_RATE      = 44100;   # samples per second, Hz

my $BYTES_PER_SAMPLE = 2;
my $packfmt = ($BYTES_PER_SAMPLE == 2)
  ? 's<'   # signed 16-bit little-endian (I think 'v' also works)
  : ($BYTES_PER_SAMPLE == 1)
    ? 'C'  # unsigned 8-bit
    : die("unsupported BYTES_PER_SAMPLE\n");
my $MAX_AMPLITUDE = 2**(8*$BYTES_PER_SAMPLE - 1) - 1;  # signed

# maybe I should just use GetOpt...
my ($freq, $sec, $delay, $decay) = @ARGV;
$freq  //= 261.626;  # middle C
$sec   //= 2.5;      # time
$delay //= 1;        # delay in samples
$decay //= 1;        # decay per sample (should be <= 1; >1 fades into noise)

# $freq is related to the sample size $L ,
# I guess $SAMPLE_RATE / $L == $freq
my $L = int($SAMPLE_RATE / $freq);  # not quite A (44100 / 440 ~ 100.227)
my @x = map(int(2 * $MAX_AMPLITUDE * (rand(1) - 0.5)), 1 .. $L);

my $num_samples = $SAMPLE_RATE * $sec;
foreach my $n (0 .. $num_samples - 1) {
    my $nmod = $n % $L;
    my $value = int($x[$nmod]);
    my $n_minus_1 = ($nmod == 0)
      ? -1
      : ($nmod - 1);
    $x[$nmod] = ($x[$nmod] + $decay * $x[$n_minus_1]) / 2;
    print pack($packfmt, int($value));
}

__END__

./synth/pluck.pl 440 2 1 | ./synth/wav-gen.pl ~/wav/pluck-440-2-1.wav
./synth/pluck.pl 440 2 7 0.999 | ./synth/wav-gen.pl ~/wav/pluck-440-2-7-0.999.wav
# sick bass sound (
./synth/pluck.pl 41 2 7 0.99 | ./synth/wav-gen.pl ~/wav/pluck-41-2-7-0.99.wav
# for some reason (harmonics filtered?) it changes sound the longer it's played
./synth/pluck.pl 41 5 1 0.99 | ./synth/wav-gen.pl ~/wav/pluck-41-5-1-0.99.wav

https://en.wikipedia.org/wiki/Karplus%E2%80%93Strong_string_synthesis
http://amid.fish/karplus-strong
http://crypto.stanford.edu/~blynn/sound/karplusstrong.html
http://cmc.music.columbia.edu/MusicAndComputers/chapter4/04_09.php
http://blog.csdn.net/YhL_Leo/article/details/48730857
-wavetable synthesis algorithm
-plucked string algorithm
-drum algorithm
https://ccrma.stanford.edu/~jos/pasp/Extended_Karplus_Strong_Algorithm.html
-extended Karplus-Strong algorithm

# have to register ("free"), original karplus-strong article
https://www.jstor.org/stable/3680062

# "digital waveguide synthesis" seems to be a patented (by Stanford, ccrma site above)
# but apparently "comb filters" sound the same and exist before that
https://en.wikipedia.org/wiki/Comb_filter
# also flanging
