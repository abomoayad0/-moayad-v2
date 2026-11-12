/*
 * cropper.js — قص الصورة على دائرة البطاقة.
 * الموظف يسحب الصورة ويكبّرها لين يتوسط وجهه الدائرة، والناتج مربع 800×800 JPEG
 * تُرسم الدائرة منه في البطاقة (card.js). تستعمله صفحة التسجيل ولوحة صلاح.
 */
(function (global) {
  'use strict';
  const OUT = 800;          // ضلع الصورة الناتجة
  const MAX_SRC = 2400;     // تصغير الصور الكبيرة قبل العمل عليها

  function create(host, opts) {
    opts = opts || {};
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
    let size = 0;

    function resize() {
      const css = Math.min(host.clientWidth || 300, 340);
      const dpr = window.devicePixelRatio || 1;
      const old = size;
      size = Math.round(css * dpr);
      if (img && old && old !== size) { const r = size / old; ox *= r; oy *= r; scale *= r; }
      stage.width = stage.height = size;
      stage.style.width = stage.style.height = css + 'px';
      if (img) fit(false);
      draw();
    }

    function fit(reset) {
      minScale = size / Math.min(img.width, img.height);   // الصورة تغطي المربع دائمًا
      if (reset) { scale = minScale; ox = oy = 0; zoomEl.value = 1; }
      scale = Math.max(scale, minScale);
      clamp();
    }

    function clamp() {
      const w = img.width * scale, h = img.height * scale;
      const mx = (w - size) / 2, my = (h - size) / 2;
      ox = Math.max(-mx, Math.min(mx, ox));
      oy = Math.max(-my, Math.min(my, oy));
    }

    function paint(c, s, k) {
      // k: نسبة من المسرح إلى الهدف
      const w = img.width * scale * k, h = img.height * scale * k;
      c.drawImage(img, s / 2 - w / 2 + ox * k, s / 2 - h / 2 + oy * k, w, h);
    }

    function draw() {
      ctx.clearRect(0, 0, size, size);
      ctx.fillStyle = '#eef2f3'; ctx.fillRect(0, 0, size, size);
      if (!img) return;
      paint(ctx, size, 1);
      // تعتيم خارج الدائرة
      ctx.save();
      ctx.fillStyle = 'rgba(255,255,255,0.72)';
      ctx.beginPath();
      ctx.rect(0, 0, size, size);
      ctx.arc(size / 2, size / 2, size / 2 - 1, 0, Math.PI * 2, true);
      ctx.fill('evenodd');
      ctx.strokeStyle = '#16769e'; ctx.lineWidth = Math.max(2, size / 150);
      ctx.beginPath(); ctx.arc(size / 2, size / 2, size / 2 - ctx.lineWidth, 0, Math.PI * 2); ctx.stroke();
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
      c.width = c.height = OUT;
      const x = c.getContext('2d');
      x.fillStyle = '#fff'; x.fillRect(0, 0, OUT, OUT);
      paint(x, OUT, OUT / size);
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
