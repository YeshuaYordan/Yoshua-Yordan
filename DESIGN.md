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
  - **Power-ups** (Rush hour, Busy street, Tip jar): each can be started by watching an ad
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

### Code and repo
- Keep tool and assistant names out of the game files, code comments and commit messages.
- Web builds for itch.io: `tools/build_web.sh beanery-web.zip`, then upload the zip as an HTML game played in the browser.

## Game loop
1. Customers come in through the **one door** (left wall) and line up **in front of the cash register**.
2. Each customer is **dine-in** (chair icon, 40%) or **takeaway** (bag icon, 60%).
3. Tap **Brew** (or tap the café) to make the order. More taps make it faster.
4. Takeaway customers leave through the same door. Dine-in customers (pay 20% more) look for a free chair.
   - No free chair: they go to the marked **"Waiting for a seat" area** (12 numbered spots, one guest per spot,
     left of the line) for **15 seconds**. If a chair frees up they sit, otherwise they walk out and give **1 star**.
   - The waiting area is fixed against the **left wall**, so it stays in the same place when the café expands.
   - A chip at the top shows how many guests are waiting for a chair. Tapping it opens the Chairs upgrade
     (or reminds you to clean tables when dirty ones are blocking seats).
   - **Dirty tables:** when a dine-in guest leaves, the dish for what they ordered stays on the table
     (coffee leaves a cup, cold drinks a glass, food a plate with crumbs). That seat can't be used until the player
     **taps the table** to clean it. Dirty tables pulse and show "Tap to clean".
5. Spend money on upgrades. Bigger upgrades unlock as you earn more.
6. One in-game day lasts **30 real minutes**. At the end of the day you pay rent and staff wages and get +3 gems.
   (Rent and wages were scaled up 15x when days went from 2 to 30 minutes, so the cost per minute is unchanged.)

## Customer flow
- Upgrades set the café's **pull**: 1 customer every **5 seconds** at the start (tripled in v0.8 so there is
  usually a line, which gives the player time to spot a thief).
  Each decoration +15%, each extra chair +5%, each extra menu item +10%, each café level +50%.
- The rating then scales that pull: **flow = pull × (rating ÷ 5)**.
  - 5★ = 100% (pull of 1/5s stays 1/5s)
  - 4★ = 80% · 3★ = 60%
  - 2.5★ = 50% (1/5s becomes 1/10s)
  - 2★ = 40% · 1★ = 20%
  - No ratings yet counts as 5★.
- Upgrade → Equipment shows the current pull, the rating's share and the result.

## Thief
- **5%** of new customers are thieves. A thief looks exactly like one of the normal customers, with an order
  bubble too, but wears a **red scarf**. Spotting it is the challenge.
- Thieves never get served. If a thief reaches the **front of the line at the register**, they steal a random
  **10–70% of the player's current money** and run out of the door.
- To stop a thief: **press and hold** them for **1 second** (a ring fills above their head). They run out empty-handed.
  Holding a normal customer does nothing ("Just a customer"). A quick tap still brews or cleans.
- The first thief of a save shows a one-time tip.

## Ratings and reviews
- Only **50% of customers** leave a rating (the same chance for happy and unhappy customers).
  The café rating is the **average of the last 100 ratings**. 60% of raters also write a comment.
- Stars come from how long they waited (fast = 5), decorations (small bonus chance), waiting for a chair (−1),
  giving up in line (1–2 stars) and finding no chair (1 star).
- Comments are picked at random from **satisfied, neutral and bad** comment lists that match their stars.
- The **phone button** (bottom right) opens the Beanery Reviews app: average rating, star breakdown, comments
  with filters, and a badge for new reviews.
- Rating matters: see Customer flow above.

## What you can improve
| Area | What it does |
| --- | --- |
| Menu | Add new items (espresso → cold brew tonic) and raise their price with upgrades |
| Chairs | Bought one by one (a table comes with every 2 chairs). Dine-in guests need a free chair |
| Decoration | 12 pieces bought one by one (plants, lights, neon sign...). Each is visible and brings 12% more customers |
| Baristas | Make orders automatically, one at a time. They earn wages |
| Cashier | +10% tips per level |
| Power-ups | Rush hour (2x money), Busy street (2x customers), Tip jar (instant cash) |
| Expansion | Coffee Stand → Cozy Café → Corner Café → Grand Café. Bigger room, more staff and tables, new menu items, higher rent |

Room sizes: Coffee Stand 9×9, Cozy Café 10×10, Corner Café 11×11, Grand Café 12×12 tiles.

## Characters
- Drawn in code as pixel art in `characters.js` (loaded by `index.html`). Frames are 20 x 32 art pixels,
  scaled up with crisp pixels. Each character has **one fixed look** (no recolours).
- **Customers (10):** student, office worker, grandma, kid, hoodie guy, hijab lady, artist, runner,
  businesswoman, bookworm. The same person never comes in twice in a row.
- **Baristas (4):** white shirt and green apron, each with their own face and hair. Customers never use these looks.
- **Views:** 3/4 front (toward the camera) and 3/4 back (away), mirrored for left/right, so 4 walking directions.
- **Walk:** 4 frames. Wide step, then the back leg swings forward lifted with a bent knee, then the other side.
  Arms stay attached at the shoulder and swing opposite to the legs; the body bobs on the passing frames.
- **Standing:** in line they face the register (back view); in the waiting area they face the camera. They blink now and then.
- **Seated:** guests sit on the café's own chairs and only the upper body is drawn.
  - Far side of a table: facing the camera; the table hides the lower body; they lift the cup or food to the mouth.
  - Near side: back to the camera; the chair back covers the lower back; the elbow lifts and the cup peeks out.
  - Food → eating animation, drinks → drinking animation.
- The owner's earlier pixel-art sheet is kept in `assets/characters/girl-source.png`, with `tools/slice_sprites.py`
  for cutting future sheets, but the game no longer uses it.

## Current status (v0.8, test build)
- v0.8 removed every speed upgrade (espresso machine, barista training, Quick hands power-up).
  Orders take the item's own time; only the player's taps speed them up.
- Menu prices doubled in v0.4 because customers now arrive less often.
- `index.html` (game) + `characters.js` (character art). No other downloads needed.
- Progress saves on the device automatically.
- Ads and purchases are **simulated** so the game can be tested. Real Google AdMob and Google Play
  Billing are connected later, when the Android app is set up.

## Roadmap
1. Play-test and tune: speed, prices, what feels good or annoying.
2. More menu items, decorations and café levels.
3. Android app wrapper (Capacitor) and a GitHub build for the Play Store file.
4. Real rewarded ads (AdMob, with the EU/UK consent screen) and real purchases.
5. Store listing: icon, screenshots, description, privacy policy.
