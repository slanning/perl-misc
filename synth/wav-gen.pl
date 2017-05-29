#!/usr/bin/env perl
# ./osc.pl | ./wav-gen.pl foo.wav
# http://soundfile.sapp.org/doc/WaveFormat/
use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }
use Math::Trig;    # pi

my $NUM_CHANNELS     = 1;       # 1=mono, 2=stereo, etc
my $SAMPLE_RATE      = 44100;   # samples per second, Hz
my $BYTES_PER_SAMPLE = 2;

my ($out_fh) = open_files();
write_riff_chunk_descriptor($out_fh);
my $data_chunk_pos = write_fmt_sub_chunk($out_fh);
write_data_sub_chunk($out_fh);
fill_in_chunk_sizes($out_fh, $data_chunk_pos);

exit;

sub open_files {
    die "Usage: osc.pl 440 1 | $0 output.wav\n"
      unless @ARGV == 1;

    open(my $out_fh, '+>', $ARGV[0])
      or die("couldn't open output file '$ARGV[0]': $!");

    return($out_fh);
}

sub write_riff_chunk_descriptor {
    my ($out_fh) = @_;

    print $out_fh "RIFF",                      # ChunkID
                  "????",                      # ChunkSize (not yet known)
                  "WAVE";                      # Format
}

sub write_fmt_sub_chunk {
    my ($out_fh) = @_;

    my $byte_rate   = $SAMPLE_RATE * $NUM_CHANNELS * $BYTES_PER_SAMPLE;
    my $block_align = $NUM_CHANNELS * $BYTES_PER_SAMPLE;  # size in bytes of integer samples for all channels

    print $out_fh "fmt ",                           # Subchunk1ID
                  # these are little-endian; V = 4-byte, v = 2-byte
                  pack('V', 16),                    # Subchunk1Size (16 for PCM)
                  pack('v', 1),                     # AudioFormat   (PCM=1 => linear quantization)
                  pack('v', $NUM_CHANNELS),         # NumChannels
                  pack('V', $SAMPLE_RATE),          # SampleRate
                  pack('V', $byte_rate),            # ByteRate
                  pack('v', $block_align),          # BlockAlign
                  pack('v', $BYTES_PER_SAMPLE * 8); # BitsPerSample

    # if not PCM, there are also:
    # 2 bytes ExtraParamSize
    # X bytes ExtraParams

    my $data_chunk_pos = tell($out_fh);
    return($data_chunk_pos);
}

sub write_data_sub_chunk {
    my ($out_fh) = @_;

    print $out_fh "data",                      # Subchunk2ID
                  "????";                      # Subchunk2Size

    # could get data chunk size here
    my $buf;
    while (read(STDIN, $buf, 2**12)) {
        print $out_fh $buf;
    }
}

sub fill_in_chunk_sizes {
    my ($out_fh, $data_chunk_pos) = @_;

    my $file_length = tell($out_fh);   # total file size

    # 8 here is ChunkID size + ChunkSize size (4 + 4)

    # sound data size
    seek($out_fh, $data_chunk_pos + 4, 0);   # "data" == 4
    print $out_fh pack('V', $file_length - $data_chunk_pos + 8);

    # RIFF chunk size = size of file excluding ChunkID and ChunkSize
    seek($out_fh, 4, 0);
    print $out_fh pack('V', $file_length - 8);
}

__END__
