# Arcane Fusion – Play Store launch guide

Everything you need to fill in on Google Play Console, in order. Files in this folder:

- `icon_512.png` – app icon (512 x 512)
- `feature_graphic_1024x500.png` – feature graphic
- `1_battle.png` … `7_summon.png` – phone screenshots (1080 x 1920)
- `privacy_policy.html` – privacy policy (fill in the `[...]` parts, then put it online, see step 2)

---

## 1. Store listing (Grow > Store presence > Main store listing)

**App name (max 30):**
Arcane Fusion: Merge & Defend

**Short description (max 80):**
Merge elemental cards, fuse legends and defend your castle from endless waves!

**Full description:**

> Merge. Fuse. Defend.
>
> Monsters march on your castle in endless waves. Buy elemental cards, merge them into stronger spirits and fuse elements into new powers: Fire + Water makes Steam, Fire + Earth makes Lava, and over 100 Epic fusions are waiting to be discovered.
>
> ⚔️ MERGE & FUSE – Combine Fire, Water, Earth, Wind, Light and Dark into Next elements, Epics, Myths and Legends. Every card has its own shot and power.
>
> 🐉 EPIC BOSSES – Face the Fire Dragon, the Kraken and the Soul Eater. Draw magic runes with your finger to strike them down.
>
> ✨ MYTHS, LEGENDS & DIVINE CARDS – Fuse Epics in the Chamber to summon Kitsune, Phoenix, Kraken and more. Raise Zeus, Hades, Poseidon and the Greek gods. Offer the right recipe at the Divine Altar to ascend Divine cards like Nyxarion, Elyndor and Tychor.
>
> 🔮 SPELLS – Draw runes to cast Meteor, Freeze, Earthquake, Rewind and the devastating Doom.
>
> 🏰 ENDLESS WAVES – Six lands, elite enemies with special traits, stage blessings, relics, curses and combos. How far can you go?
>
> 🏆 DAILY CHALLENGE & LEADERBOARDS – A new challenge every day, quests, missions, achievements and Google Play Games leaderboards.
>
> ☁️ CLOUD SAVE – Sign in with Google Play Games to keep your progress on a new phone.
>
> Free to play. Ads are always optional. Contains optional in-app purchases.

**Category:** Game > Strategy (or Casual) · **Tags:** Tower defense, Card game, Merge
**Contact email:** your email · **Privacy policy:** the URL from step 2
**Graphics:** upload the icon, feature graphic and 2–8 of the screenshots above.

## 2. Privacy policy (required)

1. Open `privacy_policy.html`, replace `[DATE]`, `[DEVELOPER NAME]` and `[YOUR EMAIL]`.
2. Put it online at a public link, for example a free **Google Sites** page (paste the text) or GitHub Pages.
3. Paste that link in Play Console: **Policy > App content > Privacy policy**, and in the store listing.

## 3. In-app products (Monetize > Products > In-app products)

Create these as one-time products (ids must match exactly):

| Product id | Price | Notes |
|---|---|---|
| gems_250 | $0.99 | consumable (250 gems) |
| gems_1500 | $4.99 | consumable (1,500) |
| gems_4000 | $9.99 | consumable (4,000) |
| gems_10000 | $19.99 | consumable (10,000) |
| gems_35000 | $49.99 | consumable (35,000) |
| gems_100000 | $99.99 | consumable (100,000) |
| speed_2x | $0.99 | unlock |
| no_ads | $4.99 | unlock |
| starter_deal | $1.00 | Beginner Deal (2,000 gems + Fight, Flight, Chalice) |
| hex_deal | $3.00 | Hex Deal (5,000 gems + Hex) |
| pick2_deal | $3.00 | Pick 2 Deal (any 2 Specials) |
| special_totem, special_flight, special_midas, special_mirror, special_hourglass, special_bulwark, special_seer, special_chainlink, special_chalice, special_hex | $2.99 each | Special cards |

The game decides which ones are "consumed" (gems) by itself; in Play Console they are all normal one-time products.

## 4. AdMob (real ads)

1. Create an account at **admob.google.com**, add the app (Android, "Arcane Fusion").
2. Create one **Rewarded** ad unit.
3. **Privacy & messaging > European regulations**: create and publish a GDPR consent message for the app (the game shows it automatically to players in Europe; without it ads may not show there).
4. Send me the **App ID** (`ca-app-pub-…~…`) and the **Rewarded ad unit ID** (`ca-app-pub-…/…`). Until then the app uses Google's test ads.
5. Optional but recommended later: an `app-ads.txt` file on your developer website.

## 5. Play Games Services (leaderboards + cloud save)

1. Play Console > **Play Games Services > Setup and management > Configuration** > create a new game project for this app.
2. **Credentials**: create an Android OAuth credential. Add the **SHA-1 of the App signing key** (Setup > App signing) – and the SHA-1 of the upload key for testing builds.
3. **Saved Games**: turn **ON** (needed for cloud save).
4. **Leaderboards**: create two (both "Higher is better", integer):
   - "Best Wave" (waves cleared in a normal run)
   - "Boss Break Out" (bosses killed in Boss Break Out)
5. Publish the Play Games configuration, add your test accounts as **testers** there.
6. Send me: the **project ID** (a number) and the two **leaderboard IDs** (`Cgk…`).

## 6. App content forms (Policy > App content)

**Ads:** Yes, the app contains ads.

**Target audience:** 13+ (recommended; choosing younger ages brings extra Families-policy rules for ads and purchases).

**Data safety** (suggested answers – compare with Google's AdMob and Play Games data-disclosure pages before submitting):
- Does the app collect or share user data? **Yes**.
- **Device or other IDs** (advertising ID): collected and shared, by AdMob – purposes: Advertising or marketing, Analytics, Fraud prevention. Not optional? Choose "users can't turn it off" (ads ask consent in the EEA).
- **Location > Approximate location** (from IP, by AdMob): collected and shared – Advertising, Analytics, Fraud prevention.
- **App activity > App interactions** (ad interactions, by AdMob): collected and shared – Advertising, Analytics.
- **App info and performance > Crash logs / Diagnostics** (by AdMob SDK): collected – Analytics.
- **App activity > Other actions / In-app progress** (cloud save in the player's Google account, by Play Games): collected, not shared – App functionality; optional (only when signed in).
- Data encrypted in transit: **Yes**. Users can request deletion: **Yes** (by email, and through Google Play Games settings).
- Purchases are processed by Google Play and do not need to be declared as "collected" by you.

**Content rating questionnaire (IARC):** category **Game**. Suggested answers:
- Violence: **Yes – fantasy / cartoon violence** against monsters, no blood or gore.
- Fear, sex, language, drugs: **No**.
- **In-app purchases: Yes**. **Random items purchasable** (loot boxes): **Yes** – Summon gives random cards and gems can be bought. (The game shows the odds in "Rates".)
- **Simulated gambling:** the Divine card Tychor shows a slot machine as a battle effect (no betting, no money in or out). Answer **No** unless you prefer to be extra careful; answering Yes usually raises the age rating.
- Users interact / share info / location: **No**.

**News app / COVID / Government:** No. **Financial features:** No. **Health:** No.

## 7. Closed test (needed for new personal developer accounts)

1. **Testing > Closed testing** > create a track (e.g. "Alpha"), upload the release `.aab` I build.
2. Add at least **12 testers** (a Google Group or an email list); they must **opt in** with the link and **keep the app installed for 14 days**.
3. After 14 days with 12+ testers, apply for **Production access** in the Dashboard and answer the questions about your test.
4. Then publish to Production (Google reviews it, usually a few days).

## 8. Before the final release build (I do these)

- Real AdMob IDs and Play Games IDs in the app.
- Version: first upload uses version code 3 (1.1.0); every later upload gets a higher code.
- Tester tools (TEST card picker, reset) are switched off automatically in the Android app.
- Sign with your upload key (`upload-keystore.jks`).
