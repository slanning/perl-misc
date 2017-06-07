Learning to synthesize various electronic sounds
and generate wav files.

# basic oscillators, 440 Hz
./osc.pl 440 2 sin      | ./wav-gen.pl ~/wav/sin-440-2.wav
./osc.pl 440 2 sawtooth | ./wav-gen.pl ~/wav/saw-440-2.wav
./osc.pl 440 2 triangle | ./wav-gen.pl ~/wav/tri-440-2.wav
./osc.pl 440 2 noise    | ./wav-gen.pl ~/wav/noise-2.wav
./osc.pl 440 2 square   | ./wav-gen.pl ~/wav/square-440-2.wav
./osc.pl 440 2 rect10   | ./wav-gen.pl ~/wav/rect10-440-2.wav

# simple Karplus-Strong pluck sounds
# high-pitched
./pluck.pl 440 2 1 | ./wav-gen.pl ~/wav/pluck-440-2-1.wav
# bass guitar
./pluck.pl 41 2 7 0.99 | ./wav-gen.pl ~/wav/pluck-41-2-7-0.99.wav

# Karplus-Strong extended algorithm
# bass guitar (41Hz)
./karplus-strong-extended.pl 41 2 5 | ./wav-gen.pl ~/wav/kps-ext-41-5.wav


I try to keep the Perl without external dependencies
(otherwise for example there's Audio::SndFile for writing .wav files
and probably http://search.cpan.org/search?query=audio&mode=module
and/or http://search.cpan.org/search?query=sound&mode=module )

piano-frequencies.dat is from https://en.wikipedia.org/wiki/Piano_key_frequencies
(or for the normal 88 keys, the $n key's frequency is 2**(($n-49)/12) * 440 )
