#!/usr/bin/perl
# Ransomware behaviour simulator for detector tests. NOT malware: it only rewrites files it creates itself
# in a directory you pass. usage: [RS_SIM_DELAY=seconds] ransom_sim.pl DIR MODE [COMM]
#   MODE: full | partial | b64 | none(=just write low-entropy copies)
#   COMM: process name to present in /proc/<pid>/comm (default: leave as is)
use strict; use warnings;
my ($dir, $mode, $comm) = @ARGV;
$0 = $comm if defined $comm && length $comm;   # perl sets comm from $0
mkdir $dir unless -d $dir;
my $n = 40; my $size = 65536;
# Ordinary prose, not a pangram: a 16-byte stretch of real text repeats few byte values, which is what the
# partial-encryption check looks at (a pangram has almost every letter in every stretch).
my $plain = '';
if (open(my $lic, '<', '/usr/share/common-licenses/GPL-3')) { local $/; $plain = <$lic>; close $lic }
$plain = "the theme of the thesis is then that there is this and that. " unless length $plain;
$plain = substr($plain x (int($size / length($plain)) + 1), 0, $size);
my @files;
for my $i (1..$n) {
    my $f = "$dir/doc$i.txt";
    open(my $fh, '>', $f) or die $!; print $fh $plain; close $fh;
    push @files, $f;
}
sleep 2;   # let the creation settle so only the rewrite below forms the burst
sub keystream { my $len = shift; pack('C*', map { int(rand(256)) } 1..$len) }
for my $f (@files) {
    open(my $in, '<:raw', $f) or next; local $/; my $data = <$in>; close $in;
    my $out;
    if ($mode eq 'full') { $out = keystream(length $data) }
    elsif ($mode eq 'partial') {
        $out = $data;                               # encrypt 16 bytes, skip 16, ...
        for (my $o = 0; $o < length $out; $o += 32) { substr($out, $o, 16) = keystream(16) if $o + 16 <= length $out }
    }
    elsif ($mode eq 'b64') { require MIME::Base64; $out = MIME::Base64::encode_base64(keystream(int(length($data) * 3 / 4))) }
    else { $out = $data }
    open(my $o, '>:raw', $f) or next; print $o $out; close $o;
    rename $f, "$f.locked";
    select(undef, undef, undef, $ENV{RS_SIM_DELAY}) if $ENV{RS_SIM_DELAY};   # seconds per file; real ransomware works on much larger files, so it is slower than this
}
print "done $mode comm=", ($comm // '(default)'), "\n";
