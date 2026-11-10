#!/usr/bin/env python3
"""Synthesize the Nothing sound theme: short percussive sine 'glyph' blips."""
import os, shutil, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "nothing", "stereo")

# event: [(freq Hz, duration s, gain), ...] played in sequence
EVENTS = {
    "message-new-instant": [(1568, .07, .5), (2093, .12, .45)],
    "dialog-information": [(1318, .09, .45), (1760, .14, .4)],
    "dialog-warning": [(880, .09, .5), (880, .09, .5), (659, .16, .45)],
    "dialog-error": [(523, .12, .55), (392, .2, .5)],
    "bell": [(1760, .1, .4)],
    "audio-volume-change": [(2637, .035, .35)],
    "device-added": [(1046, .06, .45), (1568, .1, .45)],
    "device-removed": [(1568, .06, .45), (1046, .1, .45)],
    "desktop-login": [(784, .08, .4), (1046, .08, .4), (1568, .08, .4), (2093, .22, .4)],
    "desktop-logout": [(2093, .08, .4), (1568, .08, .4), (1046, .18, .4)],
    "complete": [(1318, .06, .4), (1975, .14, .4)],
    "screen-capture": [(3136, .03, .3), (2349, .05, .3)],
}
ALIASES = {"service-login": "desktop-login", "service-logout": "desktop-logout",
           "battery-caution": "dialog-error", "power-plug": "device-added",
           "power-unplug": "device-removed", "message": "message-new-instant"}


def tone(f, d, g):
    return f"sine=f={f}:d={d},afade=t=in:d=0.004,afade=t=out:st=0.008:d={d - 0.008:.3f},volume={g}"


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, notes in EVENTS.items():
        args = ["ffmpeg", "-loglevel", "error", "-y"]
        for n in notes:
            args += ["-f", "lavfi", "-i", tone(*n)]
        chain = "".join(f"[{i}:a]" for i in range(len(notes)))
        args += ["-filter_complex", f"{chain}concat=n={len(notes)}:v=0:a=1,aecho=0.6:0.3:40:0.18,"
                 "aformat=sample_rates=48000:channel_layouts=stereo",
                 "-c:a", "libvorbis", "-q:a", "5", os.path.join(OUT, name + ".oga")]
        subprocess.run(args, check=True)
    for alias, src in ALIASES.items():
        shutil.copy(os.path.join(OUT, src + ".oga"), os.path.join(OUT, alias + ".oga"))
    with open(os.path.join(HERE, "nothing", "index.theme"), "w") as f:
        f.write("[Sound Theme]\nName=Nothing\nComment=Short, digital, dot-like tones\n"
                "Directories=stereo\n\n[stereo]\nOutputProfile=stereo\n")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
