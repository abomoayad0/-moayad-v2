/*
 * cards/cropper.js — قص الصورة على مكان الصورة في البطاقة.
 * الشكل والنسبة من CARD_CONFIG.photo: دائرة (المندق) أو إطار مستطيل (بني حسن).
 * الموظف يسحب الصورة ويكبّرها لين يتوسط وجهه، والناتج JPEG بعرض 800 وبنفس نسبة المكان.
 */
(function (global) {
  'use strict';
  const OUT_W = 800;        // عرض الصورة الناتجة
  const MAX_SRC = 2400;     // تصغير الصور الكبيرة قبل العمل عليها

  function create(host, opts) {
    opts = opts || {};
    const P = global.CARD_CONFIG.photo;
    const aspect = P.w / P.h;                 // عرض ÷ ارتفاع
    const OUT_H = Math.round(OUT_W / aspect);
    const wrap = document.createElement('div');
    wrap.className = 'crop';
    wrap.innerHTML =
      '<canvas class="crop-stage"></canvas>' +
      '<div class="crop-zoom"><span>−</span><input type="range" min="1" max="4" step="0.01" value="1" aria-label="تكبير الصورة"><span>+</span></div>';
    host.appendChild(wrap);
    const stage = wrap.querySelector('canvas');
    const zoomEl = wrap.querySelector('input');
    const ctx = stage.getContext('2d');

    let img = null;           // canvas مصدر (بعد التصغير)
    let scale = 1, minScale = 1, ox = 0, oy = 0;   // إزاحة مركز الصورة عن مركز المسرح (بكسل المسرح)
    let sw = 0, sh = 0;

    function resize() {
      const cssW = Math.min(host.clientWidth || 300, 340 * Math.min(1, aspect));
      const dpr = window.devicePixelRatio || 1;
      const old = sw;
      sw = Math.round(cssW * dpr); sh = Math.round(sw / aspect);
      if (img && old && old !== sw) { const r = sw / old; ox *= r; oy *= r; scale *= r; }
      stage.width = sw; stage.height = sh;
      stage.style.width = cssW + 'px'; stage.style.height = (cssW / aspect) + 'px';
      if (img) fit(false);
      draw();
    }

    function fit(reset) {
      minScale = Math.max(sw / img.width, sh / img.height);   // الصورة تغطي المكان دائمًا
      if (reset) { scale = minScale; ox = oy = 0; zoomEl.value = 1; }
      scale = Math.max(scale, minScale);
      clamp();
    }

    function clamp() {
      const mx = (img.width * scale - sw) / 2, my = (img.height * scale - sh) / 2;
      ox = Math.max(-mx, Math.min(mx, ox));
      oy = Math.max(-my, Math.min(my, oy));
    }

    function paint(c, tw, th, k) {
      // k: نسبة من المسرح إلى الهدف
      const w = img.width * scale * k, h = img.height * scale * k;
      c.drawImage(img, tw / 2 - w / 2 + ox * k, th / 2 - h / 2 + oy * k, w, h);
    }

    function shapePath(c, inset) {
      c.beginPath();
      if (P.shape === 'circle') c.arc(sw / 2, sh / 2, Math.min(sw, sh) / 2 - inset, 0, Math.PI * 2);
      else c.rect(inset, inset, sw - 2 * inset, sh - 2 * inset);
    }

    function draw() {
      ctx.clearRect(0, 0, sw, sh);
      ctx.fillStyle = '#eef2f3'; ctx.fillRect(0, 0, sw, sh);
      if (!img) return;
      paint(ctx, sw, sh, 1);
      ctx.save();
      if (P.shape === 'circle') {
        // تعتيم خارج الدائرة
        ctx.fillStyle = 'rgba(255,255,255,0.72)';
        ctx.beginPath();
        ctx.rect(0, 0, sw, sh);
        ctx.arc(sw / 2, sh / 2, Math.min(sw, sh) / 2 - 1, 0, Math.PI * 2, true);
        ctx.fill('evenodd');
      }
      ctx.strokeStyle = '#16769e'; ctx.lineWidth = Math.max(2, sw / 150);
      shapePath(ctx, ctx.lineWidth / 2 + 1); ctx.stroke();
      ctx.restore();
    }

    let raf = 0;
    function changed() {
      draw();
      if (opts.onChange && !raf) raf = requestAnimationFrame(() => { raf = 0; opts.onChange(); });
    }

    // سحب وتكبير بالإصبعين
    const pts = new Map();
    let pinch0 = null;
    stage.addEventListener('pointerdown', (e) => {
      if (!img) return;
      stage.setPointerCapture(e.pointerId);
      pts.set(e.pointerId, { x: e.clientX, y: e.clientY });
      if (pts.size === 2) {
        const [a, b] = [...pts.values()];
        pinch0 = { d: Math.hypot(a.x - b.x, a.y - b.y), s: scale };
      }
    });
    stage.addEventListener('pointermove', (e) => {
      if (!img || !pts.has(e.pointerId)) return;
      const prev = pts.get(e.pointerId);
      const cur = { x: e.clientX, y: e.clientY };
      pts.set(e.pointerId, cur);
      const dpr = stage.width / stage.clientWidth;
      if (pts.size === 1) {
        ox += (cur.x - prev.x) * dpr; oy += (cur.y - prev.y) * dpr;
      } else if (pts.size === 2 && pinch0) {
        const [a, b] = [...pts.values()];
        setScale(pinch0.s * Math.hypot(a.x - b.x, a.y - b.y) / pinch0.d);
      }
      clamp(); changed();
    });
    const up = (e) => { pts.delete(e.pointerId); if (pts.size < 2) pinch0 = null; };
    stage.addEventListener('pointerup', up);
    stage.addEventListener('pointercancel', up);
    stage.addEventListener('wheel', (e) => {
      if (!img) return;
      e.preventDefault();
      setScale(scale * (e.deltaY < 0 ? 1.06 : 1 / 1.06)); clamp(); changed();
    }, { passive: false });
    zoomEl.addEventListener('input', () => { if (img) { setScale(minScale * parseFloat(zoomEl.value)); clamp(); changed(); } });

    function setScale(s) {
      scale = Math.max(minScale, Math.min(minScale * 4, s));
      zoomEl.value = (scale / minScale).toFixed(2);
    }

    async function decode(file) {
      if (global.createImageBitmap) {
        try { return await createImageBitmap(file, { imageOrientation: 'from-image' }); } catch (e) { /* يكمل تحت */ }
      }
      return await new Promise((res, rej) => {
        const u = URL.createObjectURL(file);
        const im = new Image();
        im.onload = () => { URL.revokeObjectURL(u); res(im); };
        im.onerror = () => { URL.revokeObjectURL(u); rej(new Error('ما قدرنا نفتح الصورة — جرّب صورة ثانية')); };
        im.src = u;
      });
    }

    async function loadSource(src) {
      const k = Math.min(1, MAX_SRC / Math.max(src.width, src.height));
      const c = document.createElement('canvas');
      c.width = Math.round(src.width * k); c.height = Math.round(src.height * k);
      c.getContext('2d').drawImage(src, 0, 0, c.width, c.height);
      img = c;
      wrap.classList.add('has-img');
      fit(true); changed();
    }

    async function load(file) {
      if (!file || !/^image\//.test(file.type || 'image/')) throw new Error('اختر ملف صورة');
      await loadSource(await decode(file));
    }

    function toCanvas() {
      if (!img) return null;
      const c = document.createElement('canvas');
      c.width = OUT_W; c.height = OUT_H;
      const x = c.getContext('2d');
      x.fillStyle = '#fff'; x.fillRect(0, 0, OUT_W, OUT_H);
      paint(x, OUT_W, OUT_H, OUT_W / sw);
      return c;
    }

    function clear() { img = null; wrap.classList.remove('has-img'); draw(); }

    new ResizeObserver(resize).observe(host);
    resize();

    return {
      load, loadSource, clear, toCanvas,
      hasPhoto: () => !!img,
      toDataURL: () => { const c = toCanvas(); return c ? c.toDataURL('image/jpeg', 0.9) : null; },
    };
  }

  global.MandakCropper = { create };
})(window);
