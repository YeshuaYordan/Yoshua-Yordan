// Medium-effort autoplayer: buys, merges, fuses, keeps its 5 strongest cards in battle, rerolls when rich,
// cures curses after a while, takes the first relic offered. No spells, no Chamber, no wild cards, no revive, no meta upgrades.
window.BOT = {
  power(c) {
    const d = EL[c.element]; if (d.special || d.totem) return 0;
    let p = damageOf(c.element, c.rarity) * rateOf(c.element, c.rarity) * (1 + (c.stars || 0));
    if (d.chain) p *= 1 + 0.6 * (d.chain - 1); if (d.pierce) p *= 1 + 0.4 * d.pierce; if (d.splash) p *= 1.6; if (d.multishot) p *= d.multishot;
    if (d.cloud || d.puddle) p *= 1.3; if (d.curse) p *= 1 + d.curse; return p;
  },
  board() { const out = []; for (const r of ["active", "storage"]) rows[r].forEach((c, i) => { if (c) out.push([r, i, c]); }); return out; },
  ok(c) { return c && !EL[c.element].special && !EL[c.element].totem; },
  mergeAll() {
    let did = true, n = 0;
    while (did && n++ < 40) { did = false;
      const b = this.board().filter(([, , c]) => this.ok(c));
      outer: for (let x = 0; x < b.length; x++) for (let y = 0; y < b.length; y++) { if (x === y) continue;
        const [ra, ia, a] = b[x], [rb, ib, c] = b[y];
        const res = merge(a.element, a.rarity, c.element, c.rarity, a.stars, c.stars);
        if (!res || res.totem) continue;
        if (ra === "active" && rb !== "active") continue;   // merge into the active one
        moveCard(ra, ia, rb, ib); did = true; break outer; }
    }
  },
  free() { for (let i = 0; i < SLOTS; i++) if (!rows.active[i]) return ["active", i]; for (let i = 0; i < rows.storage.length; i++) if (!rows.storage[i]) return ["storage", i]; return null; },
  shopBuy() {
    let bought = false;
    for (let si = 0; si < rows.shop.length; si++) { const c = rows.shop[si]; if (!this.ok(c)) continue;
      const cost = freeCard ? 0 : c.price; if (gold < cost) continue;
      // a merge target first
      const t = this.board().find(([, , o]) => this.ok(o) && (() => { const r = merge(c.element, c.rarity, o.element, o.rarity, c.stars, o.stars); return r && !r.totem; })());
      if (t) { if (buy(si, t[0], t[1])) { bought = true; continue; } }
      const f = this.free(); if (f && buy(si, f[0], f[1])) bought = true;
    }
    return bought;
  },
  arrange() {
    for (let k = 0; k < 6; k++) {
      const act = rows.active.map((c, i) => [i, c ? this.power(c) : -1]).sort((a, b) => a[1] - b[1])[0];
      const best = rows.storage.map((c, i) => [i, c && this.ok(c) ? this.power(c) : -1]).sort((a, b) => b[1] - a[1])[0];
      if (!best || best[1] <= act[1]) break;
      moveCard("storage", best[0], "active", act[0]);
    }
  },
  sellJunk() {
    if (this.free()) return;
    const w = rows.storage.map((c, i) => [i, c ? this.power(c) : 1e18]).sort((a, b) => a[1] - b[1])[0];
    if (w) sell("storage", w[0]);
  },
  chamber() {   // like a player: 4-5 spare Epics on the altars for a Myth; 5 spare Myths for a Legend
    const spare = (rar) => rows.storage.map((c, i) => [i, c]).filter(([, c]) => c && this.ok(c) && c.rarity === rar);
    for (const [rar, need, out, pool] of [[MYTH, 5, LEGEND, LEGEND_ELS], [EPIC, 4, MYTH, MYTH_ELS]]) {
      const sp = spare(rar).sort((a, b) => this.power(a[1]) - this.power(b[1])); if (sp.length < need) continue;
      const use = sp.slice(0, Math.min(5, sp.length)), n = use.length;
      const chance = rar === MYTH ? Math.min(LEGEND_MAX, n * LEGEND_PER_MYTH) : CHAMBER_CHANCE[n];
      for (const [i] of use) rows.storage[i] = null;
      this.stats.tries++;
      if (Math.random() * 100 < chance) { const c = new Card(pickOne(pool), out); const f = this.free(); if (f) { rows[f[0]][f[1]] = c; const s = slotPos(f[0], f[1]); c.setHome(s.x, s.y, true); } this.stats[out === LEGEND ? 'legend' : 'myth']++; }
    }
  },
  stats: { tries: 0, myth: 0, legend: 0 },
  curseT: {},
  act() {
    if (relicOffer) pickRelic(relicOffer.picks[0]);
    if (speedOffer) speedOffer = false;
    if (reviveOffer) { reviveOffer = null; gameOver(); return; }
    for (const k of curses) { this.curseT[k] = (this.curseT[k] || 0) + 0.5; if (this.curseT[k] > 15) { liftCurse(k); delete this.curseT[k]; } }
    if (state !== "wave" && state !== "break") return;
    this.mergeAll();
    let bought = this.shopBuy();
    this.mergeAll();
    if (!bought && gold > Math.max(25, rerollPrice() * 3)) { reroll(); this.shopBuy(); this.mergeAll(); }
    this.chamber(); this.sellJunk(); this.arrange();
    if (state === "break") beginWave(true);
  },
  run(maxSimSec) {
    let acc = 0; const dt = 1 / 30;
    for (let s = 0; s < maxSimSec * 30; s++) {
      update(dt); acc += dt;
      if (acc >= 0.5) { acc = 0; this.act(); }
      if (state === "gameover") break;
    }
    return { wave, state, gold: Math.round(gold) };
  },
};
