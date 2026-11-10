/* Beanery characters: hand-placed pixel art drawn in code.
 *
 * Every character is a different person with one fixed look (no recolors).
 * Frames are 20 x 32 art pixels, drawn once and cached, then scaled up with crisp pixels.
 *
 * Views (the art faces to the right; mirror it for the left-facing directions):
 *   front  - 3/4 view facing down-right, toward the camera   (mirror = down-left)
 *   back   - 3/4 view facing up-right, away from the camera   (mirror = up-left)
 * Poses:
 *   walk      4 frames: step, pass, step, pass (legs alternate, arms swing, body bobs)
 *   idle      2 frames: normal, blink
 *   eat/drink 4 frames, seated (upper body + thighs only, so a table in front hides the rest)
 *
 * Anchors (art pixels): standing frames stand on row 31 at x 10; seated frames sit with hips on row 25 at x 10.
 */
(function (global) {
  'use strict';
  const CW = 20, CH = 32, FOOT_Y = 31, HIP_Y = 25, CX = 10, TOP_PAD = 2;

  function shade(hex, k) {
    const n = parseInt(hex.slice(1), 16);
    const ch = [n >> 16, (n >> 8) & 255, n & 255].map(v => Math.max(0, Math.min(255, Math.round(k < 1 ? v * k : v + (255 - v) * (k - 1)))));
    return '#' + ch.map(v => v.toString(16).padStart(2, '0')).join('');
  }

  /* ---------- The cast ---------- */
  const CUSTOMERS = [
    { id: 'student', name: 'Student', skin: '#F4D4BC', hair: { style: 'long', c: '#3A2B2E' },
      top: { style: 'sailor', c: '#F4F1EA', a: '#2F3E63', b: '#C2453D' }, bottom: { style: 'skirt', c: '#2F3E63' }, legs: '#F4D4BC', shoes: '#3A2E2E',
      bag: { style: 'backpack', c: '#E08A4F' } },
    { id: 'office', name: 'Office worker', skin: '#E8B990', hair: { style: 'short', c: '#1F1B1E' },
      top: { style: 'shirtTie', c: '#CFE0EE', a: '#2B3A5C' }, bottom: { style: 'pants', c: '#5A5E66' }, shoes: '#2A2526' },
    { id: 'grandma', name: 'Grandma', skin: '#F1CDB4', hair: { style: 'bun', c: '#CBC6C2' }, glasses: true,
      top: { style: 'cardigan', c: '#A78BB6', a: '#F2EAD8' }, bottom: { style: 'longskirt', c: '#7A5A44' }, shoes: '#5A3F33' },
    { id: 'kid', name: 'Kid', skin: '#F7D8C0', hair: { style: 'short', c: '#6B4226' }, hat: { style: 'cap', c: '#D8433B' }, scale: .84,
      top: { style: 'tee', c: '#F2C94C' }, bottom: { style: 'shorts', c: '#3E6FB5' }, legs: '#F7D8C0', shoes: '#F4F4F4' },
    { id: 'hoodie', name: 'Hoodie guy', skin: '#C98E63', hair: { style: 'messy', c: '#4A3022' },
      top: { style: 'hoodie', c: '#5E8C61' }, bottom: { style: 'pants', c: '#2F3B52' }, shoes: '#E9E6DF' },
    { id: 'hijab', name: 'Hijab lady', skin: '#E4B28E', hair: { style: 'hijab', c: '#C98B8B' },
      top: { style: 'tunic', c: '#3F6E73', a: '#E7D6B8' }, bottom: { style: 'longskirt', c: '#2F3B4A' }, shoes: '#4A3A30',
      bag: { style: 'handbag', c: '#B07A3A' } },
    { id: 'artist', name: 'Artist', skin: '#F2CFB3', hair: { style: 'bob', c: '#9A4A2A' }, hat: { style: 'beret', c: '#7A2E3B' },
      top: { style: 'stripe', c: '#F4F1EA', a: '#2E3D5C' }, bottom: { style: 'pants', c: '#232325' }, shoes: '#7A2E3B' },
    { id: 'runner', name: 'Runner', skin: '#8D5A3B', hair: { style: 'ponytail', c: '#1E1A1A' }, hat: { style: 'headband', c: '#F2F2F2' },
      top: { style: 'sport', c: '#F07B3F', a: '#FFFFFF' }, bottom: { style: 'pants', c: '#1F2328' }, shoes: '#3FA7D6' },
    { id: 'business', name: 'Businesswoman', skin: '#F0C8A8', hair: { style: 'bob', c: '#2A2024' },
      top: { style: 'blazer', c: '#3A3F4A', a: '#F4F1EA' }, bottom: { style: 'skirt', c: '#3A3F4A' }, legs: '#3A3F4A', shoes: '#1E1E22',
      bag: { style: 'handbag', c: '#B5362F' } },
    { id: 'reader', name: 'Bookworm', skin: '#D9A47E', hair: { style: 'curly', c: '#2E2320' }, glasses: true,
      top: { style: 'sweater', c: '#D9A43A' }, bottom: { style: 'pants', c: '#9C8A66' }, shoes: '#5A3F2E',
      bag: { style: 'messenger', c: '#7A5236' } },
  ];
  const STAFF = [
    { id: 'barista1', name: 'Barista', skin: '#E8B990', hair: { style: 'short', c: '#2B2522' }, hat: { style: 'cap', c: '#2F6B55' },
      top: { style: 'apron', c: '#F4F1EA', a: '#2F6B55' }, bottom: { style: 'pants', c: '#2E3430' }, shoes: '#2E3430' },
    { id: 'barista2', name: 'Barista', skin: '#F2CFB3', hair: { style: 'bun', c: '#6B4226' },
      top: { style: 'apron', c: '#F4F1EA', a: '#2F6B55' }, bottom: { style: 'pants', c: '#2E3430' }, shoes: '#2E3430' },
    { id: 'barista3', name: 'Barista', skin: '#8D5A3B', hair: { style: 'curly', c: '#1E1A1A' },
      top: { style: 'apron', c: '#F4F1EA', a: '#2F6B55' }, bottom: { style: 'pants', c: '#2E3430' }, shoes: '#2E3430' },
    { id: 'barista4', name: 'Barista', skin: '#F4D4BC', hair: { style: 'ponytail', c: '#C99A4A' }, hat: { style: 'headband', c: '#2F6B55' },
      top: { style: 'apron', c: '#F4F1EA', a: '#2F6B55' }, bottom: { style: 'pants', c: '#2E3430' }, shoes: '#2E3430' },
  ];
  const OUTLINE = '#2B2430';

  /* ---------- Frame builder ---------- */
  function build(ch, view, pose, f, item) {
    const cv = document.createElement('canvas'); cv.width = CW; cv.height = CH;
    const g = cv.getContext('2d');
    g.translate(0, TOP_PAD); // headroom for buns, berets and bobbing
    const R = (x, y, w, h, c) => { if (!c || w <= 0 || h <= 0) return; g.fillStyle = c; g.fillRect(x, y, w, h); };
    const P1 = (x, y, c) => R(x, y, 1, 1, c);
    const sit = pose === 'eat' || pose === 'drink';
    const walk = pose === 'walk';
    const bob = walk && (f === 1 || f === 3) ? -1 : 0;
    const oy = (sit ? 2 : 0) + bob;            // vertical offset of everything above the hips
    const front = view === 'front';
    const skin = ch.skin, skinD = shade(skin, .86);
    const top = ch.top, topC = top.c, topD = shade(topC, .82), topA = top.a, topB = top.b;
    const sleeve = top.style === 'apron' ? topC : top.style === 'cardigan' ? topC : top.style === 'blazer' ? topC : topC;
    const hairC = ch.hair.c, hairD = shade(hairC, .78), hairL = shade(hairC, 1.18);
    const bottomC = ch.bottom.c, bottomD = shade(bottomC, .8);
    const legC = ch.bottom.style === 'pants' ? bottomC : (ch.legs || skin);
    const legD = shade(legC, .82);

    /* walk cycle offsets */
    // The art faces right, so "forward" is +x.
    // frame 0: front leg forward, back leg behind (wide stride)
    // frame 1: back leg swings forward through the middle, lifted with a bent knee
    // frame 2: back leg forward, front leg behind
    // frame 3: front leg swings forward through the middle, lifted
    const dxF = walk ? [2, 0, -2, 0][f] : 0, dxB = walk ? [-1, 1, 3, 1][f] : 0;
    const liftF = walk && f === 3, liftB = walk && f === 1;
    // arms swing opposite to the legs: front arm back while the front leg is forward
    const armF = walk ? [-2, -1, 2, 1][f] : 0, armB = walk ? [2, 1, -2, -1][f] : 0;

    /* ---------------- layers ---------------- */
    // 1. hair / hijab behind the body
    if (front) {
      if (ch.hair.style === 'long') { R(4, oy + 6, 4, 11, hairD); R(4, oy + 6, 1, 9, hairC); }
      if (ch.hair.style === 'ponytail') { R(2, oy + 6, 3, 7, hairC); R(2, oy + 12, 2, 2, hairD); }
      if (ch.hair.style === 'hijab') { R(4, oy + 3, 12, 12, shade(hairC, .9)); }
    }

    // 2. back arm (front view: behind the torso)
    const armTop = oy + 14;
    // Arm with the shoulder fixed at the torso. swing moves the hand forward (+) or back (-) by up to 2 pixels;
    // the elbow takes half of that, so the arm always stays one connected piece.
    const drawArm = (x, dark, swing = 0) => {
      const sc = dark ? shade(sleeve, .82) : sleeve, hc = dark ? skinD : skin;
      const mid = Math.sign(swing) * Math.min(1, Math.abs(swing)), raise = swing > 0 ? 1 : 0;
      R(x, armTop, 2, 2, sc);                               // shoulder
      R(x + mid, armTop + 2, 2, 3 - raise, sc);             // elbow / forearm
      R(x + swing, armTop + 5 - raise, 2, 2, hc);           // hand
    };
    if (!sit) drawArm(4, true, armB);
    else if (front) drawArm(4, true, 0);

    // 3. legs (standing) or thighs (seated)
    if (!sit) {
      const legTop = 21 + oy, shoe = ch.shoes, shoeD = shade(shoe, .8);
      const leg = (x, lifted, dark) => {
        const lc = dark ? legD : legC, sc = dark ? shoeD : shoe;
        if (lifted){
          // passing leg: thigh swings forward (knee ahead), shin hangs back, foot lifted off the ground
          R(x, legTop, 2, 2, lc); R(x + 1, legTop + 2, 2, 1, lc); R(x, legTop + 3, 2, 2, lc);
          R(x - 1, legTop + 5, 3, 2, sc);
        } else {
          R(x, legTop, 2, 26 - legTop + 1, lc);
          R(x, 27, 3, 2, sc);
        }
      };
      leg(7 + dxB, liftB, true);
      leg(10 + dxF, liftF, false);
      // skirt / shorts / long skirt over the top of the legs
      const st = ch.bottom.style;
      if (st === 'skirt') { R(6, legTop - 1, 8, 3, bottomC); R(6, legTop + 1, 8, 1, bottomD); }
      if (st === 'shorts') { R(6, legTop - 1, 8, 3, bottomC); }
      if (st === 'longskirt') { const sway = walk ? [1, 0, -1, 0][f] : 0; R(6, legTop - 1, 8, 5, bottomC); R(6 + sway, legTop + 4, 8, 1, bottomD); }
    } else if (front) {
      // thighs pointing toward the table (to the right)
      const st = ch.bottom.style, c = st === 'pants' ? bottomC : bottomC;
      R(7, oy + 21, 8, 2, c); R(7, oy + 22, 8, 1, shade(c, .85));
    } else {
      R(7, oy + 21, 7, 1, bottomD);
    }

    // 4. torso
    const tx = 6, ty = oy + 13, tw = 7, th = 8;
    R(tx, ty, tw, th, topC);
    R(tx, ty, 1, th, topD);                       // shaded side
    R(tx, ty + th - 1, tw, 1, topD);              // hem
    if (front) {
      switch (top.style) {
        case 'sailor': R(tx, ty, tw, 2, topA); R(10, ty + 2, 2, 1, topB); P1(11, ty + 3, topB); break;
        case 'shirtTie': P1(10, ty, skin); R(11, ty, 1, 5, topA); P1(11, ty + 5, shade(topA, .8)); break;
        case 'cardigan': R(9, ty, 3, th - 1, topA); P1(10, ty + 3, shade(topC, .7)); P1(10, ty + 5, shade(topC, .7)); break;
        case 'hoodie': R(8, ty + 5, 4, 2, topD); P1(10, ty + 1, shade(topC, 1.4)); P1(11, ty + 1, shade(topC, 1.4)); break;
        case 'blazer': R(10, ty, 2, 4, topA); P1(9, ty, topD); P1(12, ty, topD); P1(11, ty + 5, shade(topC, 1.3)); break;
        case 'stripe': for (let r = 1; r < th - 1; r += 2) R(tx + 1, ty + r, tw - 1, 1, topA); break;
        case 'sport': R(9, ty, 1, th, topA); R(tx, ty, tw, 1, shade(topC, .9)); break;
        case 'tunic': R(tx, ty + th - 1, tw, 3, topC); R(9, ty + 1, 3, 1, topA); break;
        case 'sweater': R(tx, ty + th - 1, tw, 1, shade(topC, .72)); P1(10, ty, shade(topC, .72)); P1(11, ty, shade(topC, .72)); break;
        case 'apron': R(8, ty + 1, 5, th + (sit ? 0 : 1), topA); R(8, ty - 1, 1, 2, topA); R(12, ty - 1, 1, 2, topA); P1(10, ty + 4, shade(topA, 1.35)); break;
        case 'tee': P1(10, ty, skinD); break;
      }
    } else {
      // back of the outfit
      if (top.style === 'sailor') R(tx, ty, tw, 3, topA);
      if (top.style === 'hoodie') { R(7, ty - 1, 5, 3, topD); }
      if (top.style === 'stripe') for (let r = 1; r < th - 1; r += 2) R(tx + 1, ty + r, tw - 1, 1, topA);
      if (top.style === 'sport') R(tx, ty + 2, tw, 1, topA);
      if (top.style === 'tunic') R(tx, ty + th - 1, tw, 3, topC);
      if (top.style === 'apron') { R(tx + 2, ty + 3, 3, 1, topA); P1(tx + 3, ty + 4, topA); }
    }

    // 5. bags
    const bag = ch.bag;
    if (bag) {
      if (front) {
        if (bag.style === 'backpack') { R(12, ty, 1, 6, bag.c); R(5, ty + 1, 1, 5, shade(bag.c, .8)); }
        if (bag.style === 'messenger') { P1(12, ty, bag.c); P1(11, ty + 1, bag.c); P1(10, ty + 2, bag.c); P1(9, ty + 3, bag.c); P1(8, ty + 4, bag.c); R(4, ty + 4, 3, 3, shade(bag.c, .85)); }
      } else {
        if (bag.style === 'backpack') { R(6, ty + 1, 6, 6, bag.c); R(6, ty + 1, 6, 2, shade(bag.c, 1.15)); R(7, ty + 4, 4, 1, shade(bag.c, .8)); }
        if (bag.style === 'messenger') { P1(7, ty, bag.c); P1(8, ty + 1, bag.c); P1(9, ty + 2, bag.c); P1(10, ty + 3, bag.c); P1(11, ty + 4, bag.c); R(11, ty + 4, 3, 3, shade(bag.c, .85)); }
      }
    }

    // 6. head
    const hy = oy + 3;
    if (front) {
      R(6, hy + 1, 9, 9, skin);
      R(6, hy + 9, 9, 1, skinD);
      // face (eyes look toward the right)
      const blink = (pose === 'idle' && f === 1) || ((pose === 'drink') && (f === 1 || f === 2));
      const happy = pose === 'eat' && f === 3;
      if (blink || happy) { R(10, hy + 6, 1, 1, OUTLINE); R(13, hy + 6, 1, 1, OUTLINE); if (happy) { P1(9, hy + 5, OUTLINE); P1(12, hy + 5, OUTLINE); } }
      else { R(10, hy + 5, 1, 2, OUTLINE); R(13, hy + 5, 1, 2, OUTLINE); }
      P1(9, hy + 7, '#F0A0A0'); P1(14, hy + 7, '#F0A0A0');
      const mouthOpen = pose === 'eat' && f === 2;
      if (mouthOpen) R(12, hy + 8, 2, 1, '#8A3A3A');
      else if (pose === 'drink' && f === 3) R(11, hy + 8, 2, 1, '#B85A5A');
      else P1(12, hy + 8, '#B85A5A');
      if (happy) P1(15, hy + 7, skin);           // chewing cheek
      if (ch.glasses) { R(9, hy + 4, 6, 1, OUTLINE); P1(8, hy + 5, OUTLINE); P1(11, hy + 5, '#BFD9E6'); P1(14, hy + 5, '#BFD9E6'); }
    } else {
      R(6, hy + 1, 9, 9, skin);
      P1(14, hy + 5, skinD); P1(14, hy + 6, skinD); // ear
    }

    // 7. hair (front layer)
    const hs = ch.hair.style;
    if (front) {
      if (hs === 'hijab') {
        R(5, hy, 10, 2, hairC); R(5, hy + 2, 3, 8, hairC); R(14, hy + 1, 1, 9, hairC);
        R(5, oy + 13, 10, 3, hairC); R(6, oy + 15, 8, 1, shade(hairC, .85)); R(7, hy + 1, 7, 1, shade(hairC, .9));
      } else {
        R(5, hy, 10, 3, hairC); R(6, hy - 1, 8, 1, hairC);
        R(5, hy + 3, 3, 4, hairC);                        // back of the head
        R(8, hy + 3, 6, 1, hairC); P1(9, hy + 4, hairC); P1(12, hy + 4, hairC); // bangs
        R(7, hy, 5, 1, hairL);                            // shine
        if (hs === 'long') { R(5, hy + 7, 2, 6, hairC); P1(14, hy + 3, hairC); P1(14, hy + 4, hairC); }
        if (hs === 'bob') { R(5, hy + 7, 3, 3, hairC); R(14, hy + 2, 1, 6, hairC); R(5, hy + 10, 3, 1, hairD); }
        if (hs === 'bun') { R(4, hy - 3, 4, 3, hairC); P1(5, hy - 3, hairL); }
        if (hs === 'messy') { P1(6, hy - 2, hairC); P1(9, hy - 2, hairC); P1(12, hy - 2, hairC); P1(14, hy + 3, hairC); }
        if (hs === 'curly') { R(4, hy - 1, 12, 4, hairC); P1(5, hy - 2, hairC); P1(8, hy - 2, hairC); P1(11, hy - 2, hairC); P1(14, hy - 2, hairC); R(4, hy + 3, 2, 4, hairC); P1(14, hy + 3, hairC); }
        if (hs === 'ponytail') P1(4, hy + 3, ch.hat && ch.hat.style === 'headband' ? ch.hat.c : hairD);
      }
    } else {
      if (hs === 'hijab') { R(4, hy, 12, 10, hairC); R(5, oy + 13, 10, 4, hairC); R(5, oy + 16, 10, 1, shade(hairC, .85)); }
      else {
        R(5, hy, 10, 8, hairC); R(6, hy - 1, 8, 1, hairC); R(7, hy, 5, 1, hairL);
        if (hs === 'long') { R(5, hy + 8, 10, 8, hairC); R(6, hy + 15, 8, 1, hairD); }
        if (hs === 'bob') { R(4, hy + 2, 11, 8, hairC); R(4, hy + 9, 11, 1, hairD); }
        if (hs === 'bun') { R(8, hy - 3, 4, 3, hairC); P1(9, hy - 3, hairL); }
        if (hs === 'messy') { P1(6, hy - 2, hairC); P1(9, hy - 2, hairC); P1(12, hy - 2, hairC); }
        if (hs === 'curly') { R(4, hy - 1, 12, 9, hairC); P1(5, hy - 2, hairC); P1(8, hy - 2, hairC); P1(11, hy - 2, hairC); P1(14, hy - 2, hairC); }
        if (hs === 'ponytail') { R(9, hy + 7, 3, 7, hairC); R(9, hy + 13, 2, 1, hairD); P1(10, hy + 6, ch.hat ? ch.hat.c : hairD); }
        if (hs === 'short' || hs === 'messy') R(8, hy + 8, 4, 1, skinD); // nape
      }
    }

    // 8. hats
    const hat = ch.hat;
    if (hat) {
      if (hat.style === 'cap') {
        R(5, hy - 1, 10, 3, hat.c); R(7, hy - 1, 5, 1, shade(hat.c, 1.2));
        if (front) R(12, hy + 2, 5, 1, shade(hat.c, .8)); else R(8, hy + 2, 3, 1, shade(hat.c, .7));
      }
      if (hat.style === 'beret') { R(4, hy - 2, 11, 2, hat.c); R(6, hy - 3, 7, 1, hat.c); P1(10, hy - 4, hat.c); R(5, hy - 2, 4, 1, shade(hat.c, 1.2)); }
      if (hat.style === 'headband') R(5, hy + 2, 10, 1, hat.c);
    }

    // 9. front arm (and what the hand is holding)
    const hold = (x, y) => {
      const it = item || { kind: pose === 'eat' ? 'pastry' : 'cup', color: pose === 'eat' ? '#D9A441' : '#6B4A33' };
      if (it.kind === 'cup') { R(x, y, 3, 3, '#FFFFFF'); R(x, y, 3, 1, it.color); P1(x + 3, y + 1, '#FFFFFF'); }
      else if (it.kind === 'glass') { R(x, y - 1, 2, 4, '#EAF3F5'); R(x, y + 1, 2, 2, it.color); }
      else { R(x, y, 3, 2, it.color); P1(x + 1, y, shade(it.color, 1.3)); }
    };
    if (!sit) {
      drawArm(13, false, armF);
      if (bag && bag.style === 'handbag' && front) { R(14 + armF, oy + 20, 3, 3, bag.c); P1(15 + armF, oy + 19, shade(bag.c, .7)); }
    } else if (front) {
      // seated, facing the camera: the arm brings the food or cup up to the mouth
      const up = pose === 'drink' ? [0, 2, 2, 0][f] : [0, 1, 2, 0][f];
      if (up === 0) { R(13, armTop, 2, 4, sleeve); R(13, oy + 18, 2, 2, skin); hold(14, oy + 16 + (pose === 'eat' ? 1 : 0)); }
      if (up === 1) { R(13, armTop, 2, 2, sleeve); R(14, oy + 13, 2, 2, sleeve); R(14, oy + 12, 2, 2, skin); hold(15, oy + 11); }
      if (up === 2) { R(13, armTop - 1, 2, 2, sleeve); R(13, oy + 11, 2, 2, skin); hold(13, hy + 7); }
      if (pose === 'drink' && f === 2) { P1(14, hy + 4, '#FFFFFF'); P1(15, hy + 3, '#FFFFFF'); }
    } else {
      // seated, back to the camera: only the elbow and the cup peek out beside the head
      const up = [0, 1, 1, 0][f];
      if (!up) { R(13, armTop, 2, 5, sleeve); R(13, oy + 19, 2, 1, skin); }
      else { R(13, armTop, 2, 2, sleeve); R(15, oy + 12, 2, 3, sleeve); R(14, oy + 10, 2, 2, skin); hold(15, oy + 7); }
      R(4, armTop, 2, 5, shade(sleeve, .82));
    }

    // 10. outline around everything
    g.setTransform(1, 0, 0, 1, 0, 0);
    const id = g.getImageData(0, 0, CW, CH), d = id.data;
    const solid = (x, y) => x >= 0 && y >= 0 && x < CW && y < CH && d[(y * CW + x) * 4 + 3] > 0;
    const edge = [];
    for (let y = 0; y < CH; y++) for (let x = 0; x < CW; x++)
      if (!solid(x, y) && (solid(x + 1, y) || solid(x - 1, y) || solid(x, y + 1) || solid(x, y - 1))) edge.push([x, y]);
    g.fillStyle = OUTLINE; edge.forEach(([x, y]) => g.fillRect(x, y, 1, 1));
    return cv;
  }

  const cache = new Map();
  function frame(ch, view, pose, f, item) {
    const key = ch.id + view + pose + f + (item ? item.kind + item.color : '');
    let cv = cache.get(key);
    if (!cv) { cv = build(ch, view, pose, f, item); cache.set(key, cv); }
    return cv;
  }

  /* ---------- Drawing helpers ---------- */
  // Screen direction from a movement vector (dx, dy in screen pixels): which view and whether to mirror.
  function facing(sdx, sdy) {
    const front = sdy >= 0;               // moving down the screen = toward the camera
    const mirror = sdx < 0;               // art faces right; mirror for left
    return { view: front ? 'front' : 'back', mirror };
  }
  // Draw a frame with its anchor at (sx, sy) on ctx. px = screen pixels per art pixel.
  function draw(ctx, ch, view, pose, f, sx, sy, px, mirror, alpha, item) {
    const cv = frame(ch, view, pose, f, item), sit = pose === 'eat' || pose === 'drink';
    const ay = sit ? HIP_Y : FOOT_Y, s = px * (ch.scale || 1);
    ctx.save();
    ctx.imageSmoothingEnabled = false;
    if (alpha !== undefined) ctx.globalAlpha = alpha;
    ctx.translate(Math.round(sx), Math.round(sy));
    if (mirror) ctx.scale(-1, 1);
    ctx.drawImage(cv, -CX * s, -ay * s, CW * s, CH * s);
    ctx.restore();
    return sy - (ay - 1) * s;             // approximate top of the head
  }

  global.BeaneryCharacters = { CUSTOMERS, STAFF, frame, draw, facing, CW, CH, FOOT_Y, HIP_Y };
})(window);
