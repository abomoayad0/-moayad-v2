// مؤيّد · النموذج الرسمي — يُملأ في الشاشة ويُحفظ في القاعدة، ثم يُعتمد ويُوقَّع، ويُطبع من المحفوظ.
// form.html?form=8&student=<uuid>&ref=<record_id>&task=<task_id>
// v2_form_open · v2_form_save · v2_form_sign · v2_form_void
// الخانات من schema والجدول من row_schema، ولا يُؤلَّف حقل ولا يُحسب شيء في الشاشة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'form';

  const q = new URLSearchParams(location.search);
  const P = {
    form: Number(q.get('form')), student: q.get('student') || null,
    ref: q.get('ref') || null, task: q.get('task') || null,
  };
  const ui = { doc: null, rows: [] };
  // داخل نافذة المهامّ (embed=1): يُبلغ الشاشة الأمّ بكل تغيير
  const EMBED = q.get('embed') === '1' && window.parent !== window;
  if (EMBED) document.body.classList.add('embed');
  function notifyParent() {
    if (EMBED) window.parent.postMessage({ moayad: 'form-changed' }, location.origin);
  }

  // الوجهة بأسمائها من القاعدة (goes_to_ar)
  function goesText() { return ((ui.doc && ui.doc.goes_to_ar) || []).join(' · '); }

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  function isFinal() { return !!(ui.doc && ui.doc.entry && ui.doc.entry.status === 'final'); }
  // من يملك التعديل تحكم به القاعدة (can_edit)
  function canEdit() { return !!(ui.doc && ui.doc.can_edit); }

  // مفتاح الصف الآلي من أعمدته الآلية — ليُعرف ما جاء من auto_rows فلا يُحذف
  function autoKey(row) {
    const ks = (ui.doc.row_schema || []).filter((c) => c.input === 'auto').map((c) => c.key);
    if (!ks.length || ks.every((k) => row[k] == null)) return null;
    return JSON.stringify(ks.map((k) => row[k] == null ? null : row[k]));
  }
  function isFixed(row) {
    const k = autoKey(row);
    return k != null && (ui.doc.auto_rows || []).some((a) => autoKey(a) === k);
  }

  // قيمة الحقل الآلي من auto بمفتاحه كما هو — لا مطابقة في الشاشة
  function autoValue(key) {
    const a = (ui.doc && ui.doc.auto) || {};
    const v = a[key];
    return v == null || typeof v === 'object' ? null : String(v);
  }

  // خانة بحسب input من القاعدة
  function control(f, value, disabled, idp) {
    let c;
    switch (f.input) {
      case 'longtext':
        c = document.createElement('textarea'); c.rows = 3; break;
      case 'date':
        c = document.createElement('input'); c.type = 'date'; break;
      case 'number':
        c = document.createElement('input'); c.type = 'number'; c.inputMode = 'decimal'; break;
      case 'checkbox':
        c = document.createElement('input'); c.type = 'checkbox'; break;
      case 'select': {
        c = document.createElement('select');
        const ph = document.createElement('option');
        ph.value = ''; ph.textContent = '—';
        c.appendChild(ph);
        for (const o of f.options || []) {
          const op = document.createElement('option');
          op.value = o; op.textContent = o;
          c.appendChild(op);
        }
        break;
      }
      default:
        c = document.createElement('input'); c.type = 'text';
    }
    c.id = idp + f.key;
    c.dataset.key = f.key;
    if (f.input === 'checkbox') c.checked = value === true || value === 'true';
    else if (value != null) c.value = value;
    c.disabled = disabled;
    return c;
  }

  function read(c) {
    if (c.type === 'checkbox') return c.checked;
    const v = c.value.trim();
    if (v === '') return null;
    return c.type === 'number' && !isNaN(Number(v)) ? Number(v) : v;
  }

  // ---------- العرض ----------
  function render() {
    const d = ui.doc;
    const e = d.entry;
    const fin = isFinal();
    const ro = fin || !canEdit();
    document.title = 'مؤيّد · ' + (d.title_ar || 'نموذج');
    $('barTitle').textContent = 'نموذج ' + d.form_no + ': ' + (d.title_ar || '');
    const sh = $('sheet');
    sh.textContent = '';

    const auto = d.auto || {};
    const school = auto.school || (d.doc && d.doc.school);
    if (school) sh.appendChild(el('div', 'sch', school));
    sh.appendChild(el('h1', null, d.title_ar || ''));
    sh.appendChild(el('div', 'src', 'نموذج رقم ' + d.form_no + (d.source ? ' · ' + d.source : '')));
    const st = el('div', 'fstatus ' + (fin ? 'final' : e ? 'draft' : 'new'),
      fin ? 'معتمد' + (e.finalized_h ? ' في ' + e.finalized_h : '') + (e.filled_role ? ' — ' + e.filled_role : '')
        : e ? 'مسوّدة محفوظة' : 'جديد — لم يُحفظ بعد');
    sh.appendChild(st);
    // إلى من يصل — قبل الاعتماد لئلّا يُفاجأ
    if (!fin && goesText()) sh.appendChild(el('div', 'goes noprint', 'عند الاعتماد يصل إلى: ' + goesText()));
    if (!fin && !canEdit()) sh.appendChild(el('div', 'notice err noprint', 'لا تملك صفتك تعبئة هذا النموذج — يُعرض للاطّلاع.'));

    // الخانات
    const data = (e && e.data) || {};
    const t = el('table', 'kv');
    for (const f of d.schema || []) {
      const tr = el('tr');
      const th = el('th', null, f.label + (f.required && f.input !== 'auto' ? ' *' : ''));
      const td = el('td');
      if (f.input === 'auto') {
        const v = autoValue(f.key);
        td.appendChild(v == null ? el('span', 'blank', '—') : document.createTextNode(v));
        td.classList.add('auto');
      } else {
        td.appendChild(control(f, data[f.key], ro, 'f_'));
        if (f.hint && !ro) td.appendChild(el('div', 'hint', f.hint));
      }
      tr.append(th, td);
      t.appendChild(tr);
    }
    sh.appendChild(t);

    // الجدول — تُضاف صفوفه وتُحذف
    const rs = d.row_schema || [];
    if (rs.length) {
      sh.appendChild(el('h2', null, 'الجدول'));
      const wrap = el('div', 'gridwrap');
      const g = el('table', 'grid');
      const hr = el('tr');
      for (const c of rs) hr.appendChild(el('th', null, c.label));
      if (!ro) hr.appendChild(el('th', 'noprint', ''));
      g.appendChild(hr);
      ui.rows.forEach((row, i) => {
        const tr = el('tr');
        for (const c of rs) {
          const td = el('td');
          if (c.input === 'auto') {
            const v = row[c.key];
            td.appendChild(v == null ? el('span', 'blank', '—') : document.createTextNode(String(v)));
            td.classList.add('auto');
          } else {
            const ctl = control(c, row[c.key], ro, 'r' + i + '_');
            ctl.addEventListener('input', () => { row[c.key] = read(ctl); });
            ctl.addEventListener('change', () => { row[c.key] = read(ctl); });
            td.appendChild(ctl);
          }
          tr.appendChild(td);
        }
        if (!ro) {
          const td = el('td', 'noprint');
          // صفوف القاعدة (auto_rows) لا تُحذف
          if (!isFixed(row)) {
            const del = el('button', 'rowdel', '✕');
            del.type = 'button';
            del.title = 'احذف الصف';
            del.addEventListener('click', () => { ui.rows.splice(i, 1); render(); });
            td.appendChild(del);
          }
          tr.appendChild(td);
        }
        g.appendChild(tr);
      });
      wrap.appendChild(g);
      sh.appendChild(wrap);
      if (!ro) {
        const add = el('button', 'btn-ghost wide noprint', '+ أضف صفاً');
        add.type = 'button';
        add.addEventListener('click', () => { ui.rows.push({}); render(); });
        sh.appendChild(add);
      }
    }

    // الحفظ والاعتماد
    if (!ro) {
      const acts = el('div', 'dlg-acts noprint');
      const draft = el('button', 'btn-ghost', 'حفظ مسوّدة');
      draft.type = 'button';
      draft.addEventListener('click', () => save(false));
      const final = el('button', 'btn-accept', 'اعتماد');
      final.type = 'button';
      final.addEventListener('click', () => save(true));
      acts.append(draft, final);
      sh.appendChild(acts);
    }

    // التوقيعات — بعد الاعتماد
    const signs = el('div', 'signs');
    const sigs = (e && e.signatures) || [];
    for (const who of d.signers || []) {
      const box = el('div');
      const done = sigs.filter((x) => x.signer === who);
      const last = done[done.length - 1];
      box.append(el('div', 'line', last ? (last.signed ? '✓ أقرّ' : '✕ امتنع') : ''), el('div', null, who));
      if (last) {
        box.appendChild(el('div', last.signed ? 'meta' : 'meta red',
          (last.signed ? 'أقرّ' : 'امتنع: ' + (last.reason || '')) + (last.at_h ? ' · ' + last.at_h : '')));
      }
      if (fin && !last) {
        const a = el('div', 'acts two noprint');
        const y = el('button', 'a-accept', 'أقرّ');
        y.type = 'button';
        y.addEventListener('click', () => sign(who, true));
        const n = el('button', 'a-reject', 'امتنع بسبب');
        n.type = 'button';
        n.addEventListener('click', () => sign(who, false));
        a.append(y, n);
        box.appendChild(a);
      } else if (!fin) {
        box.appendChild(el('div', 'blank', 'يُوقَّع بعد الاعتماد'));
      }
      signs.appendChild(box);
    }
    sh.appendChild(signs);

    // المعتمد لا يُعدَّل — يُلغى بسبب مكتوب ثم يُعاد، والقاعدة تحكم بمن يلغي
    if (fin && ui.doc.can_void) {
      const v = el('button', 'btn-ghost wide noprint voidbtn', 'ألغِ النموذج بسبب');
      v.type = 'button';
      v.addEventListener('click', voidEntry);
      sh.appendChild(v);
    }
    sh.hidden = false;
  }

  function collect() {
    const data = {};
    for (const f of ui.doc.schema || []) {
      if (f.input === 'auto') continue;
      const c = $('f_' + f.key);
      if (c) data[f.key] = read(c);
    }
    // الصف بأعمدة row_schema (والآلي منها كما أرجعته القاعدة)، ولا تُرسل الصفوف الفارغة كلها
    const keys = (ui.doc.row_schema || []).map((c) => c.key);
    const rows = ui.rows
      .map((r) => Object.fromEntries(keys.map((k) => [k, r[k] == null ? null : r[k]])))
      .filter((r) => Object.values(r).some((v) => v != null && v !== '' && v !== false));
    return { data, rows };
  }

  // ---------- الحفظ والتوقيع ----------
  async function save(final) {
    const { data, rows } = collect();
    const e = ui.doc.entry;
    const { data: res, error } = await M.rpc('v2_form_save', {
      p_form: P.form, p_data: data, p_rows: rows, p_student: P.student, p_ref: P.ref,
      p_task: P.task, p_entry: e ? e.id : null, p_final: final,
    }, final ? 'اعتماد نموذج' : 'حفظ مسوّدة نموذج');
    if (error) { toast((final ? 'لم يُعتمد النموذج:\n' : 'لم تُحفظ المسوّدة:\n') + errText(error)); return; }
    notifyParent();
    if (final) {
      const to = goesText();
      toast('اعتُمد النموذج' + (to ? ' · وصل إلى: ' + to : '') +
        (res && res.delivered != null ? ' (' + res.delivered + ' نسخة)' : '') + '\nويُوقَّع الآن.', true);
    } else {
      toast('حُفظت المسوّدة.', true);
    }
    await open();
  }

  async function sign(who, signed) {
    let reason = null;
    if (!signed) {
      $('refWho').textContent = who;
      $('refReason').value = '';
      $('refOk').disabled = true;
      if (await ask($('refuseDlg')) !== 'ok') return;
      reason = $('refReason').value.trim();
    }
    const { data: res, error } = await M.rpc('v2_form_sign', {
      p_entry: ui.doc.entry.id, p_signer: who, p_signed: signed, p_refuse_reason: reason,
    }, 'توقيع نموذج');
    if (error) { toast('لم يُسجَّل التوقيع:\n' + errText(error)); return; }
    notifyParent();
    const left = (res && res.remaining) || [];
    toast((signed ? 'سُجّل إقرار ' + who + '.' : 'سُجّل امتناع ' + who + '.') +
      (left.length ? '\nبقي: ' + left.join(' · ') : '\nاكتملت التوقيعات.'), true);
    await open();
  }

  async function voidEntry() {
    $('voidReason').value = '';
    $('voidOk').disabled = true;
    if (await ask($('voidDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_form_void',
      { p_entry: ui.doc.entry.id, p_reason: $('voidReason').value.trim() }, 'إلغاء نموذج');
    if (error) { toast('لم يُلغَ النموذج:\n' + errText(error)); return; }
    notifyParent();
    toast('أُلغي النموذج. ويُعبّأ من جديد.', true);
    await open();
  }

  $('voidReason').addEventListener('input', () => { $('voidOk').disabled = $('voidReason').value.trim() === ''; });
  $('refReason').addEventListener('input', () => { $('refOk').disabled = $('refReason').value.trim() === ''; });

  // ---------- الفتح ----------
  async function open() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_form_open',
      { p_form: P.form, p_student: P.student, p_ref: P.ref, p_task: P.task }, 'فتح نموذج ' + P.form);
    if (error) { showLoadErr('تعذّر فتح النموذج: ' + errText(error)); return; }
    if (!data) { showLoadErr('لم يُرجع النموذج شيئاً.'); return; }
    ui.doc = data;
    // المحفوظ أولاً، ثم ما في auto_rows ولم يُحفظ بعد (ما دام النموذج لم يُعتمد)
    ui.rows = ((data.entry && data.entry.rows) || []).map((r) => Object.assign({}, r));
    if (!(data.entry && data.entry.status === 'final')) {
      const have = new Set(ui.rows.map(autoKey).filter((k) => k != null));
      for (const a of data.auto_rows || []) {
        const k = autoKey(a);
        if (k == null || !have.has(k)) ui.rows.push(Object.assign({}, a));
      }
    }
    render();
  }

  $('printBtn').addEventListener('click', () => window.print());
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });

  (async () => {
    if (!P.form) { showLoadErr('رابط النموذج ناقص: يلزم رقم النموذج.'); return; }
    const { data: sess } = await M.sb.auth.getSession();
    if (!sess.session) { location.replace('./'); return; }
    // تُفرض صفة إن لم تكن مختارة — كبقيّة الشاشات قبل أيّ جسر
    try { await M.defaultRole(); } catch (e) { showLoadErr('تعذّر فرض الصفة: ' + errText(e)); return; }
    await open();
  })();
})();
