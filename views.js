// مؤيّد · ثوابتُ شاشات الأدوار السبع (المحاكي) — مشتركةٌ بينها كي لا تختلف شاشةٌ عن أختها.
// رأسُ الصفة · شريطُ النتيجة · الشرائط · الزرُّ المعطَّل بسببه · اللوحُ المنزلق · الأرقامُ العربيّة.
// لا حسابَ هنا ولا نصَّ حكمٍ: كلُّ ذلك من القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el } = M;

  // الأرقامُ عربيّةٌ في العرض — لما ترجعه القاعدةُ بأرقامٍ غربيّة (الرقم · التاريخ): تحويلُ أرقامٍ لا حساب
  const ar = (v) => String(v == null ? '' : v).replace(/[0-9]/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  function arabize(node) {
    const w = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    for (let t = w.nextNode(); t; t = w.nextNode()) t.nodeValue = ar(t.nodeValue);
  }
  const btn = (text, cls, fn) => {
    const b = el('button', cls, text);
    b.type = 'button';
    if (fn) b.addEventListener('click', fn);
    return b;
  };
  // فعلٌ لم يُبنَ في المحرّك: زرٌّ معطَّلٌ ومعه سببُه
  const notBuilt = (text) => {
    const w = el('span', 'rs-off-act');
    const b = btn(text, 'rs-btn soft');
    b.disabled = true;
    w.append(b, el('small', null, 'لم يُبنَ بعد'));
    return w;
  };
  // بطاقةٌ لبندٍ لم يُبنَ: عنوانُه ثمّ «لم يُبنَ بعد»
  const offCard = (title, meta) => {
    const c = el('section', 'rs-card rs-off');
    c.appendChild(el('h3', null, title));
    if (meta) c.appendChild(el('p', 'rs-meta', meta));
    c.appendChild(el('div', 'rs-note', 'لم يُبنَ بعد — لا جسرَ له في القاعدة.'));
    return c;
  };

  // رأسُ الشاشة: الصفةُ من v2_me
  function renderRole() {
    const me = M.state.me || {};
    $('roleLine').hidden = !me.role_ar;
    $('roleText').textContent = '';
    $('roleText').append('تعمل بصفة ', el('b', null, me.role_ar || ''));
  }

  // شريطُ النتيجة: نصُّه من القاعدة، ويبقى حتى الفعل التالي
  function flash(kind, text, acts) {
    const f = $('flash');
    f.className = 'flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (acts && acts.length) {
      const row = el('span', 'rs-row');
      for (const a of acts) row.appendChild(a);
      f.appendChild(row);
    }
    f.hidden = false;
    arabize(f);
  }

  // شرائطُ الاختيار القصير (٢–٩): [[value, text]] ⇒ onPick(value)
  function pick(box, items, cur, onPick) {
    box.textContent = '';
    for (const [v, t] of items) {
      const s = el('span', v === cur ? 'on' : null, t);
      s.setAttribute('role', 'button');
      s.tabIndex = 0;
      s.setAttribute('aria-pressed', String(v === cur));
      const go = () => onPick(v);
      s.addEventListener('click', go);
      s.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
      box.appendChild(s);
    }
    arabize(box);
  }

  // اللوحُ المنزلق من الأسفل — لما يحتاج حقولًا وحدَه
  function sheet(id) {
    const m = $(id);
    const close = () => { m.hidden = true; };
    m.addEventListener('click', (e) => { if (e.target === m) close(); });
    return { open: () => { m.hidden = false; }, close };
  }

  // سجلُّ أحداثٍ مطويّ — يُبنى في .rs-dtb
  function events(box, evs) {
    box.textContent = '';
    for (const e of evs) {
      const d = el('div');
      d.append(el('b', null, e.title || ''), document.createTextNode(' · ' + (e.on || '') + (e.body ? ' — ' + e.body : '')));
      box.appendChild(d);
    }
    if (!evs.length) box.appendChild(el('div', null, 'لا أحداثَ بعد.'));
    arabize(box);
  }


  // قائمةٌ طويلةٌ ببحث (المنسوبون · الطلّاب): [[value, text, sub]] ⇒ onPick(value) — وتُرجع { get, set }
  function chooser(box, items, cur, onPick) {
    box.textContent = '';
    const q = el('input');
    q.type = 'search';
    q.placeholder = 'ابحث بالاسم';
    const list = el('div', 'rs-list');
    list.setAttribute('role', 'listbox');
    let val = cur == null ? null : cur;
    const draw = () => {
      list.textContent = '';
      const t = q.value.trim();
      let n = 0;
      for (const [v, text, sub] of items) {
        if (t && !(text + ' ' + (sub || '')).includes(t)) continue;
        if (++n > 40) break;
        const b = el('button', 'rs-item' + (v === val ? ' on' : ''));
        b.type = 'button';
        b.append(el('span', null, text), el('small', null, sub || ''));
        b.addEventListener('click', () => { val = v; draw(); if (onPick) onPick(v); });
        list.appendChild(b);
      }
      if (!n) list.appendChild(el('div', 'rs-meta', 'لا نتائج.'));
      arabize(list);
    };
    q.addEventListener('input', draw);
    box.append(q, list);
    draw();
    return { get: () => val, set: (v) => { val = v; draw(); } };
  }

  // اللوحُ المنزلق بحقوله — لما يحتاج حقولًا وحدَه. onOk(values) يرجع خطأ القاعدة أو null:
  // فإن رجع خطأٌ بقي اللوحُ بما كُتب فيه، وعُرض نصُّه كما هو في أعلاه.
  // الحقول: { key, type: text|textarea|date|time|number|pick|choose|file, label, items, value, hint }
  let formBox = null;
  function form(o) {
    if (!formBox) {
      formBox = el('div', 'rs-modal');
      formBox.hidden = true;
      const sh = el('div', 'sheet');
      sh.setAttribute('role', 'dialog');
      sh.setAttribute('aria-modal', 'true');
      formBox.appendChild(sh);
      document.body.appendChild(formBox);
      formBox.addEventListener('click', (e) => { if (e.target === formBox && !formBox.busy) formBox.hidden = true; });
    }
    const sh = formBox.firstChild;
    sh.textContent = '';
    sh.appendChild(el('h3', null, o.title));
    if (o.what) sh.appendChild(el('p', 'rs-meta', o.what));
    const err = el('div', 'flash bad');
    err.hidden = true;
    sh.appendChild(err);
    const get = {};
    for (const f of o.fields || []) {
      const id = 'fm_' + f.key;
      if (f.type === 'pick' || f.type === 'choose') {
        sh.appendChild(el('div', 'rs-label', f.label));
        const box = el('div', f.type === 'pick' ? 'rs-pick' : null);
        sh.appendChild(box);
        if (f.type === 'pick') {
          let v = f.value == null ? null : f.value;
          const draw = () => pick(box, f.items, v, (x) => { v = x; draw(); if (f.onChange) f.onChange(x, api); });
          draw();
          get[f.key] = () => v;
        } else {
          const c = chooser(box, f.items, f.value, null);
          get[f.key] = c.get;
        }
        if (f.hint) sh.appendChild(el('p', 'rs-meta', f.hint));
        continue;
      }
      const l = el('label', null, f.label);
      l.htmlFor = id;
      const inp = f.type === 'textarea' ? el('textarea') : el('input');
      inp.id = id;
      if (f.type === 'textarea') inp.rows = f.rows || 3;
      else inp.type = f.type || 'text';
      if (f.value != null && f.type !== 'file') inp.value = f.value;
      sh.append(l, inp);
      if (f.hint) sh.appendChild(el('p', 'rs-meta', f.hint));
      get[f.key] = f.type === 'file' ? () => inp.files[0] || null
        : f.type === 'number' ? () => (inp.value === '' ? null : Number(inp.value))
        : () => { const v = inp.value.trim(); return v === '' ? null : v; };
    }
    const row = el('div', 'rs-row');
    const ok = btn(o.ok || 'تأكيد', 'rs-btn');
    const no = btn('تراجع', 'rs-btn ghost', () => { formBox.hidden = true; });
    row.append(ok, no);
    sh.appendChild(row);
    const api = { values: () => { const r = {}; for (const k in get) r[k] = get[k](); return r; } };
    ok.addEventListener('click', async () => {
      if (formBox.busy) return;
      formBox.busy = true; ok.disabled = true;
      let e = null;
      try { e = await o.onOk(api.values()); } finally { formBox.busy = false; ok.disabled = false; }
      if (e) { err.textContent = typeof e === 'string' ? e : M.errText(e); err.hidden = false; arabize(err); return; }
      formBox.hidden = true;
    });
    arabize(sh);
    formBox.hidden = false;
    const first = sh.querySelector('textarea, input');
    if (first) first.focus();
  }

  // بطاقةُ إقرار مشاركةٍ من v2_entries_pending — مشتركةٌ بين رائد النشاط والمكلَّف.
  // ما كتبه الطالبُ وشاهدُه، ثمّ الملاحظةُ الإلزاميّة، ثمّ الأحكامُ الأربعة بضغطةٍ واحدة (v2_entry_verdict).
  const VERDICTS = ['نفّذ', 'نفّذ جزئيًّا', 'لم ينفّذ', 'لم يحضر']; // كما يقبلها v2_entry_verdict — والقاعدةُ ترفض غيرها
  let verdictBusy = false;
  function verdictCard(x, opts) {
    const f = el('div', 'rs-file');
    f.append(el('h5', null, (x.student || '') + ' — ' + (x.merit || '')),
      el('p', null, [x.when, x.delegated_to_me ? 'أُحيلت إليك' + (x.delegate_note ? ': ' + x.delegate_note : '') : null].filter(Boolean).join(' · ')));
    const lg = el('div', 'rs-lgd');
    lg.append(el('i', 'k', 'ما كتبه:'), el('i', null, x.what || '—'), el('i', 'k', 'الشاهد:'), el('i', null, x.evidence || '—'));
    f.appendChild(lg);
    if (x.evidence_path) {
      f.appendChild(btn('افتح المرفق', 'rs-btn soft', async () => {
        const { data, error } = await M.sb.storage.from('v2-attachments').createSignedUrl(x.evidence_path, 300);
        if (error) { flash('bad', M.errText(error)); return; }
        window.open(data.signedUrl, '_blank', 'noopener');
      }));
    }
    const l = el('label', null, 'ملاحظتُك (إلزاميّة)');
    const note = el('textarea');
    note.rows = 2;
    note.id = 'n_' + x.entry;
    l.htmlFor = note.id;
    f.append(l, note);
    const row = el('div', 'rs-row');
    for (const v of VERDICTS) {
      row.appendChild(btn(v, 'rs-btn', async () => {
        if (verdictBusy) return;
        verdictBusy = true;
        for (const b of f.querySelectorAll('button')) b.disabled = true;
        flash('wait', 'يُسجَّل… ' + (x.student || '') + ' — ' + v);
        const { error } = await M.rpc('v2_entry_verdict', { p_entry: x.entry, p_verdict: v, p_note: note.value.trim() || null, p_file: null }, 'إقرار مشاركة');
        verdictBusy = false;
        for (const b of f.querySelectorAll('button')) b.disabled = false;
        // رُفض ⇒ تبقى البطاقةُ بملاحظتها، ونصُّ الرفض كما هو
        if (error) { flash('bad', M.errText(error)); return; }
        flash('ok', 'سُجّل الحكم: ' + (x.student || '') + ' — ' + v + ' · وتقدّر اللجنةُ درجتَه');
        if (opts && opts.onDone) opts.onDone();
      }));
    }
    f.appendChild(row);
    if (opts && opts.onDelegate) f.appendChild(btn('أحِل الإقرارَ لغيرك', 'rs-btn ghost', () => opts.onDelegate(x)));
    return f;
  }

  // قرارٌ من محضرٍ معتمدٍ مسندٌ إليك (v2_my_committee_tasks) — وإقرارُ تنفيذه في لوح (v2_committee_task_done)
  function committeeTask(t, onDone) {
    const f = el('div', 'rs-file');
    f.append(el('h5', null, (t.title || '') + (t.student ? ' — ' + t.student : '')),
      el('p', null, [t.committee, 'الاجتماع ' + t.meeting_no, t.held_on, t.carried ? 'مرحَّل' : null].filter(Boolean).join(' · ')));
    if (t.decision) f.appendChild(el('p', null, 'القرار: ' + t.decision));
    if (t.recommend) f.appendChild(el('p', null, 'التوصية: ' + t.recommend));
    if (t.due) {
      const p = el('p', null, 'الموعد ' + t.due + (t.days_left != null ? ' · ' + (t.late ? 'متأخّرٌ ' + Math.abs(t.days_left) + ' يومًا' : 'بقي ' + t.days_left + ' يومًا') : ''));
      if (t.late) p.className = 'rs-state-open';
      f.appendChild(p);
    }
    f.appendChild(btn('أقرّ تنفيذَه', 'rs-btn', () => form({
      title: 'إقرارُ تنفيذ قرار اللجنة', what: t.title || '',
      fields: [{ key: 'note', type: 'textarea', label: 'ما فعلتَ' }, { key: 'ev', label: 'الشاهد (اختياري)' }],
      ok: 'أقرّ التنفيذ',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_committee_task_done', { p_item: t.item, p_note: v.note, p_evidence: v.ev }, 'تنفيذ قرار اللجنة');
        if (error) return error;
        flash('ok', 'أُقرّ تنفيذُ القرار — ' + (t.title || ''));
        if (onDone) onDone();
        return null;
      },
    })));
    arabize(f);
    return f;
  }

  window.MoayadView = { ar, arabize, btn, notBuilt, offCard, renderRole, flash, pick, sheet, events, chooser, form, verdictCard, committeeTask };
})();
