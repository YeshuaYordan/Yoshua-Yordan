# Arcane Fusion: Merge & Defend

A portrait mobile game for Android, built with **Godot 4.3**. You merge elemental spirit cards to defend your castle against endless waves of shadow creatures.

> **Status: Step 1, playable prototype.** All art is drawn by code as placeholders. Ads and in-app purchases come in step 3.

## How to play
- Enemies march down toward the castle wall, and each wave is stronger than the last.
- **Battle slots** (the top row of 5): only cards here attack.
- **Storage** (the second row of 5): keeps cards safe, but they don't attack.
- **Shop** (3 cards): tap a card to buy it into the first free slot, or drag it onto a slot. Your **first card is free**. After that, cards and **Reroll** both cost gold.
- **Merge** by dragging one card onto another, either in battle or storage. This works even during a wave.
  - Same element and same rarity: the card goes up one rarity (Common → Uncommon → Rare → Epic → Myth → Legend).
  - Two different elements make a new element, which keeps the lower rarity.
- **Sell** a card by dragging it onto the shop table.
- **Spellbook** (the Book button): shows the recipes you've discovered. New ones show as `???` until you find them.
- Between waves there's a short break. Tap **Start Wave** to go early.

### Fusion recipes (spoilers!)
| Tier II | | Tier III | |
|---|---|---|---|
| Fire + Water | Steam (damaging cloud) | Lightning + Water | Storm (chains 5 and slows) |
| Fire + Earth | Lava (burning pools) | Ice + Wind | Blizzard (slows an area) |
| Fire + Wind | Lightning (chains 3) | Lava + Water | Obsidian (pierces 5) |
| Water + Earth | Plant (roots enemies) | Plant + Earth | Grove (roots an area) |
| Water + Wind | Ice (slows) | Plant + Fire | Wildfire (burns an area) |
| Earth + Wind | Sand (knockback) | Sand + Lightning | Crystal (3 shots) |

Enemies: Grunt, Runner (fast), Tank (tough), Flyer (weak to Wind, resists Earth), and a Boss every 10 waves. From wave 8, some enemies have an elemental aura. They resist their own element and are weak to its counter (Water > Fire > Wind > Earth > Water).

## Running it on your computer
1. Download **Godot 4.3** (standard version) from https://godotengine.org/download/archive/4.3-stable/
2. Open Godot, click **Import**, and choose the `project.godot` file in this folder.
3. Press **F5** (or the ▶ Play button at the top right).

## Project layout
| Path | What it is |
|---|---|
| `scripts/card_db.gd` | All elements, stats, recipes, rarities, shop odds and save data |
| `scripts/game.gd` | Main game: board, drag & merge, shop, waves, UI |
| `scripts/card.gd` | Drawing and animation for a card |
| `scripts/enemy.gd` | Enemy types, movement and status effects |
| `scripts/projectile.gd`, `zone.gd`, `fx.gd` | Shots, lingering clouds and pools, visual effects |
| `shaders/vintage.gdshader` | Vintage film grain and vignette overlay |
| `tests/test.gd` | Automated tests and a bot that plays the game |

Run the tests:
```
godot --headless --path . --fixed-fps 60 res://tests/test.tscn
```

## Roadmap
1. ~~Prototype~~ ✅
2. Polish: balance, sounds and music, real art, main menu, permanent upgrades
3. Monetization: AdMob rewarded ads (revive, double gold, free reroll), interstitials after game over, Google Play Billing (Remove Ads, gems, cosmetics)
4. Play Store release: Android export, signing, privacy policy, store listing
