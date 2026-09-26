# Ransomware detection: partial encryption and Base64, measured (2026-09-26)

The Linux detection (`roamswitch-core/src/entropy.rs`) counts a file write when the whole-buffer average entropy of the first
256 KiB is 7.92 or more. So the following ways of writing were not detected (confirmed on a real kernel on 2026-09-26):

- Partial encryption (only 16 of every 32 bytes; the technique LockBit-style families use)
- Encrypting only the head of a file, or skipping regions
- Encrypting, then Base64-encoding the output

Widening the detection risked false positives on legitimate files, so this was measured first.

## Method

- Legitimate files: **19,997** files of 8 KiB or more, picked at random from `/usr`, `/System/Library`, `/Applications`, `/Library`
  and `~/Dev` on a Mac. Only the first 256 KiB was read and only statistics were computed (no content is output).
- Simulated encryption: 300 legitimate text files (extended to 256 KiB) were rewritten six ways: full, 16/32 (the first 16 of every
  32 bytes), alternate 4 KiB blocks, one region in four, the first 64 KiB, and Base64 (random bytes stand in for ciphertext).
- Features: whole-buffer entropy; entropy per 4 KiB chunk (7.9 or more counts as "high"), the share of high chunks, the longest run
  and the number of switches; the number of distinct byte values in each 16-byte block (14 or more looks random, 12 or fewer
  looks like text); the share of Base64 characters and how evenly the 64 symbols are used (chi-square per degree of freedom).
- "New false positives" are legitimate files that the current rule (whole ≥ 7.92) does not flag but the new rule does. The current
  rule already counts 10.4% of the files (photos, video, compressed data); that is handled by the writer allowlist and by the burst
  of 20 or more files.

## Results

| Rule (shape) | Simulated files detected | New false positives (of ~20,000 legitimate files) | What they were |
|---|---|---|---|
| Current: whole entropy ≥ 7.92 | full 100%, all others 0% | (baseline) 2,080 files (10.40%) | png, mov, jpg, caar, icns, caf |
| interleaved-16: random-looking and text-looking 16-byte blocks alternate (half or more of neighbouring pairs) | 16/32: 94% | **2 files (0.01%)** | plist 1, scn 1 |
| chunk-switching: 4 KiB chunks switch between high and low at least 4 times, 20–85% of them high | alternate 4 KiB 100%, one in four 100% | 206 files (1.03%) | jpg 82, car 70, caar 12, icns 10, png 8 |
| encrypted-head: a run of 8 or more high chunks (32 KiB), whole entropy below 7.92 | first 64 KiB: 100% | 227 files (1.14%) | jpg 88, caf 27, car 25, m4a 17, icns 17 |
| uniform-base64: over 99% Base64 characters, 64 symbols used evenly (chi² / d.o.f. < 2), entropy 5.7–6.05 | Base64: 100% | 0 files (0.00%) | (the sample has almost no legitimate Base64 files) |

## What was enabled

- **Only interleaved-16 is enforced** (it counts towards the burst that freezes a process). Its false-positive rate is 2 files
  (0.01%), and it detects 94% of the 16/32 partial encryption that the whole-buffer average could not see.
- **The other three run in shadow mode.** Writes are counted; when one process writes a burst of files of such a shape, the log
  says `ransomware shadow (nothing frozen)` with the shape's name, once. They never count as a detection and never freeze anything.
  Field data will decide whether to enforce them.
  - chunk-switching and encrypted-head flag about 1% of mixed media (jpg, Xcode assets, audio). Writers of that kind (image tools,
    builds) are already handled by the current rule and the allowlist, but the new share needs real data.
  - uniform-base64 has no false positives in the sample, **because the sample holds almost no legitimate Base64**. Any compressed
    data looks the same once Base64-encoded, so email attachments, files made with `base64`, and PEM bundles cannot be told apart
    by content. One file proves nothing; it takes the behaviour ("rewrites existing files in place, one after another, as Base64").

## Confirmed on a real kernel (Ubuntu 24.04 aarch64, real fanotify)

The simulator (`test/realhost/ransom_sim.pl`, 40 files) was run against the daemon with this change. The simulator's text was changed to
ordinary prose (GPL-3); the earlier pangram uses almost every letter in every 16-byte stretch, so it did not look like text.

| Simulation | Result |
|---|---|
| full | Detected and stopped with SIGSTOP (31 of 40 files encrypted by then) |
| partial (16 of every 32 bytes) | **Detected** (0 before). At full speed the simulator finishes all 40 files before the 20-file threshold is evaluated, so the process was already gone when the freeze came ("NOT frozen: process gone"). With 0.2 s per file it was stopped at 20 of 40, like full |
| b64 | Not counted as a detection; two shadow log lines (`uniform-base64`, 20 files each) |
| none (low entropy left as is) | Neither a detection nor a shadow line |

## What this does not do

- Ransomware written in a genuine allowlisted program (`python3` and the like) cannot be told apart by name (a limit of the design).
- Base64 cannot be judged by content alone (above).
- The simulation uses random bytes as ciphertext. Real encryptors produce almost the same statistics, but no real ransomware was measured.

## Reproduce

`test/realhost/ransom_shape_measure.py` (writes the features of the legitimate files to `legit.json`) and
`ransom_shape_eval.py` (prints detections and false positives per rule). Change the sampled folders with `roots` in `measure.py`.
