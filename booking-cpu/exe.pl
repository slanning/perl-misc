#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

my $DEBUG = 0;
my $SLEEP = 0;
my %REG = (
    A => undef,
    B => undef,
    C => undef,
    D => undef,
);
my @MEMORY = (0) x 64*1024;
my $OVERFLOW_LIMIT = 2**16 - 1;
my $OVERFLOW = 0;
my $UNDERFLOW = 0;
my $PC = 0;
my %LABEL2INST;


my %HANDLE = (
    MUL => sub {
        $REG{C} = $REG{A} * $REG{B};
        $OVERFLOW = 1 if $REG{C} > $OVERFLOW_LIMIT;
    },
    DIV => sub { $REG{C} = int($REG{A} / $REG{B}) },
    MOD => sub { $REG{C} = $REG{A} % $REG{B} },

    # $PC is always incremented after $HANDLE, so subtracting 1 here
    JOF => sub { $PC = $LABEL2INST{$_[0]} - 1 if $OVERFLOW },
    JUF => sub { $PC = $LABEL2INST{$_[0]} - 1 if $UNDERFLOW },
    JMP => sub { $PC = $LABEL2INST{$_[0]} - 1 },
);
$HANDLE{JUMP} = $HANDLE{JMP};  # workaround bug in example script
foreach my $reg ("A" .. "D") {
    $HANDLE{"LD$reg"}  = sub { $REG{$reg} = $_[0] };
    $HANDLE{"OUT$reg"} = sub { print $REG{$reg}, $/ };
    $HANDLE{"RD$reg"}  = sub { $REG{$reg} = $MEMORY[$_[0]] };
    $HANDLE{"WT$reg"}  = sub { $MEMORY[$_[0]] = $REG{$reg} };
    $HANDLE{"INC$reg"} = sub {
        if (++$REG{$reg} > $OVERFLOW_LIMIT) {
            $OVERFLOW = 1;
            $REG{$reg} = undef;
        }
    };
    $HANDLE{"DEC$reg"} = sub {
        if (--$REG{$reg} < 0) {
            $UNDERFLOW = 1;
            $REG{$reg} = undef;  # ?
        }
    };
    $HANDLE{"J${reg}Z"} = sub {
        $PC = $LABEL2INST{$_[0]} - 1
          if $REG{$reg} == 0;
    };
}

my $instructions = parse_instructions();
run($instructions);
exit;

sub run {
    my ($instructions) = @_;

    print Dumper($instructions) if $DEBUG;

    my $running = 1;
    while ($running) {
        my $inst = $instructions->[$PC];
        dump_state($inst) if $DEBUG;

        last if $inst->{name} eq 'HALT';

        $HANDLE{$inst->{name}}->(@{ $inst->{args} });
        $PC++;
        select undef,undef,undef, $SLEEP;
    }
}

sub dump_state {
    my ($instruction) = @_;
    print Dumper($instruction);
    print "pc: $PC\n";
    print "overflow: $OVERFLOW\n";
    print "underflow: $UNDERFLOW\n";
}

sub parse_instructions {
    my @instruction;

    my $addr = 0;
    while (<>) {
        chomp;
        s/^\s+//;
        s/#.*$//;
        s/\s+$//;
        next unless $_;

        my ($label, $name, $args) = /^\s*(\S+:)?\s*(\S+)(.*)$/;

        if ($label) {
            $label =~ s/:$//;
            $LABEL2INST{$label} = $addr;
        }

        my @args;
        if ($args and $args =~ /\S/) {
            $args =~ s/^\s+//;
            $args =~ s/\s+$//;
            @args = split /\s+/, $args;
        }


        $instruction[$addr++] = {
            name     => uc($name),
            args     => \@args,
            ($label ? (label => uc($label)) : ()),
            addr     => $addr,
        };
    }

    return(\@instruction);
}


__END__

Tl;dr
Write a program that will run programs written in a simple machine language for a register based CPU.
A small machine language

    you have 3 registers called A B C D, each one can hold a 16 bit unsigned integer
    you have 64K of memory space, individually adressable.

Opcodes and what they do
a line in your program consists of:

    an optional case insensitive label [A-Za-z]+ terminated by a colon
    an opcode from the following table
    an argument if the opcode requires it
    an optional comment preceded by a #

comments do nothing at all.

BEGIN: LDA 4 # load 4 into the A register

    LDA: load an integer into the A register (LDB, LDC, LDD do the obvious)
    RDA: read from a location in memory into A (RDB, RDC, RDD)
    WTA: write the value of A in a location in memory (WTB, WTC, WTD)
    INCA: increment by 1 the A register: if overflow, set OVERFLOW flag and the result is undefined. (INCB, INCC, INCD)
    DECA: decrement by 1 the A register: if underflow set UNDERFLOW flag (DECB, DECC, DECD)
    DIV: integer divide A by B and write into C
    MOD: integer divide A by B and write the remainder into C
    MUL: multiply A by B and write into C; if overflow, set OVERFLOW flag
    JAZ: jumps to a label if A is zero (JBZ, JCZ, JDZ)
    JOF: jumps to a label if OVERFLOW is set
    JUF: jumps to a label if UNDERFLOW is set
    JMP: jumpst to a label without any condition
    OUTA: sends the content of A to standard output as ASCII text followed by a carriage return (OUTB, OUTC, OUTD)
    HALT: ends execution (your program should terminate when it sees a HALT)

Example programs

# ex1.asm
START: LDA 10 # count down from 10 to 0
LOOP:  OUTA
       DECA
       JAZ END
       JUMP LOOP
END:   HALT

------------------------

# ex2.asm
START: LDA 1 # print the powers of 2 up to 2^15
       LDB 2
       LDD 15 # the loop index
LOOP:  MUL   # multiply A by 2
       OUTC  # print the result
       DECD  # decrement the index
       WTC 0 # store the result into memory 0
       RDA 0 # read it into A
       JDZ END
       JMP LOOP
END:   HALT

$ ./exe.pl ex1.asm
10
9
8
7
6
5
4
3
2
1

$ ./exe.pl ex2.asm
2
4
8
16
32
64
128
256
512
1024
2048
4096
8192
16384
32768

$
