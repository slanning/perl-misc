#!perl
# It turns out that the conversion from miles to kilometers
# is approximately the same as the golden ratio (1.61-ish)
# which can be approximated by the ratios in the fibonacci series!

use warnings;
use strict;

my $K  = 1.609344;  # km/mile

my $s5 = sqrt 5;
my $f  = 1;

# https://arxiv.org/pdf/1611.07384.pdf
# "FIBONACCI NUMBERS AND THE GOLDEN RATIO"
# (though I've seen non-recursive fibonacci before that)
my $Phi = ($s5 + 1) / 2;
my $fib = sub {
    my $n = $_[0];
    return( ($Phi**$n - (-$Phi)**-$n) / $s5 );
};

print " n\t\tfib ratio\tdelta\tpercent\n";
for (2..20) {
    my $F = $fib->($_);
    my $r = $F / $f;
    printf "%2d %9s=%.7f %+.7f %+2.4f\n",
      $_,
      "$F/$f",
      $r,
      ($K - $r),
      100 * ($K - $r) / $K,
      ;
    $f = $F;
}

__END__

# after n=5 it's pretty good,
# and converges at n=20
perl -E'my$K=1.609344;my$s5=sqrt 5;my$f=1;my$Phi=($s5+1)/2;my$fib=sub{my$n=$_[0];($Phi**$n-(-$Phi)**-$n)/$s5};say"    n\t\tfib ratio\tdelta\tpercent";for(2..20){my$F=$fib->($_);my$r=$F/$f;printf"    %2d %9s=%.7f %+.7f %+2.4f\n",$_,"$F/$f",$r,($K-$r),100*($K-$r)/$K;$f=$F}'
n           fib ratio       delta   percent
 2       1/1=1.0000000 +0.6093440 +37.8629
 3       2/1=2.0000000 -0.3906560 -24.2742
 4       3/2=1.5000000 +0.1093440 +6.7943
 5       5/3=1.6666667 -0.0573227 -3.5619
 6       8/5=1.6000000 +0.0093440 +0.5806
 7      13/8=1.6250000 -0.0156560 -0.9728
 8     21/13=1.6153846 -0.0060406 -0.3753
 9     34/21=1.6190476 -0.0097036 -0.6030
10     55/34=1.6176471 -0.0083031 -0.5159
11     89/55=1.6181818 -0.0088378 -0.5492
12    144/89=1.6179775 -0.0086335 -0.5365
13   233/144=1.6180556 -0.0087116 -0.5413
14   377/233=1.6180258 -0.0086818 -0.5395
15   610/377=1.6180371 -0.0086931 -0.5402
16   987/610=1.6180328 -0.0086888 -0.5399
17  1597/987=1.6180344 -0.0086904 -0.5400
18 2584/1597=1.6180338 -0.0086898 -0.5400
19 4181/2584=1.6180341 -0.0086901 -0.5400
20 6765/4181=1.6180340 -0.0086900 -0.5400
