# Arcane Fusion: Merge & Defend — project notes

The game is live and in active development (the old "wait for go" rule no longer applies).

## Where things are
- Game: `web/index.html` (one file, canvas 2D, width 720) plus `web/assets/img`, `web/assets/audio`, `web/sprites/epic`.
- Android app wrapper: `app-android/` (package `arcanefusion.app`, WebView with WebViewAssetLoader; the build copies `web/`). Version 1.1.0 (code 3, built and signed 2026-11-17, never uploaded to Play yet, so code 3 can still be used for the first upload); bump versionCode for every upload after that. Play Billing: `PlayBilling.java` (billing 7.1.1) exposes `window.AndroidBilling`; the game's bridge is next to `productById` / `__grantOwned` in index.html. Compiles fine; real purchases not tested yet.
- Upload key: `app-android/upload-keystore.jks` + `UPLOAD_KEY_README.txt` (git-ignored; the user has a copy). The old key was lost; a new one was made 2026-11-17 (alias `upload`) before any Play upload, so it is the app's only upload key. If it's missing in a session, ask the user to attach the .jks and its README. Release copies go in `play-release/` (git-ignored).
- Branch: `claude/game-project-mzv2uw`. Web preview artifact: https://claude.ai/artifact/Hdh3dPfxfE5bTdbZwXqT9X (republish `web/index.html`; new asset files need a `files` map, e.g. `{"assets/img/x.webp": "web/assets/img/x.webp"}`).
- Android SDK goes in `/opt/android-sdk` (the user accepted the license; host dl.google.com is allowed). Maven Central rate-limits: build with `gradle --no-daemon -q --max-workers=1 bundleRelease assembleRelease`, retry on 429.

## User rules (always follow)
- Never put "claude" or "anthropic" in game files (grep before committing).
- Do NOT send .apk/.aab files or make Android builds unless the user asks.
- Don't make the public itch build unless asked; give the tester zip only when asked.
- Don't weaken enemies. Ads always optional. Keep graphics unchanged when optimizing.
- After every game change, republish the web preview artifact and send the user the link.
- Ask before unexpected changes. Keep replies short; skip browser tests and screenshots for simple changes (save the user's credits).
- All Legend cards use the gold frame; Myth cards use the Phoenix Myth frame.
- Kitsune and Fenrir keep their original shots (`foxfire`, `fenrir`): don't redesign them. The other 7 Myths use `MYTHFX` (`mx_<card>`) shots; Myth medals are `assets/img/<card>_medal.webp`.

## Game systems (quick map, search these names in index.html)
- Cards: `EL` table. Myth = `myth: true` + `art` (448x544 webp) + `medal: [x, y, size]` face crop. Legend = `legendCard: true`. Special = `special: true`; totems/idols use `totem` kind, never attack, 1 per board, power up by dropping copies (Lv1-5).
- 10 Specials: Fight, Flight, Midas, Mirror, Hourglass, Bulwark, Seer, Chain(`chainlink`), Chalice, Hex (`IDOL_VAL`, `drawIdolCard`, `drawIdolEmblem`).
- 10 Myths: Kitsune, Fenrir, Serpent, Phoenix, Cerberus, Basilisk, Griffin, Qilin, Kraken, Banshee. 10 Legends: Zeus, Hades, Poseidon + Athena, Ares, Apollo, Artemis, Hermes, Hephaestus, Hera (shots in `MYTHFX`). Their art is in `assets/img/<god>.webp` (448x544, cropped from the user's 1024x1536 art); orbit icons in `LEGEND_ORBIT`, card auras in `LEGEND_AURA` (back sigil, edge, over-art; theme = god name; sigils drawn in a pre-pass in `drawWorld`, `GOD_BACK_OFF`; Zeus/Poseidon/Hades sigils in `LEGEND_BACK`, all at `GOD_BACK_SCALE`). Greek Legend shots drawn at `LEGEND_SHOT_K` to match the old Legends. A card with `wip: true` stays out of drops (`LEGEND_ELS`). Ares `frenzy`, Hera `aura` (`heraAura`).
- Shots: `VFX_STYLE`, `EPV` (head + trail + impact mixes). Sounds: `SAMPLE_SRC` (recorded) else `SOUND_OF` synth; `playSfx`.
- Shop / IAP: `SHOP_GEMS`, specials $4.99, Beginner Deal `STARTER_DEAL` ($1: 2,000 gems + Fight + Flight + Chalice, 24h, id `starter_deal`). Test mode when `window.nativePurchase` is missing.
- Castle & spell upgrades: `CASTLE_UPS`, `spellUpCost` (prices are 4x the original). Spell cast price x1.5 per cast per run (`spellCost`).
- Player name: first-launch panel, change once per 7 days (`openNameBox`, `NAME_COOLDOWN`).
- Front camera: the canvas fills the screen; everything is drawn `TOP` units lower (`setSafeTop` from MainActivity's cutout inset, or `env(safe-area-inset-top)`). Canvas height is `H + TOP`; full-screen fills/clips use `(0, -TOP, W, H + TOP)`; `lobbyView` covers the strip; `toLogical` subtracts `TOP`.
- Loading screen: `drawLoading`, warm-up pre-draws every card (`WARM`), then "TAP TO START".
- `TESTER_RESET` is now false (release). Set it true only for a private test build.
- Play Console in-app products (all one-time "in-app" products): consumable gem packs gems_250, gems_1500, gems_4000, gems_10000, gems_35000, gems_100000; one-time (never consumed) speed_2x, starter_deal, special_totem, special_flight, special_midas, special_mirror, special_hourglass, special_bulwark, special_seer, special_chainlink, special_chalice, special_hex.

## Testing
- Serve with `python3 -m http.server 8765 --bind 127.0.0.1` from `web/` (file:// can't load audio); kill it after. Playwright + Chromium are installed.
- Tests must tap once after loading (`LOAD.ready && loadShown >= 1`) to pass "TAP TO START".

## To do / ideas
- Summon sounds: `summon_<rise|zap|step|implode|boom|boom_epic|boom_legend|flip|flip_rare>` played by `summonSfx` (synth is the fallback). Done: `_atk`/`_hit` sounds for the 7 Greek Legends. Done: Special sounds (`sp_<card>_up` on power-up for all 10, `sp_<card>` when an idol triggers, via `playSpecial` with cooldowns). Also done: `_atk`/`_hit` sounds for Serpent, Cerberus, Basilisk, Griffin, Qilin, Kraken, Banshee (loudness matched to `serpent_atk.mp3`, about -12.5 LUFS, max 1.4 s).
- 40 more Epics (`ep2: true`, after Polar Night in `EL`): now every pair of different Next elements fuses (105 Epics). Single form, emblems in `sprites/epic/<key>.webp` (the user's V3 art, 12 frames at 128 px). Shots: `EP2` = [head, Dark/Light trail + accent, classic impact]. Sounds: one file `assets/audio/epic40_sounds.mp3`, sliced by `EPIC40_PACK` (`pack:` URIs in `loadAudioBytes`). Chain shots skip splash/pools/clouds (only `applyHit` does those).
- Web preview limit: 511 files per version; it holds 503 now. Pack new sounds/images into fewer files before adding more.
- Publishing is on hold: the user wants to polish the game first. Release checklist for later: build 1.1.0 (code 3) and test a real purchase with a Play license tester; create the products above in Play Console; optional AdMob; store listing, privacy policy, data safety, content rating; closed test if the account needs it.
