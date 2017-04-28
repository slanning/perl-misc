#!/usr/bin/env perl
# using phonemes from arpabet passed:
# ./swap-phonemes.pl phoneme1 phoneme2
# this will output all the words from CMUdict matched by swapping those phonemes
# phoneme1 and phoneme2 are the keys of %phoneme below

use strict;
use warnings;
use autodie;
use Data::Dumper; {package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1) x 4}
use File::Spec ();
use FindBin ();

my ($phoneme1, $phoneme2) = @ARGV;
die "Usage: $0 phoneme1 phoneme2"
  unless @ARGV == 2;

# from http://www.speech.cs.cmu.edu/cgi-bin/cmudict
# Phoneme Example Translation
my %phoneme = (
    AA  => "odd     AA D",
    AE  => "at  AE T",
    AH  => "hut HH AH T",
    AO  => "ought       AO T",
    AW  => "cow K AW",
    AY  => "hide        HH AY D",
    B   => "be  B IY",
    CH  => "cheese      CH IY Z",
    D   => "dee D IY",
    DH  => "thee        DH IY",
    EH  => "Ed  EH D",
    ER  => "hurt        HH ER T",
    EY  => "ate EY T",
    F   => "fee F IY",
    G   => "green       G R IY N",
    HH  => "he  HH IY",
    IH  => "it  IH T",
    IY  => "eat IY T",
    JH  => "gee JH IY",
    K   => "key K IY",
    L   => "lee L IY",
    M   => "me  M IY",
    N   => "knee        N IY",
    NG  => "ping        P IH NG",
    OW  => "oat OW T",
    OY  => "toy T OY",
    P   => "pee P IY",
    R   => "read        R IY D",
    S   => "sea S IY",
    SH  => "she SH IY",
    T   => "tea T IY",
    TH  => "theta       TH EY T AH",
    UH  => "hood        HH UH D",
    UW  => "two T UW",
    V   => "vee V IY",
    W   => "we  W IY",
    Y   => "yield       Y IY L D",
    Z   => "zee Z IY",
    ZH  => "seizure     S IY ZH ER",
);

my @unrecognized_phonemes = grep { !exists($phoneme{$_}) } ($phoneme1, $phoneme2);
die "unrecognized phonemes: @unrecognized_phonemes"
  if @unrecognized_phonemes;

my %words;

# http://svn.code.sf.net/p/cmusphinx/code/trunk/cmudict/
my $cmudict_file = File::Spec->catfile($FindBin::Bin, 'cmudict-0.7b.txt');
open(my $fh, '<', $cmudict_file);
while (<$fh>) {
    next if /^;;;/;
    chomp;
    my ($word, @phoneme) = split / +/;

    # Numbers 0-2 indicate stress, which I ignore here.
    # I also prepend the "multi-dimensional array" char ($;)
    # so that each phoneme is preceded by that,
    # for easier matching below
    my $pronunciation = $; . join($;, map { s/[0-2]$//; $_ } @phoneme);
    push @{ $words{$pronunciation} }, $word;
}

my %matching;
foreach my $pronunciation1 (sort keys %words) {
    my $pronunciation2 = $pronunciation1;

    if ($pronunciation2 =~ s/$;$phoneme1/$;$phoneme2/ and $words{$pronunciation2}) {
	print "[@{ $words{$pronunciation1} }] - [@{ $words{$pronunciation2} }]\n";
    }
}
