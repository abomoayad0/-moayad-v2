/*
 * cards/card.js — محرك رسم البطاقة، مصدر واحد لكل البلديات.
 * كل بلدية تعرّف window.CARD_CONFIG في مجلدها (config.js): القالب، مكان الصورة،
 * والنصوص ومواضعها. هنا الرسم فقط — لا رقم موضع ولا مقاس خاص ببلدية.
 *
 * القالب كما وصل من البلدية بلا تعديل؛ الإضافة الوحيدة أن مكان الصورة فيه شفاف
 * لتظهر الصورة من تحته.
 *
 * عنصر النص في الإعداد:
 *   { k, cx, cy, size, weight, font: 'CardText'|'CardNum', maxW, ltr?,
 *     wrapAt?, wrapK?, gap?, cy2? }
 *   — cy: مركز الحبر عموديًا بكسل القالب
 *   — wrapAt: ينقسم سطرين إذا (العرض × wrapAt) > maxW؛ غيابه = سطر واحد يصغر ليناسب
 */
(function (global) {
  'use strict';
  const CFG = global.CARD_CONFIG;
  if (!CFG) throw new Error('CARD_CONFIG مفقود');
  const W = CFG.W, H = CFG.H;
  const COLOR = CFG.color || '#16769e';

  const assets = { front: null, back: null, ready: null };

  function loadImage(src) {
    return new Promise((res, rej) => {
      const im = new Image();
      im.crossOrigin = 'anonymous';
      im.onload = () => res(im);
      im.onerror = () => rej(new Error('تعذّر تحميل الصورة'));
      im.src = src;
    });
  }

  function ready() {
    if (!assets.ready) {
      assets.ready = Promise.all([
        loadImage(CFG.assets + 'front.png'),
        loadImage(CFG.assets + 'back.png'),
        document.fonts.load('400 100px CardText', 'الأستاذ'),
        document.fonts.load('700 100px CardText', 'محمد'),
        document.fonts.load('900 100px CardNum', '0123456789'),
      ]).then(([f, b]) => { assets.front = f; assets.back = b; });
    }
    return assets.ready;
  }

  function latinDigits(s) {
    return String(s == null ? '' : s)
      .replace(/[٠-٩]/g, d => String(d.charCodeAt(0) - 0x0660))
      .replace(/[۰-۹]/g, d => String(d.charCodeAt(0) - 0x06F0));
  }

  function setFont(ctx, weight, size, family) { ctx.font = `${weight} ${size}px ${family}`; }

  // سطر متمركز أفقيًا حول cx وعموديًا حول مركز الحبر cy، يصغر لو تجاوز maxW
  function line(ctx, text, cx, cy, size, weight, family, maxW) {
    let s = size;
    setFont(ctx, weight, s, family);
    let m = ctx.measureText(text);
    if (m.width > maxW) {
      s = Math.floor(s * maxW / m.width);
      setFont(ctx, weight, s, family);
      m = ctx.measureText(text);
    }
    ctx.fillText(text, cx, cy + (m.actualBoundingBoxAscent - m.actualBoundingBoxDescent) / 2);
    return s;
  }

  // يقسم النص على سطرين بأقرب توازن بالكلمات
  function splitTwo(ctx, text) {
    const words = text.split(/\s+/).filter(Boolean);
    if (words.length < 2) return [text];
    let best = null;
    for (let i = 1; i < words.length; i++) {
      const a = words.slice(0, i).join(' '), b = words.slice(i).join(' ');
      const d = Math.max(ctx.measureText(a).width, ctx.measureText(b).width);
      if (!best || d < best.d) best = { d, parts: [a, b] };
    }
    return best.parts;
  }

  function drawItem(ctx, it, raw) {
    const text = it.font === 'CardNum' ? latinDigits(raw).trim() : String(raw || '').trim();
    if (!text) return;   // الحقل الاختياري الفارغ يبقى مكانه فارغًا والقالب كما هو
    ctx.direction = it.ltr ? 'ltr' : 'rtl';
    const fam = it.font || 'CardText';
    if (it.wrapAt) {
      setFont(ctx, it.weight, it.size, fam);
      if (ctx.measureText(text).width * it.wrapAt > it.maxW) {
        const s = Math.round(it.size * it.wrapK);
        setFont(ctx, it.weight, s, fam);
        const parts = splitTwo(ctx, text);
        if (parts.length === 2) {
          const step = s * it.gap, cy = it.cy2 != null ? it.cy2 : it.cy;
          line(ctx, parts[0], it.cx, cy - step / 2, s, it.weight, fam, it.maxW);
          line(ctx, parts[1], it.cx, cy + step / 2, s, it.weight, fam, it.maxW);
          return;
        }
      }
    }
    line(ctx, text, it.cx, it.cy, it.size, it.weight, fam, it.maxW);
  }

  function texts(ctx, items, d) {
    ctx.save();
    ctx.fillStyle = COLOR; ctx.textAlign = 'center'; ctx.textBaseline = 'alphabetic';
    for (const it of items) drawItem(ctx, it, d[it.k]);
    ctx.restore();
  }
  const frontText = (ctx, d) => texts(ctx, CFG.front, d);
  const backText = (ctx, d) => texts(ctx, CFG.back, d);

  function drawFront(ctx, d, photo) {
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, W, H);
    if (photo) { const P = CFG.photo; ctx.drawImage(photo, P.x, P.y, P.w, P.h); }
    ctx.drawImage(assets.front, 0, 0, W, H);
    frontText(ctx, d);
  }

  function drawBack(ctx, d) {
    ctx.clearRect(0, 0, W, H);
    ctx.drawImage(assets.back, 0, 0, W, H);
    backText(ctx, d);
  }

  function makeCanvas() { const c = document.createElement('canvas'); c.width = W; c.height = H; return c; }

  global.MandakCard = {
    W, H, CFG, ready, assets, latinDigits, loadImage,
    drawFront, drawBack, frontText, backText, makeCanvas,
  };
})(window);
