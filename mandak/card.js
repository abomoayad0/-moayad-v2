/*
 * card.js — المصدر الوحيد لرسم بطاقة موظف بلدية المندق.
 * تستعمله صفحة التسجيل (المعاينة) ولوحة صلاح (المعاينة والـ PDF)، فلا يُرسم في مكانين.
 *
 * القالب كما وصل من البلدية بلا تعديل: وجهان 1297×2008 بكسل = 5.49×8.5 سم بدقة 600.
 * الإضافة الوحيدة: الدائرة الرمادية في الوجه الأمامي صارت شفافة لتظهر الصورة من تحتها.
 *
 * المواضع مقيسة من بطاقة العينة (محمد أحمد محي الزهراني) بعد مطابقتها على القالب:
 *   كل رقم هنا = مركز الحبر عموديًا بكسل القالب.
 */
(function (global) {
  'use strict';

  const W = 1297, H = 2008;
  const COLOR = '#16769e';           // لون نصوص العينة المقيس (22,118,158)

  const FRONT = {
    photo: { cx: 740, cy: 836, r: 352 },   // فتحة الدائرة نصف قطرها ~345، والصورة أعرض قليلًا فلا يظهر فراغ
    cx: 740, maxW: 980,
    title: { cy: 1330, size: 95, weight: 400 },
    name:  { cy: 1490, size: 75, weight: 700 },
    dept:  { cy: 1795, size: 88, weight: 400, cy2: 1800, gap: 1.18 },
  };
  const BACK = {
    // الحجم الأساسي أصغر من العينة (440) بطلب أبو علي لأن بعض الأرقام طويلة؛
    // والطويل يصغر لحاله ولا يتعدى عرض إطار السجل المدني
    num: { cx: 590, cy: 814,  size: 340, maxW: 820 },
    id:  { cx: 553, cy: 1705, size: 122, maxW: 780 },   // وسط الإطار الذهبي 117..990
  };

  const HONORIFICS = ['الأستاذ', 'الأستاذة', 'المهندس', 'المهندسة', 'الدكتور', 'الدكتورة'];

  const assets = { front: null, back: null, ready: null };

  function loadImage(src) {
    return new Promise((res, rej) => {
      const im = new Image();
      im.crossOrigin = 'anonymous';
      im.onload = () => res(im);
      im.onerror = () => rej(new Error('تعذّر تحميل الصورة: ' + src));
      im.src = src;
    });
  }

  function base() {
    // مجلد الصفحة الحالية — card.js يُحمَّل من /mandak/
    const s = document.currentScript || document.querySelector('script[src*="card.js"]');
    return s ? s.src.replace(/card\.js.*$/, '') : '/mandak/';
  }
  const BASE = base();

  function ready() {
    if (!assets.ready) {
      assets.ready = Promise.all([
        loadImage(BASE + 'assets/front.png'),
        loadImage(BASE + 'assets/back.png'),
        document.fonts.load('400 100px CardText', 'الأستاذ'),
        document.fonts.load('700 100px CardText', 'محمد'),
        document.fonts.load('900 100px CardNum', '0123456789'),
      ]).then(([f, b]) => { assets.front = f; assets.back = b; });
    }
    return assets.ready;
  }

  // يحوّل الأرقام الهندية والفارسية إلى لاتينية
  function latinDigits(s) {
    return String(s == null ? '' : s)
      .replace(/[٠-٩]/g, d => String(d.charCodeAt(0) - 0x0660))
      .replace(/[۰-۹]/g, d => String(d.charCodeAt(0) - 0x06F0));
  }

  function setFont(ctx, weight, size, family) {
    ctx.font = `${weight} ${size}px ${family}`;
  }

  // يرسم سطرًا متمركزًا أفقيًا حول cx وعموديًا حول مركز الحبر cy، ويصغّر الخط لو تجاوز maxW
  function line(ctx, text, cx, cy, size, weight, family, maxW) {
    let s = size;
    setFont(ctx, weight, s, family);
    let m = ctx.measureText(text);
    if (m.width > maxW) {
      s = Math.floor(s * maxW / m.width);
      setFont(ctx, weight, s, family);
      m = ctx.measureText(text);
    }
    const asc = m.actualBoundingBoxAscent, desc = m.actualBoundingBoxDescent;
    ctx.fillText(text, cx, cy + (asc - desc) / 2);
    return s;
  }

  // يقسم نص الإدارة على سطرين بأقرب توازن بالكلمات
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

  function drawDept(ctx, text) {
    const D = FRONT.dept;
    setFont(ctx, D.weight, D.size, 'CardText');
    if (ctx.measureText(text).width <= FRONT.maxW) {
      line(ctx, text, FRONT.cx, D.cy, D.size, D.weight, 'CardText', FRONT.maxW);
      return;
    }
    // سطران — مثل بطاقة «مساعد رئيس البلدية…» في العينات
    const s = Math.round(D.size * 0.86);
    setFont(ctx, D.weight, s, 'CardText');
    const parts = splitTwo(ctx, text);
    if (parts.length === 1) { line(ctx, text, FRONT.cx, D.cy, D.size, D.weight, 'CardText', FRONT.maxW); return; }
    const step = s * D.gap;
    line(ctx, parts[0], FRONT.cx, D.cy2 - step / 2, s, D.weight, 'CardText', FRONT.maxW);
    line(ctx, parts[1], FRONT.cx, D.cy2 + step / 2, s, D.weight, 'CardText', FRONT.maxW);
  }

  // الاسم سطر واحد كالعينة؛ لو طال لدرجة يصغر فيها كثير ينقسم سطرين بين الصفة والزخرفة
  function drawName(ctx, text) {
    const N = FRONT.name;
    setFont(ctx, N.weight, N.size, 'CardText');
    const w = ctx.measureText(text).width;
    if (w * 0.8 <= FRONT.maxW) { line(ctx, text, FRONT.cx, N.cy, N.size, N.weight, 'CardText', FRONT.maxW); return; }
    const s = Math.round(N.size * 0.85);
    setFont(ctx, N.weight, s, 'CardText');
    const parts = splitTwo(ctx, text);
    if (parts.length === 1) { line(ctx, text, FRONT.cx, N.cy, N.size, N.weight, 'CardText', FRONT.maxW); return; }
    const step = s * 1.25;
    line(ctx, parts[0], FRONT.cx, N.cy - step / 2, s, N.weight, 'CardText', FRONT.maxW);
    line(ctx, parts[1], FRONT.cx, N.cy + step / 2, s, N.weight, 'CardText', FRONT.maxW);
  }

  function prep(ctx) {
    ctx.fillStyle = COLOR;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'alphabetic';
    ctx.direction = 'rtl';
  }

  // نصوص الوجه الأمامي فقط (شفافة الخلفية) — للـ PDF
  function frontText(ctx, d) {
    ctx.save(); prep(ctx);
    if (d.honorific) line(ctx, d.honorific, FRONT.cx, FRONT.title.cy, FRONT.title.size, FRONT.title.weight, 'CardText', FRONT.maxW);
    if (d.full_name) drawName(ctx, d.full_name.trim());
    if (d.department) drawDept(ctx, d.department.trim());
    ctx.restore();
  }

  // نصوص الوجه الخلفي فقط — الرقم الوظيفي اختياري: إن غاب بقي مكانه فارغًا والقالب كما هو
  function backText(ctx, d) {
    ctx.save(); prep(ctx); ctx.direction = 'ltr';
    const num = latinDigits(d.employee_no || '').trim();
    if (num) line(ctx, num, BACK.num.cx, BACK.num.cy, BACK.num.size, 900, 'CardNum', BACK.num.maxW);
    const nid = latinDigits(d.national_id || '').trim();
    if (nid) line(ctx, nid, BACK.id.cx, BACK.id.cy, BACK.id.size, 900, 'CardNum', BACK.id.maxW);
    ctx.restore();
  }

  function drawPhoto(ctx, photo) {
    if (!photo) return;
    const P = FRONT.photo, s = P.r * 2;
    ctx.drawImage(photo, P.cx - P.r, P.cy - P.r, s, s);
  }

  // الوجه الأمامي كاملًا: الصورة تحت، ثم القالب (بفتحته الشفافة)، ثم النصوص
  function drawFront(ctx, d, photo) {
    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, W, H);
    drawPhoto(ctx, photo);
    ctx.drawImage(assets.front, 0, 0, W, H);
    frontText(ctx, d);
  }

  function drawBack(ctx, d) {
    ctx.clearRect(0, 0, W, H);
    ctx.drawImage(assets.back, 0, 0, W, H);
    backText(ctx, d);
  }

  function makeCanvas() {
    const c = document.createElement('canvas');
    c.width = W; c.height = H;
    return c;
  }

  global.MandakCard = {
    W, H, FRONT, BACK, HONORIFICS, BASE,
    ready, assets, latinDigits, loadImage,
    drawFront, drawBack, frontText, backText, makeCanvas,
  };
})(window);
