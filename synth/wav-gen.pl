#!/usr/bin/env perl
# (currently foo.dat is ignored, so write anything there)
# $0 foo.dat foo.wav
# http://soundfile.sapp.org/doc/WaveFormat/
use strict;
use warnings;
use Data::Dumper; { package Data::Dumper; our ($Indent, $Sortkeys, $Terse, $Useqq) = (1)x4 }
use Math::Trig;    # pi

my $NUM_CHANNELS    = 2;       # 1=mono, 2=stereo, etc
my $SAMPLE_RATE     = 44100;   # samples per second, Hz
my $BITS_PER_SAMPLE = 16;      # multiple of 8

my ($data_fh, $out_fh) = open_files();
write_riff_chunk_descriptor($out_fh);
my $data_chunk_pos = write_fmt_sub_chunk($out_fh);
write_data_sub_chunk($data_fh, $out_fh);
fill_in_chunk_sizes($data_fh, $out_fh, $data_chunk_pos);

exit;

sub open_files {
    die "Usage: $0 input.dat output.wav\n"
      unless @ARGV == 2;

    #open(my $data_fh, '<', $ARGV[0])
    #  or die("couldn't open data file '$ARGV[0]': $!");
    my $data_fh;

    open(my $out_fh, '+>', $ARGV[1])
      or die("couldn't open output file '$ARGV[1]': $!");

    return($data_fh, $out_fh);
}

sub write_riff_chunk_descriptor {
    my ($out_fh) = @_;

    print $out_fh "RIFF",                      # ChunkID
                  "????",                      # ChunkSize (not yet known)
                  "WAVE";                      # Format
}

sub write_fmt_sub_chunk {
    my ($out_fh) = @_;

    my $byte_rate   = $SAMPLE_RATE * $NUM_CHANNELS * $BITS_PER_SAMPLE / 8;
    my $block_align = $NUM_CHANNELS * $BITS_PER_SAMPLE / 8;  # size in bytes of integer samples for all channels

    print $out_fh "fmt ",                      # Subchunk1ID
                  # these are little-endian; V = 4-byte, v = 2-byte
                  pack('V', 16),               # Subchunk1Size (16 for PCM)
                  pack('v', 1),                # AudioFormat   (PCM=1 => linear quantization)
                  pack('v', $NUM_CHANNELS),    # NumChannels
                  pack('V', $SAMPLE_RATE),     # SampleRate
                  pack('V', $byte_rate),       # ByteRate
                  pack('v', $block_align),     # BlockAlign
                  pack('v', $BITS_PER_SAMPLE); # BitsPerSample

    # if not PCM, there are also:
    # 2 bytes ExtraParamSize
    # X bytes ExtraParams

    my $data_chunk_pos = tell($out_fh);
    return($data_chunk_pos);
}

sub write_data_sub_chunk {
    my ($data_fh, $out_fh) = @_;

    print $out_fh "data",                      # Subchunk2ID
                  "????";                      # Subchunk2Size

    # finally, the sound data
    # not sure what would make sense for $data_fh input generally, yet
    make_sin($data_fh, $out_fh);
}

sub fill_in_chunk_sizes {
    my ($data_fh, $out_fh, $data_chunk_pos) = @_;

    my $file_length = tell($out_fh);   # total file size

    # 8 here is ChunkID size + ChunkSize size (4 + 4)

    # sound data size
    seek($out_fh, $data_chunk_pos + 4, 0);   # "data" == 4
    print $out_fh pack('V', $file_length - $data_chunk_pos + 8);

    # RIFF chunk size = size of file excluding ChunkID and ChunkSize
    seek($out_fh, 4, 0);
    print $out_fh pack('V', $file_length - 8);
}

sub make_sin {
    my ($data_fh, $out_fh) = @_;

    # http://www.cplusplus.com/forum/beginner/166954/
    # C4 note with a sine wave
    my $two_pi        = 2 * pi;
    my $max_amplitude = 32760;
    my $frequency     = 261.626;  # middle C
    my $seconds       = 2.5;  # time

    my $num_samples = $SAMPLE_RATE * $seconds;  # total number of samples
    foreach my $n (0 .. $num_samples - 1) {
        my $amplitude = $n / $num_samples * $max_amplitude;
        my $value    = sin( ($two_pi * $n * $frequency) / $SAMPLE_RATE );

        # 2 channels, but not sure why they complement each other
        print $out_fh pack('v', int($amplitude * $value)),
                      pack('v', int(($max_amplitude - $amplitude) * $value));
    }
}

__END__
