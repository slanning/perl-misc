#!/usr/bin/env perl
# https://arxiv.org/ftp/arxiv/papers/1106/1106.2593.pdf
# (subleq one-instruction set computer -
#  beginning, I don't remember where I was going here)

use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }

my @memory;
my $ip = 0;

while ($ip >= 0) {
    # assumes all 3 operands are given
    my ($a, $b, $c) = @memory[$IP .. $IP+2];

#    # negative is cheating (?)
#    if ($a < 0) {
#        local $/ = \1;
#        $memory[$b] = <STDIN>;
#    }
#    elsif ($b < 0) {
#        local $/ = \1;
#        $memory[$a] = <STDOUT>;
#    }
    if ($a < 0 or $b < 0) {
        $ip = -1;
    else {
        $memory[$b] -= $memory[$a];
        if ($memory[$b] > 0) {
            $ip += 3;
        }
        else {
            $ip = $c;
        }
    }
}
