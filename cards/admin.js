/*
 * cards/admin.js — لوحة البلدية: مراجعة، تعديل، اعتماد، أرشفة، وPDF للمعتمدين فقط.
 * مشتركة لكل البلديات، وكل لوحة تكلّم دالة بلديتها فقط بكلمة مرورها.
 */
(function () {
  'use strict';
  const C = MandakCard, CFG = window.CARD_CONFIG;
  const STORE = 'cards_pass_' + CFG.key;   // لكل بلدية مفتاحها — نفس المتصفح لا يخلط كلمتين
  document.body.innerHTML = `
<header class="top"><h1>لوحة بطاقات الموظفين</h1><p>${CFG.title}</p></header>
<main class="wrap" id="login">
  <form class="panel" id="loginForm" style="max-width:420px;margin:30px auto">
    <h2>الدخول</h2>
    <label class="f"><span>كلمة المرور</span><input type="password" id="pass" autocomplete="current-password"></label>
    <div id="loginErr" class="note err hidden"></div>
    <button class="btn block" type="submit">دخول</button>
  </form>
</main>
<main class="wrap hidden" id="app">
  <div class="bar">
    <span class="count" id="count"></span>
    <input type="search" class="grow" id="q" placeholder="بحث بالاسم أو السجل أو الإدارة">
    <select id="filter" style="width:auto">
      <option value="all">الكل</option><option value="pending">بانتظار الاعتماد</option><option value="approved">المعتمد</option>
    </select>
    <button class="btn ghost sm" id="reload" type="button">تحديث</button>
    <button class="btn sm" id="pdf" type="button">تنزيل PDF للمعتمدين</button>
  </div>
  <div class="progress" id="prog"><i></i></div>
  <div id="appMsg" class="note hidden"></div>
  <div class="rows" id="rows"></div>
</main>
<div class="modal" id="viewModal"><div class="panel">
  <div class="bar"><h2 class="grow" id="viewTitle" style="margin:0"></h2><button class="btn ghost sm" type="button" data-close>إغلاق</button></div>
  <div class="preview">
    <div><canvas id="vf"></canvas><div class="cap">الوجه الأمامي</div></div>
    <div><canvas id="vb"></canvas><div class="cap">الوجه الخلفي</div></div>
  </div>
</div></div>
<div class="modal" id="editModal"><div class="panel">
  <div class="bar"><h2 class="grow" style="margin:0">تعديل البيانات</h2><button class="btn ghost sm" type="button" data-close>إلغاء</button></div>
  <p class="note err" style="margin-top:0">الحفظ يلغي اعتماد البطاقة، وتحتاج اعتماد من جديد.</p>
  <div class="cols">
    <form id="editForm" novalidate>
      <div id="editFields"></div>
      <div id="editErr" class="note err hidden"></div>
      <button class="btn block" type="submit" id="editSave">حفظ</button>
    </form>
    <div id="editPreview"></div>
  </div>
</div></div>`;

  const $ = (id) => document.getElementById(id);
  let pass = '';
  try { pass = sessionStorage.getItem(STORE) || ''; } catch (e) { /* تخزين غير متاح */ }
  let rows = [];
  const photoCache = new Map();

  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const fmt = (t) => new Date(t).toLocaleString('ar-SA-u-nu-latn', { dateStyle: 'short', timeStyle: 'short' });
  const approved = () => rows.filter(r => r.approved_at);

  function msg(text, kind) {
    const m = $('appMsg');
    m.textContent = text || '';
    m.className = 'note ' + (kind || 'ok') + (text ? '' : ' hidden');
  }

  async function api(action, payload) {
    try { return await MandakApi.call(action, payload, pass); }
    catch (e) { if (e.status === 401) logout(); throw e; }
  }

  function logout() {
    pass = '';
    try { sessionStorage.removeItem(STORE); } catch (e) { /* */ }
    $('app').classList.add('hidden'); $('login').classList.remove('hidden');
  }

  $('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    $('loginErr').classList.add('hidden');
    pass = $('pass').value;
    try {
      await MandakApi.call('admin_login', {}, pass);
      try { sessionStorage.setItem(STORE, pass); } catch (e2) { /* */ }
      start();
    } catch (ex) { $('loginErr').textContent = ex.message; $('loginErr').classList.remove('hidden'); }
  });

  async function start() {
    $('login').classList.add('hidden'); $('app').classList.remove('hidden');
    await load();
  }

  async function load() {
    msg('');
    $('rows').innerHTML = '<p class="s">جاري التحميل…</p>';
    try {
      const r = await api('admin_list');
      rows = r.rows; photoCache.clear();
      draw();
    } catch (e) { $('rows').innerHTML = ''; msg(e.message, 'err'); }
  }

  function filtered() {
    const t = C.latinDigits($('q').value.trim()), f = $('filter').value;
    return rows.filter(r =>
      (f === 'all' || (f === 'approved') === !!r.approved_at) &&
      (!t || [r.full_name, r.national_id, r.department, r.employee_no].some(v => String(v || '').includes(t))));
  }

  function draw() {
    const list = filtered(), na = approved().length;
    $('count').textContent = `المسجلين: ${rows.length} — المعتمد: ${na}` + (list.length !== rows.length ? ` — الظاهر ${list.length}` : '');
    $('pdf').textContent = `تنزيل PDF للمعتمدين (${na})`;
    $('pdf').disabled = na === 0;
    $('rows').innerHTML = list.map(r => `
      <div class="row" data-id="${esc(r.id)}">
        <img src="${esc(r.photo_url || '')}" alt="" loading="lazy">
        <div>
          <div class="t">${r.honorific ? esc(r.honorific) + ' ' : ''}${esc(r.full_name)}</div>
          <div class="s">${esc(r.department)}</div>
          <div class="s" dir="ltr" style="text-align:right">${esc(r.national_id)}${r.employee_no ? ' · ' + esc(r.employee_no) : ''}</div>
          <div class="s">${fmt(r.updated_at)} ${r.updated_by === 'admin' ? '<span class="tag">عُدّل من اللوحة</span>' : ''}
            ${r.approved_at ? '<span class="tag ok">معتمدة ✓</span>' : '<span class="tag">بانتظار الاعتماد</span>'}</div>
        </div>
        <div class="acts">
          ${r.approved_at ? '<button class="btn ghost sm" data-act="unapprove">إلغاء الاعتماد</button>' : '<button class="btn sm" data-act="approve">اعتماد</button>'}
          <button class="btn ghost sm" data-act="view">معاينة</button>
          <button class="btn ghost sm" data-act="edit">تعديل</button>
          <button class="btn warn sm" data-act="archive">أرشفة</button>
        </div>
      </div>`).join('') || '<p class="s">لا يوجد.</p>';
  }

  $('q').addEventListener('input', draw);
  $('filter').addEventListener('change', draw);
  $('reload').addEventListener('click', load);

  function photoOf(r) {
    if (!photoCache.has(r.id)) photoCache.set(r.id, C.loadImage(r.photo_url));
    return photoCache.get(r.id);
  }

  document.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', () => b.closest('.modal').classList.remove('on')));

  // ── معاينة
  async function view(r) {
    $('viewTitle').textContent = r.full_name;
    const f = $('vf'), b = $('vb');
    f.width = b.width = C.W; f.height = b.height = C.H;
    $('viewModal').classList.add('on');
    await C.ready();
    C.drawFront(f.getContext('2d'), r, await photoOf(r));
    C.drawBack(b.getContext('2d'), r);
  }

  // ── تعديل (نفس نموذج صفحة التسجيل) — يلغي الاعتماد
  const editForm = MandakForm.create($('editFields'), $('editPreview'));
  let editing = null;
  async function edit(r) {
    editing = r;
    $('editErr').classList.add('hidden');
    editForm.setData(r);
    editForm.setExistingPhoto(null);
    $('editModal').classList.add('on');
    try { editForm.setExistingPhoto(await photoOf(r)); } catch (e) { /* الصورة تبقى ناقصة */ }
  }
  $('editForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!editForm.validate()) return;
    const btn = $('editSave'); btn.disabled = true;
    try {
      const photo = editForm.newPhotoDataURL();
      await api('admin_update', { id: editing.id, ...editForm.getData(), ...(photo ? { photo } : {}) });
      $('editModal').classList.remove('on');
      await load(); msg('تم حفظ التعديل — البطاقة بانتظار الاعتماد');
    } catch (ex) { $('editErr').textContent = ex.message; $('editErr').classList.remove('hidden'); }
    finally { btn.disabled = false; }
  });

  // ── اعتماد / إلغاء اعتماد
  async function setApproved(r, on, btn) {
    btn.disabled = true;
    try {
      const res = await api('admin_approve', { id: r.id, approved: on });
      r.approved_at = res.approved_at;
      draw(); msg((on ? 'تم اعتماد: ' : 'أُلغي اعتماد: ') + r.full_name);
    } catch (ex) { msg(ex.message, 'err'); btn.disabled = false; }
  }

  // ── أرشفة بخطوتين (بلا نوافذ المتصفح)
  async function archive(r, btn) {
    if (btn.dataset.confirm !== '1') {
      btn.dataset.confirm = '1'; btn.textContent = 'تأكيد الأرشفة';
      setTimeout(() => { if (btn.isConnected) { btn.dataset.confirm = ''; btn.textContent = 'أرشفة'; } }, 4000);
      return;
    }
    btn.disabled = true;
    try { await api('admin_archive', { id: r.id }); await load(); msg('تمت الأرشفة: ' + r.full_name); }
    catch (ex) { msg(ex.message, 'err'); btn.disabled = false; }
  }

  $('rows').addEventListener('click', (e) => {
    const b = e.target.closest('button[data-act]');
    if (!b) return;
    const r = rows.find(x => x.id === b.closest('.row').dataset.id);
    if (!r) return;
    ({
      approve: () => setApproved(r, true, b), unapprove: () => setApproved(r, false, b),
      view: () => view(r), edit: () => edit(r), archive: () => archive(r, b),
    })[b.dataset.act]();
  });

  // ── PDF للطباعة: المعتمد فقط
  $('pdf').addEventListener('click', async () => {
    const btn = $('pdf'); btn.disabled = true; msg('');
    $('prog').classList.add('on');
    try {
      await load();   // روابط صور جديدة وآخر البيانات والاعتماد
      const list = approved();
      if (!list.length) throw new Error('لا توجد بطاقات معتمدة');
      const blob = await MandakPdf.build(list, (i, n) => { $('prog').firstElementChild.style.width = (100 * i / n) + '%'; });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `بطاقات-${CFG.key}-${new Date().toISOString().slice(0, 10)}-${list.length}.pdf`;
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(a.href), 60000);
      msg(`تم تجهيز ملف ${list.length} بطاقة معتمدة (${list.length * 2} صفحة: أمامي ثم خلفي لكل موظف)` +
        (rows.length > list.length ? ` — ${rows.length - list.length} بانتظار الاعتماد ما دخلت` : ''));
    } catch (ex) { msg(ex.message, 'err'); }
    finally { btn.disabled = approved().length === 0; setTimeout(() => $('prog').classList.remove('on'), 800); }
  });

  if (pass) start();
})();
