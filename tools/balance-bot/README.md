# Balance bot

A test player for tuning enemy difficulty. It buys, merges, fuses, uses the Fusion Chamber, keeps its 5 strongest
cards in battle, rerolls when rich, cures curses after 15 s and takes the first relic. No spells, no wild cards,
no revive, no Summon/castle upgrades. The game runs headless at full speed (a run takes a few seconds).

    cd web && python3 -m http.server 8765 --bind 127.0.0.1 &
    cd tools/balance-bot && node runbot.js 8      # 8 runs in parallel, prints the wave each run reached

2026-11-19 tuning (hpScale = (1 + 0.18w) * 1.034^w): 16 runs reached waves 39-79, middle about 54, 5 of 16 past 70.
The old curve stopped every run at waves 26-30.
