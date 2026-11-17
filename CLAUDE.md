# Arcane Fusion: Merge & Defend — project notes

The game is live and in active development (the old "wait for go" rule no longer applies).

## Where things are
- Game: `web/index.html` (one file, canvas 2D, width 720) plus `web/assets/img`, `web/assets/audio`, `web/sprites/epic`.
- Android app wrapper: `app-android/` (package `arcanefusion.app`, WebView with WebViewAssetLoader; the build copies `web/`). Version 1.0.1 (code 2); bump versionCode for every new upload.
- Upload key: `app-android/upload-keystore.jks` + `UPLOAD_KEY_README.txt` (git-ignored; the user has a copy). Release copies go in `play-release/` (git-ignored).
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
- 10 Myths: Kitsune, Fenrir, Serpent, Phoenix, Cerberus, Basilisk, Griffin, Qilin, Kraken, Banshee. Legends: Zeus, Hades, Poseidon (more planned; user is making art).
- Shots: `VFX_STYLE`, `EPV` (head + trail + impact mixes). Sounds: `SAMPLE_SRC` (recorded) else `SOUND_OF` synth; `playSfx`.
- Shop / IAP: `SHOP_GEMS`, specials $4.99, Beginner Deal `STARTER_DEAL` ($1: 2,000 gems + Fight + Flight + Chalice, 24h, id `starter_deal`). Test mode when `window.nativePurchase` is missing.
- Castle & spell upgrades: `CASTLE_UPS`, `spellUpCost` (prices are 4x the original). Spell cast price x1.5 per cast per run (`spellCost`).
- Player name: first-launch panel, change once per 7 days (`openNameBox`, `NAME_COOLDOWN`).
- Loading screen: `drawLoading`, warm-up pre-draws every card (`WARM`), then "TAP TO START".
- `TESTER_RESET = true` shows the Reset/Test-cards buttons: set false for release.

## Testing
- Serve with `python3 -m http.server 8765 --bind 127.0.0.1` from `web/` (file:// can't load audio); kill it after. Playwright + Chromium are installed.
- Tests must tap once after loading (`LOAD.ready && loadShown >= 1`) to pass "TAP TO START".

## To do / ideas
- Legend cards (user sends art), ElevenLabs sounds for the new Specials and Myths.
- Release: TESTER_RESET=false, Google Play billing (product ids must match), optional AdMob, new Android build.
