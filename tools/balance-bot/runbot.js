const { chromium } = require('playwright'); const fs = require('fs');
const RUNS = +(process.argv[2] || 3);
(async () => { const b = await chromium.launch();
  const results = [];
  await Promise.all(Array.from({ length: RUNS }, async (_, r) => {
    const p = await b.newPage({ viewport: { width: 400, height: 860 } });
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.goto('http://127.0.0.1:8765/index.html');
    await p.waitForFunction(() => LOAD.ready && loadShown >= 1, null, { timeout: 120000 });
    await p.mouse.click(200, 500); await p.waitForTimeout(1500);
    await p.evaluate(() => { const nb = document.getElementById('nameBox'); if (nb) nb.remove(); window.tutStart = () => {}; tut = null; window.requestAnimationFrame = () => 0; });
    await p.waitForTimeout(300);
    await p.addScriptTag({ path: 'bot.js' });
    await p.evaluate(() => { startRun(); });
    const t0 = Date.now(); let last;
    for (let k = 0; k < 400; k++) { last = await p.evaluate(() => BOT.run(120)); if (last.state === 'gameover' || last.wave >= 130) break; }
    const st = await p.evaluate(() => BOT.stats); results[r] = { stats: st, wave: last.wave, state: last.state, secs: Math.round((Date.now() - t0) / 1000), errs: errs.slice(0, 2) };
    console.log('run', r, JSON.stringify(results[r]));
  }));
  await b.close(); })();
