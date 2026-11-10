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
  - **Power-ups** (Rush hour, Quick hands, Busy street, Tip jar): each can be started by watching an ad
    (with a cooldown) or by spending gems. The player picks.
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
- Screen: the café fills the **whole screen**. Swipe to move the camera, pinch (or mouse wheel) to zoom.
- Bottom dock with **4 buttons**: Upgrade, Decoration, Power-ups, Top-ups. Each opens a sheet above the dock.
  A Brew button sits above the dock, and tapping the café also brews.

### Currencies
- **Money:** earned from every sale. Pays for upgrades, decorations and expansion.
- **Gems:** for power-ups. Start with 10. +1 per day closed, +1 per VIP served, +5 per expansion,
  or bought in Top-ups.

## Game loop
1. Customers come in through the **one door** (left wall) and line up **in front of the cash register**.
2. Each customer is **dine-in** (chair icon) or **takeaway** (bag icon).
3. Tap **Brew** (or tap the café) to make the order. More taps make it faster.
4. Takeaway customers leave through the same door. Dine-in customers (pay 20% more) look for a free chair.
   - No free chair: they stand in the middle of the café for **15 seconds**. If a chair frees up they sit,
     otherwise they walk out and give **1 star**.
5. Spend money on upgrades. Bigger upgrades unlock as you earn more.
6. Every in-game day (2 minutes) you pay rent and staff wages.

## Ratings and reviews
- Every customer rates their visit from 1 to 5 stars. The café rating is the **average of the last 100 customers**.
- Stars come from how long they waited (fast = 5), decorations (small bonus chance), waiting for a chair (−1),
  giving up in line (1–2 stars) and finding no chair (1 star).
- Many customers also write a comment, picked at random from **satisfied, neutral and bad** comment lists that
  match their stars.
- The **phone button** (bottom right) opens the Beanery Reviews app: average rating, star breakdown, comments
  with filters, and a badge for new reviews.
- Rating matters: a 5-star café gets about 30% more customers than a 1-star café.

## What you can improve
| Area | What it does |
| --- | --- |
| Menu | Add new items (espresso → cold brew tonic) and raise their price with upgrades |
| Espresso machine | Every order is made 10% faster per level |
| Chairs | Bought one by one (a table comes with every 2 chairs). Dine-in guests need a free chair |
| Decoration | 12 pieces bought one by one (plants, lights, neon sign...). Each is visible and brings 12% more customers |
| Baristas | Make orders automatically. Train them to work faster. They earn wages |
| Cashier | +10% tips per level |
| Power-ups | Rush hour (2x money), Quick hands (2x work speed), Busy street (2x customers), Tip jar (instant cash) |
| Expansion | Coffee Stand → Cozy Café → Corner Café → Grand Café. Bigger room, more staff and tables, new menu items, higher rent |

Room sizes: Coffee Stand 9×9, Cozy Café 10×10, Corner Café 11×11, Grand Café 12×12 tiles.

## Current status (v0.3, test build)
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
