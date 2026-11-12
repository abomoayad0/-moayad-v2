/*
 * form.js — حقول البطاقة + الصورة + المعاينة. نموذج واحد تستعمله صفحة التسجيل
 * ونافذة التعديل في لوحة صلاح، فلا تتكرر الحقول ولا قواعدها.
 * (القواعد نفسها يفرضها الخادم والجدول؛ هنا للتنبيه المبكر فقط)
 */
(function (global) {
  'use strict';
  const C = global.MandakCard;

  function create(host, previewHost, opts) {
    opts = opts || {};
    const H = C.HONORIFICS.map(h => `<option>${h}</option>`).join('');
    host.innerHTML = `
      <label class="f" data-k="honorific"><span>الصفة</span>
        <select name="honorific"><option value="">— اختر —</option>${H}</select>
        <div class="msg-err">اختر الصفة</div></label>
      <label class="f" data-k="full_name"><span>الاسم الكامل</span>
        <input type="text" name="full_name" autocomplete="name" maxlength="80" placeholder="مثل: محمد أحمد محي الزهراني">
        <small>ثلاثي أو رباعي، كما تبيه يطلع في البطاقة</small>
        <div class="msg-err">اكتب الاسم ثلاثيًا على الأقل بالحروف العربية</div></label>
      <label class="f" data-k="department"><span>الإدارة / المسمى</span>
        <input type="text" name="department" maxlength="120" placeholder="مثل: مدير إدارة الطوارئ والأزمات">
        <small>السطر اللي تحت الاسم في البطاقة — اكتبه مثل ما تبيه</small>
        <div class="msg-err">اكتب الإدارة أو المسمى</div></label>
      <label class="f" data-k="national_id"><span>السجل المدني</span>
        <input type="text" name="national_id" class="ltr" inputmode="numeric" maxlength="10" placeholder="10 أرقام">
        <div class="msg-err">السجل المدني ١٠ أرقام يبدأ بـ ١ أو ٢</div></label>
      <label class="f" data-k="employee_no"><span>الرقم الوظيفي <span class="opt">(اختياري)</span></span>
        <input type="text" name="employee_no" class="ltr" inputmode="numeric" maxlength="10">
        <div class="msg-err">الرقم الوظيفي أرقام فقط</div></label>
      <div class="photo-box f" data-k="photo">
        <label class="f" style="margin:0"><span>الصورة الشخصية</span></label>
        <div class="pick">
          <button type="button" class="btn ghost sm" data-act="pick">اختر صورة</button>
          <input type="file" accept="image/*" class="hidden">
          <span class="s pick-note"></span>
        </div>
        <div class="crop-host"></div>
        <div class="hint">صورة حديثة، والوجه واضح وخلفيته فاتحة. حرّك الصورة وكبّرها لين يتوسط وجهك الدائرة.</div>
        <div class="msg-err">الصورة مطلوبة</div>
      </div>`;

    previewHost.innerHTML = `
      <div class="preview">
        <div><canvas data-face="front"></canvas><div class="cap">الوجه الأمامي</div></div>
        <div><canvas data-face="back"></canvas><div class="cap">الوجه الخلفي</div></div>
      </div>`;
    const fc = previewHost.querySelector('[data-face=front]');
    const bc = previewHost.querySelector('[data-face=back]');
    fc.width = bc.width = C.W; fc.height = bc.height = C.H;

    const q = (n) => host.querySelector(`[name=${n}]`);
    const fileEl = host.querySelector('input[type=file]');
    const note = host.querySelector('.pick-note');
    let existingPhoto = null;   // صورة محفوظة (لوحة صلاح)
    let newPhoto = false;

    const cropper = global.MandakCropper.create(host.querySelector('.crop-host'), { onChange: render });

    host.querySelector('[data-act=pick]').addEventListener('click', () => fileEl.click());
    fileEl.addEventListener('change', async () => {
      const f = fileEl.files && fileEl.files[0];
      if (!f) return;
      note.textContent = 'جاري فتح الصورة…';
      try {
        await cropper.load(f);
        newPhoto = true;
        note.textContent = '';
        host.querySelector('[data-k=photo]').classList.remove('bad');
      } catch (e) { note.textContent = e.message; }
      fileEl.value = '';
      render();
    });

    host.addEventListener('input', (e) => {
      const l = e.target.closest('[data-k]');
      if (l) l.classList.remove('bad');
      render();
    });

    function getData() {
      return {
        honorific: q('honorific').value,
        full_name: q('full_name').value.replace(/\s+/g, ' ').trim(),
        department: q('department').value.replace(/\s+/g, ' ').trim(),
        national_id: C.latinDigits(q('national_id').value).replace(/\s/g, ''),
        employee_no: C.latinDigits(q('employee_no').value).replace(/\s/g, ''),
      };
    }

    function setData(d) {
      for (const k of ['honorific', 'full_name', 'department', 'national_id', 'employee_no']) q(k).value = d[k] || '';
      render();
    }

    function setExistingPhoto(img) { existingPhoto = img; newPhoto = false; cropper.clear(); render(); }

    function photoSource() { return newPhoto ? cropper.toCanvas() : existingPhoto; }

    let pending = 0;
    function render() {
      if (pending) return;
      pending = requestAnimationFrame(() => {
        pending = 0;
        C.ready().then(() => {
          const d = getData();
          C.drawFront(fc.getContext('2d'), d, photoSource());
          C.drawBack(bc.getContext('2d'), d);
          if (opts.onChange) opts.onChange(d);
        });
      });
    }

    function validate() {
      const d = getData();
      const bad = {
        honorific: !d.honorific,
        full_name: !/^[؀-ۿ ]+$/.test(d.full_name) || d.full_name.split(' ').length < 3,
        department: d.department.length < 3,
        national_id: !/^[12][0-9]{9}$/.test(d.national_id),
        employee_no: !!d.employee_no && !/^[0-9]{1,10}$/.test(d.employee_no),
        photo: !newPhoto && !existingPhoto,
      };
      let first = null;
      for (const k in bad) {
        const el = host.querySelector(`[data-k=${k}]`);
        el.classList.toggle('bad', bad[k]);
        if (bad[k] && !first) first = el;
      }
      if (first) first.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return !first;
    }

    C.ready().then(render);

    return {
      getData, setData, validate, setExistingPhoto, render,
      newPhotoDataURL: () => (newPhoto ? cropper.toDataURL() : null),
    };
  }

  global.MandakForm = { create };
})(window);
