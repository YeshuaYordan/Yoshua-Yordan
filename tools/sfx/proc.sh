#!/bin/bash
# usage: CAP=seconds FO=fadeout TGT=LUFS [COMP=1] tools/sfx/proc.sh in.mp3 out.mp3  (trim silence, cap, fade, mono 44.1k 96k, loudness, limiter)
# trim leading silence, cap 1.4 s with fade-out, mono 44.1k, gain to about -12.5 LUFS with a limiter
in=$1; out=$2
pre="silenceremove=start_periods=1:start_threshold=-45dB,atrim=0:${CAP:-1.4},afade=t=in:d=0.005,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse"
tmp=$(mktemp --suffix=.wav)
ffmpeg -v error -y -i "$in" -af "$pre${COMP:+,acompressor=threshold=-30dB:ratio=6:attack=1:release=60:makeup=4}" -ac 1 -ar 44100 "$tmp"
d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$tmp")
fs=$(python3 -c "print(max(0,float('$d')-${FO:-0.25}))")
I=$(ffmpeg -nostats -i "$tmp" -af ebur128 -f null - 2>&1 | grep -E "^\s+I:" | tail -1 | awk '{print $2}')
g=$(python3 -c "print(${TGT:--12.5}-float('$I'))")
ffmpeg -v error -y -i "$tmp" -af "afade=t=out:st=$fs:d=${FO:-0.25},volume=${g}dB,alimiter=limit=0.95:level=false" -ac 1 -ar 44100 -b:a 96k "$out"
rm -f "$tmp"
