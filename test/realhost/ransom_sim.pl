#!/usr/bin/perl
# Ransomware behaviour simulator for detector tests. NOT malware: it only rewrites files it creates itself
# in a directory you pass. usage: ransom_sim.pl DIR MODE [COMM]
#   MODE: full | partial | b64 | none(=just write low-entropy copies)
#   COMM: process name to present in /proc/<pid>/comm (default: leave as is)
use strict; use warnings;
my ($dir, $mode, $comm) = @ARGV;
$0 = $comm if defined $comm && length $comm;   # perl sets comm from $0
mkdir $dir unless -d $dir;
my $n = 40; my $size = 65536;
my @files;
for my $i (1..$n) {
    my $f = "$dir/doc$i.txt";
    open(my $fh, '>', $f) or die $!; print $fh ("The quick brown fox jumps over the lazy dog. " x int($size/45)); close $fh;
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
}
print "done $mode comm=", ($comm // '(default)'), "\n";
