# Beanery — Design Notes

A portrait, offline-friendly café tycoon. You start with a tiny coffee stand, serve customers by
tapping, and grow the café little by little with smart money management until you can hire staff
who run it for you.

## Fixed rules (decided by the owner — do not change without asking)

### Ads: the player always chooses
- **No forced ads. Ever.** No banner ads, no pop-up ads between rounds, no surprise video ads.
- **Only rewarded ads**, and only when the player taps a button to watch one.
- Every ad offer has a clear way to say no (or can simply be ignored). Saying no has no penalty.
- Ad offers never appear in the middle of the action as a pop-up.
- When there is no internet connection, ad buttons are hidden and the game still works.
- Current rewarded ad offers:
  - **Rush hour:** 2x money for 2 minutes (5 minute cooldown).
  - **Offline earnings:** collect 2x on the welcome-back screen.
  - **VIP tip:** after serving a VIP guest, an optional chip offers a bonus tip.

### Purchases
- Optional and fair: no pay-to-win pressure.
- **Supporter pack:** get every ad reward without watching ads, as a thank-you for supporting.
- Coin packs.
- Purchases go through Google Play Billing (likely via RevenueCat) once the app is on Google Play.

### Platform and feel
- Portrait, one-handed play.
- Works fully **offline** (no internet needed), and the café **keeps earning while the game is closed**
  once you have hired baristas (capped at 4 hours).
- Play style: **active first, then automated** — tap to brew early on, then hire staff.
- Look: **clean and minimal**, slightly angled (isometric) view of the café.

## Game loop
1. Customers walk in, join the line and order something from your menu.
2. Tap **Brew** (or tap the café) to make the order. More taps make it faster.
3. Serving earns money. Customers who find a free seat pay 20% more.
4. Spend money on upgrades. Bigger upgrades unlock as you earn more.
5. Every in-game day (2 minutes) you pay rent and staff wages.

## What you can improve
| Area | What it does |
| --- | --- |
| Menu | Add new items (espresso → cold brew tonic) and raise their price with upgrades |
| Espresso machine | Every order is made 10% faster per level |
| Tables | Seated guests pay 20% more, and more seats bring more customers |
| Decor | 12 visible pieces (plants, lights, neon sign...) that bring more customers |
| Baristas | Make orders automatically. Train them to work faster. They earn wages |
| Cashier | +10% tips per level |
| Expansion | Coffee Stand → Cozy Café → Corner Café → Grand Café. Bigger room, more staff and tables, new menu items, higher rent |

## Current status (v0.1, test build)
- Single file: `index.html` (HTML, CSS, JavaScript, no downloads needed).
- Progress saves on the device automatically.
- Ads and purchases are **simulated** so the game can be tested. Real Google AdMob and Google Play
  Billing are connected later, when the Android app is set up.

## Roadmap
1. Play-test and tune: speed, prices, what feels good or annoying.
2. More menu items, decorations and café levels.
3. Android app wrapper (Capacitor) and a GitHub build for the Play Store file.
4. Real rewarded ads (AdMob, with the EU/UK consent screen) and real purchases.
5. Store listing: icon, screenshots, description, privacy policy.
