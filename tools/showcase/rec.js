const { chromium } = require('playwright');
const kind = process.argv[2];
const SEG = [["Appear", 7], ["Attack", 6], ["Skill 1", 8], ["Skill 2", 8], ["Death", 7]];
const NAMES = { dragon: ["FIRE DRAGON", ["Appear", "Fireball", "Roar: cards slowed", "Enrage: enemies x2 speed", "Death"]],
  kraken: ["KRAKEN", ["Rise from the deep", "Ink spit", "Tentacle grab", "Ink curse: cards blocked", "Death"]],
  soul: ["SOUL EATER", ["Appear", "Blue soulfire", "Soul Shield: enemies immune", "Souls rise", "Death"]] };
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 400, height: 860 }, deviceScaleFactor: 1, recordVideo: { dir: `/tmp/vid/${kind}`, size: { width: 400, height: 860 } } });
  const t0 = Date.now();
  const p = await ctx.newPage();
  await p.goto('http://127.0.0.1:8765/index.html');
  await p.waitForFunction(() => LOAD.ready && loadShown >= 1, null, { timeout: 120000 });
  await p.mouse.click(200, 500); await p.waitForTimeout(1200);
  await p.evaluate(kind => {
    const nb = document.getElementById('nameBox'); if (nb) nb.remove(); nameOpen = false; save.trained = true; save.tut = { lobby: true, run1: true, merge: true, spells: true, chamber: true, boss: true }; save.guide = true; tut = null;
    startRun(); bringPick = null; castleHp = castleMax = 5000; window.damageCastle = () => {}; window.freeSheet = () => {}; window.showInfo = () => {};
    const els = ["zeus", "phoenix", "armageddon", "kitsune", "black_hole"], rs = [LEGEND_R, MYTH, EPIC, MYTH, EPIC];
    els.forEach((e, i) => { rows.active[i] = new Card(e, rs[i]); const q = slotPos("active", i); rows.active[i].setHome(q.x, q.y, true); });
    const def = kind === "kraken" ? KRAKEN_DEF : kind === "soul" ? SOUL_DEF : DRAGON_DEF, dir = kind === "kraken" ? KRAKEN_DIR : kind === "soul" ? SOUL_DIR : DRAGON_DIR;
    for (const n of Object.keys(def.animations)) loadSheet(dir + def.animations[n].file);
    const lab = document.createElement("div"); lab.id = "lab";
    lab.style.cssText = "position:fixed;left:0;right:0;bottom:0;height:150px;background:linear-gradient(transparent,rgba(8,4,16,0.92) 35%);color:#fff;font:900 30px Cinzel Decorative,serif;text-align:center;padding-top:34px;z-index:9;text-shadow:0 2px 6px #000";
    document.body.appendChild(lab);
    window.__setLab = (a, b2, col) => { lab.innerHTML = `<div style="color:${col}">${a}</div><div style="font:800 21px Fredoka,sans-serif;margin-top:6px;color:#ffe9a8">${b2}</div>`; };
  }, kind);
  await p.waitForFunction(kind => { const def = kind === "kraken" ? KRAKEN_DEF : kind === "soul" ? SOUL_DEF : DRAGON_DEF, dir = kind === "kraken" ? KRAKEN_DIR : kind === "soul" ? SOUL_DIR : DRAGON_DIR; return Object.values(def.animations).every(a => loadSheet(dir + a.file).ready) && (kind !== "kraken" || loadSheet(KRAKEN_DIR + TENTACLE.file).ready); }, kind, { timeout: 60000 });
  await p.evaluate(() => { wave = 3; beginWave(true); });
  await p.waitForTimeout(2500);
  const [title, labels] = NAMES[kind], col = kind === "dragon" ? "#ff9a4a" : kind === "kraken" ? "#5ee0ff" : "#8ab8ff";
  const start = Date.now() - t0;
  const idle = () => p.waitForFunction(() => dragon && dragon.phase === "idle", null, { timeout: 20000 }).catch(() => {});
  const atk = async next => { await idle(); await p.evaluate(n => { dragon.next = n; dragon.cd = 0; }, next); };
  const plan = { dragon: ["shoot", "roar", "roar"], kraken: ["spit", "tentacle", "spit"], soul: ["shot", "shield", "summon"] }[kind];
  for (let i = 0; i < SEG.length; i++) {
    const segStart = Date.now();
    await p.evaluate(([a, b2, c]) => __setLab(a, b2, c), [title, labels[i] === SEG[i][0] ? SEG[i][0] : `${SEG[i][0]}: ${labels[i]}`, col]);
    if (i === 0) await p.evaluate(k => { if (k === "kraken") startKraken(); else if (k === "soul") startSoul(); else startDragon(); dragon.total = dragon.left = 6; }, kind);
    else if (i < 4) await atk(plan[i - 1]);
    else await p.evaluate(() => { const go = () => { if (!dragon || dragon.dying) return; dragonRuneHit(); setTimeout(go, 220); }; go(); });
    if (i >= 1 && i <= 3) await p.evaluate(() => { if (enemies.length < 12) beginWave(true); });
    const left = SEG[i][1] * 1000 - (Date.now() - segStart); if (left > 0) await p.waitForTimeout(left);
  }
  const total = SEG.reduce((a, s) => a + s[1], 0);
  require('fs').writeFileSync(`/tmp/vid/${kind}.json`, JSON.stringify({ start: start / 1000, total }));
  await ctx.close(); await b.close();
})();
