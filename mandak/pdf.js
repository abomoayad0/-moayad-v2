/*
 * pdf.js — ملف الطباعة: صفحتان لكل موظف (أمامي ثم خلفي) بمقاس القالب 5.49×8.5 سم.
 * القالبان يُضمَّنان مرة واحدة، ولكل موظف صورته الأصلية + طبقة نصوص شفافة،
 * فيبقى الملف خفيفًا مع 120 بطاقة. الرسم نفسه من card.js.
 */
(function (global) {
  'use strict';
  const C = global.MandakCard;
  const PW = 155.64, PH = 240.96;          // نقاط = مقاس صفحة القالب الأصلي
  const k = PW / C.W;                       // نقطة لكل بكسل قالب

  async function bytes(url) {
    const r = await fetch(url);
    if (!r.ok) throw new Error('تعذّر تحميل ملف: ' + url.split('?')[0].split('/').pop());
    return new Uint8Array(await r.arrayBuffer());
  }

  function textPng(drawFn, d) {
    const c = C.makeCanvas();
    drawFn(c.getContext('2d'), d);
    return new Promise((res) => c.toBlob(async (b) => res(new Uint8Array(await b.arrayBuffer())), 'image/png'));
  }

  async function build(rows, onProgress) {
    await C.ready();
    const { PDFDocument } = global.PDFLib;
    const doc = await PDFDocument.create();
    doc.setTitle('بطاقات موظفي بلدية محافظة المندق');
    doc.setCreator('mandak');
    const frontTpl = await doc.embedPng(await bytes(C.BASE + 'assets/front.png'));
    const backTpl = await doc.embedPng(await bytes(C.BASE + 'assets/back.png'));
    const P = C.FRONT.photo;

    for (let i = 0; i < rows.length; i++) {
      const d = rows[i];
      if (!d.photo_url) throw new Error('صورة ناقصة: ' + d.full_name);
      const photo = await doc.embedJpg(await bytes(d.photo_url));
      const ft = await doc.embedPng(await textPng(C.frontText, d));
      const bt = await doc.embedPng(await textPng(C.backText, d));

      const f = doc.addPage([PW, PH]);
      f.drawImage(photo, { x: (P.cx - P.r) * k, y: PH - (P.cy + P.r) * k, width: 2 * P.r * k, height: 2 * P.r * k });
      f.drawImage(frontTpl, { x: 0, y: 0, width: PW, height: PH });
      f.drawImage(ft, { x: 0, y: 0, width: PW, height: PH });

      const b = doc.addPage([PW, PH]);
      b.drawImage(backTpl, { x: 0, y: 0, width: PW, height: PH });
      b.drawImage(bt, { x: 0, y: 0, width: PW, height: PH });

      if (onProgress) onProgress(i + 1, rows.length);
    }
    return new Blob([await doc.save()], { type: 'application/pdf' });
  }

  global.MandakPdf = { build };
})(window);
