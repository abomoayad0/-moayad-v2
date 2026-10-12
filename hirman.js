// مؤيّد · المواظبة: الحرمانُ والوقفُ والإخطار (تكليفُ الشاشات ⑧)
// ① إخطاراتُ الغياب: v2_absence_notices — قراءةٌ محضة، ومن لم يُخطَر يُقال سببُه (why_ar) فلا يُظنّ خللًا
// ② لوحةُ الحرمان: v2_denial_board — need_ar تحت كلّ صفّ: ما يبقى حتى يصحّ القرار، لا «يستحقّ»
//    والقرار: v2_denial_decide (للمدير وحدَه) · ومحضرُ اللجنة يُختار من نموذج ١٢ للطالب (v2_form_open) لا يُكتب
//    والإلغاء: v2_denial_cancel — بسببٍ مكتوب، صفٌّ ثالثٌ لا حذف · ورقمُ القرار النافذ من اللوحة (decision) والملغاةُ مشطوبةً (cancelled)
//    والإنذار: v2_denial_warn · والمحضرُ يُختار من v2_form_entries(12) · وحالاتُ غياب الطالب: v2_absence_cases_of_student ⇒ v2_halt_escalation · v2_resume_escalation
//    والإحالةُ إلى الموجّه: v2_absence_refer_counselor (حيث can_refer)
// ③ وقفُ التصعيد: v2_halted_cases · v2_resume_escalation — «الوقفُ حمايةٌ لا إهمال — ويبقى الإخطارُ والرعاية»
// والترتيبُ كما يرجع من الباب، ولا درجةَ طالبٍ هنا، وكلُّ رفضٍ يُعرض بنصّه
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash } = V;

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    await Promise.all([loadNotices(), loadDenial(), loadHalted()]);
  }

  // الصفُّ باسمه من الباب (class_ar) لا برقمه — وما لم يرجعه البابُ لا يُعرض رقمًا (ثغرةٌ في التقرير)
  const cls = (x) => x.class_ar || '';
  const fail = (box, sum, error) => { sum.textContent = ''; box.textContent = ''; box.appendChild(el('div', 'notice err', errText(error))); };

  // ---------- ① إخطاراتُ الغياب ----------
  async function loadNotices() {
    const { data, error } = await M.rpc('v2_absence_notices', { p_school: M.state.school, p_date: M.state.date || null }, 'إخطارات الغياب');
    const box = $('notBody'); const sum = $('notSum');
    if (error) { fail(box, sum, error); return; }
    const d = data || {};
    sum.textContent = (d.on_date_ar ? d.on_date_ar + ' — ' : '') + (d.summary_ar || '');
    box.textContent = '';
    // من لم يُخطَر أوّلًا — ومعه سببُه كما جاء
    const miss = d.not_sent || [];
    if (miss.length) {
      box.appendChild(el('div', 'rs-label', 'لم يُخطَر وليُّه'));
      const ul = el('ul', 'rs-acts');
      for (const x of miss) {
        const li = el('li'); const b = el('span'); b.style.flex = '1';
        b.append(el('b', null, x.name || ''), el('div', 'rs-meta', cls(x)), el('div', 'rs-need', x.why_ar || ''));
        li.append(el('i', 'rs-tick', '○'), b); ul.appendChild(li);
      }
      box.appendChild(ul);
    }
    const sent = d.sent || [];
    if (sent.length) {
      box.appendChild(el('div', 'rs-label', 'أُخطر وليُّه'));
      const ul = el('ul', 'rs-acts');
      for (const x of sent) {
        const li = el('li'); const b = el('span'); b.style.flex = '1';
        b.append(el('b', null, x.name || ''), el('div', 'rs-meta', [cls(x), x.sent_ar ? 'أُرسل ' + x.sent_ar : null, x.excused ? 'بعذر' : null, x.excuse_due_ar ? 'مهلةُ العذر ' + x.excuse_due_ar : null].filter(Boolean).join(' · ')));
        li.append(el('i', 'rs-tick ok', '✓'), b); ul.appendChild(li);
      }
      box.appendChild(ul);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    if (d.citation_ar) box.appendChild(el('p', 'rs-cite', d.citation_ar));
    arabize($('notCard'));
  }

  // ---------- ② لوحةُ الحرمان ----------
  async function loadDenial() {
    const { data, error } = await M.rpc('v2_denial_board', { p_school: M.state.school }, 'لوحة الحرمان');
    const box = $('denBody'); const sum = $('denSum');
    if (error) { fail(box, sum, error); return; }
    const d = data || {};
    sum.textContent = d.summary_ar || '';
    box.textContent = '';
    // لا جدولَ فارغ: إن لم يكن صفٌّ فالملخّصُ وحدَه · والترتيبُ كما جاء ومعه order_ar
    if ((d.rows || []).length && d.order_ar) box.appendChild(el('p', 'rs-meta', d.order_ar));
    for (const x of d.rows || []) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (x.name || '') + (cls(x) ? ' — ' + cls(x) : '')),
        el('p', 'rs-meta', [x.count_ar, x.left_ar].filter(Boolean).join(' ')));
      const tags = el('p');
      tags.append(el('span', 'rs-tag', x.crossed ? 'تجاوز الحدّ' : 'لم يبلغ الحدّ'), el('span', 'rs-tag', x.warned ? 'أُنذر وليُّه' + (x.warned_on_ar ? ' في ' + x.warned_on_ar : '') : 'لم يُنذَر وليُّه'));
      if (x.decided) tags.appendChild(el('span', 'rs-tag own', 'صدر القرار' + (x.decided_on_ar ? ' في ' + x.decided_on_ar : '')));
      f.appendChild(tags);
      // روحُ اللوحة: ما يبقى حتى يصحّ القرار — كما جاء
      if (x.need_ar) f.appendChild(el('div', 'rs-info', x.need_ar));
      // القراراتُ الملغاةُ مشطوبةً ومعها سببُها ومُلغيها — لا تُحذف
      for (const c of x.cancelled || []) {
        const p = el('p', 'rs-meta');
        const q = el('span', null, 'قرارٌ في ' + (c.decided_on_ar || '')); q.style.textDecoration = 'line-through';
        p.append(q, document.createTextNode(' — أُلغي في ' + (c.cancelled_on_ar || '') + (c.by_ar ? ' · ألغاه ' + c.by_ar : '') + (c.reason_ar ? ' · السبب: ' + c.reason_ar : '')));
        f.appendChild(p);
      }
      const r = el('div', 'rs-row');
      if (!x.warned) r.appendChild(btn('أنذِره الآن', 'rs-btn', () => warn(x)));
      r.appendChild(btn('قرارُ الحرمان', 'rs-btn', () => decideForm(x)));
      if (x.decision) r.appendChild(btn('ألغِ هذا القرار', 'rs-btn irrev', () => cancelForm(x, x.decision)));
      r.appendChild(btn('حالاتُ غيابه', 'rs-btn ghost', () => casesSheet({ id: x.student, name: x.name })));
      f.appendChild(r);
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize($('denCard'));
  }

  // القرار: محضرُ اللجنة يُختار من نموذج ١٢ للطالب (آخرُ محضرٍ غيرِ مسحوب كما يرجعه v2_form_open) — لا حقلًا يُكتب
  // ولا يُعطَّل الزرّ بحساب: إن نقص شرطٌ ردّه الجسرُ بنصّه
  async function decideForm(x) {
    const { data: fo, error: fe } = await M.rpc('v2_form_entries', { p_form: 12, p_student: x.student }, 'محاضر لجنة التوجيه');
    const items = []; let pre = null;
    const n = el('div');
    const rows = (fo && fo.rows) || [];
    if (fe) n.appendChild(el('div', 'notice err', errText(fe)));
    else if (rows.length) {
      for (const e of rows) items.push([e.entry, [e.on_ar, e.final ? 'مُقفَل' : 'لم يُقفل بعد', e.linked_ar, e.by_ar].filter(Boolean).join(' · ')]);
      if (rows.length === 1) pre = rows[0].entry;
      if (fo.note_ar) n.appendChild(el('p', 'rs-meta', fo.note_ar));
    } else n.appendChild(el('p', 'rs-meta', 'لا محضرَ لجنة توجيهٍ (نموذج ١٢) لهذا الطالب'));
    const fields = [{ key: 'info', type: 'node', node: n }];
    if (items.length) fields.push({ key: 'entry', type: 'pick', label: (fo && fo.title_ar) || 'محضرُ لجنة التوجيه', items, value: pre });
    fields.push({ key: 'note', type: 'textarea', label: 'سببُ القرار — يبقى في السجلّ باسمك', rows: 3 });
    V.form({
      title: 'قرارُ الحرمان من الانتقال', what: (x.name || '') + (cls(x) ? ' — ' + cls(x) : ''),
      fields,
      ok: 'أصدِر القرار',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_denial_decide', { p_student: x.student, p_committee_entry: v.entry || null, p_note: v.note }, 'قرار الحرمان');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُثبته الجسر';
        setTimeout(() => decidedCard(x, data), 0);
        loadDenial();
        return null;
      },
    });
  }
  // ما رجع من القرار يُعرض كما هو — ومنه وحدَه يُلغى، فاللوحةُ لا ترجع رقمَ القرار
  function decidedCard(x, d) {
    const n = el('div');
    n.appendChild(el('div', 'rs-info', d.note_ar || ''));
    n.appendChild(el('p', 'rs-meta', 'غيابُه ' + d.days + ' · والحدُّ ' + d.limit));
    if (d.citation_ar) n.appendChild(el('p', 'rs-cite', d.citation_ar));
    V.form({
      title: 'صدر القرار', what: x.name || '',
      fields: [{ key: 'c', type: 'node', node: n }],
      ok: false, cancel: 'أغلق',
      extra: [{ text: 'ألغِ هذا القرار', cls: 'rs-btn irrev', onClick: async () => { setTimeout(() => cancelForm(x, d.decision), 0); return null; } }],
    });
  }
  function cancelForm(x, decision) {
    V.form({
      title: 'إلغاءُ قرار الحرمان', what: x.name || '',
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الإلغاء — يبقى مع القرار في السجلّ', rows: 3 }],
      ok: 'ألغِ القرار', okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_denial_cancel', { p_decision: decision, p_reason: v.why }, 'إلغاء قرار الحرمان');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُثبته الجسر';
        flash('ok', data.note_ar || '');
        loadDenial();
        return null;
      },
    });
  }

  // الإنذار: v2_denial_warn — يكتب رسالةَ وليّ الأمر في سجلّ الأحداث بنفسه، وإن سبق قال ذلك بنصّه
  async function warn(x) {
    const { data, error } = await M.rpc('v2_denial_warn', { p_student: x.student }, 'إنذار وليّ الأمر');
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', (data && data.said_ar) || '');
    loadDenial();
  }

  // حالاتُ غياب الطالب: v2_absence_cases_of_student — والوقفُ حيث can_halt، والرفعُ حيث can_resume
  async function casesSheet(stu) {
    const { data, error } = await M.rpc('v2_absence_cases_of_student', { p_student: stu.id }, 'حالات غياب الطالب');
    const n = el('div');
    if (error) n.appendChild(el('div', 'notice err', errText(error)));
    else {
      const d = data || {};
      if (!(d.rows || []).length) n.appendChild(el('p', 'rs-meta', 'لا حالةَ غيابٍ له.'));
      for (const c of d.rows || []) {
        const f = el('div', 'rs-file');
        f.append(el('h5', null, 'بدأت ' + (c.triggered_ar || '')),
          el('p', 'rs-meta', [c.days_ar, c.excused ? 'بعذر' : null, c.tasks_ar].filter(Boolean).join(' · ')));
        if (c.halted) f.appendChild(el('span', 'rs-tag own', 'موقوفٌ تصعيدُها'));
        if (c.halt_reason) f.appendChild(el('div', 'rs-info', c.halt_reason));
        const r = el('div', 'rs-row');
        if (c.can_halt) r.appendChild(btn('أوقِف التصعيد', 'rs-btn', () => { closeSheet(); setTimeout(() => haltForm(stu, c), 0); }));
        if (c.can_resume) r.appendChild(btn('ارفع الوقف', 'rs-btn', () => { closeSheet(); setTimeout(() => resumeForm({ case: c.case, student: stu.name }), 0); }));
        f.appendChild(r);
        if (c.can_halt) f.appendChild(el('p', 'rs-meta', 'الوقفُ حمايةٌ لا إهمال — ويبقى الإخطارُ والرعاية'));
        n.appendChild(f);
      }
      if (d.note_ar) n.appendChild(el('p', 'rs-meta', d.note_ar));
    }
    V.form({ title: 'حالاتُ غياب الطالب', what: (data && data.student) || stu.name || '', fields: [{ key: 'c', type: 'node', node: n }], ok: false, cancel: 'أغلق' });
  }
  const closeSheet = () => { const m = document.querySelector('.rs-modal:not([hidden])'); if (m) m.hidden = true; };
  function haltForm(stu, c) {
    V.form({
      title: 'وقفُ التصعيد', what: (stu.name || '') + ' · بدأت ' + (c.triggered_ar || ''),
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الوقف — يبقى في السجلّ باسمك', rows: 3 },
        { key: 'n', type: 'node', node: el('p', 'rs-meta', 'الوقفُ حمايةٌ لا إهمال — ويبقى الإخطارُ والرعاية') }],
      ok: 'أوقِف التصعيد',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_halt_escalation', { p_case: c.case, p_reason: v.why }, 'وقف التصعيد');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُثبته الجسر';
        // ومن لا حالةَ له عند الموجّه: النصُّ كما جاء ومعه زرُّ الإحالة
        flash('ok', data.note_ar || '', data.counsel_case === false ? [btn('أحِله إلى الموجّه', 'rs-btn', () => referForm({ case: c.case, student: stu.name }))] : []);
        loadHalted();
        return null;
      },
    });
  }
  // الإحالةُ إلى الموجّه: v2_absence_refer_counselor — وإن كانت له حالةٌ مفتوحةٌ قال ذلك بنصّه
  function referForm(x) {
    V.form({
      title: 'إحالةٌ إلى الموجّه الطلابيّ', what: x.student || '',
      fields: [{ key: 'n', type: 'textarea', label: 'سببُ الإحالة (اختياريّ)', rows: 2 }],
      ok: 'أحِله',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_absence_refer_counselor', { p_case: x.case, p_note: v.n || null }, 'الإحالة إلى الموجّه');
        if (error) return error;
        flash('ok', (data && data.said_ar) || '');
        loadHalted();
        return null;
      },
    });
  }

  // ---------- ③ وقفُ التصعيد ----------
  async function loadHalted() {
    const { data, error } = await M.rpc('v2_halted_cases', { p_school: M.state.school }, 'الحالات الموقوف تصعيدها');
    const box = $('halBody'); const sum = $('halSum');
    if (error) { fail(box, sum, error); return; }
    const d = data || {};
    sum.textContent = d.summary_ar || '';
    box.textContent = '';
    for (const x of d.rows || []) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, x.student || ''),
        el('p', 'rs-meta', [x.triggered_ar ? 'بدأت ' + x.triggered_ar : null, x.days_ar, x.excused ? 'بعذر' : null, x.open_tasks_ar].filter(Boolean).join(' · ')));
      if (x.why_ar) f.appendChild(el('div', 'rs-info', x.why_ar));
      if (x.counsel_case === false) f.appendChild(el('div', 'rs-need', 'ولا حالةَ له عند الموجّه الطلابيّ — فأحِله إليه، فالوقفُ حمايةٌ لا إهمال'));
      const r = el('div', 'rs-row');
      if (x.can_refer) r.appendChild(btn('أحِله إلى الموجّه', 'rs-btn pri', () => referForm(x)));
      r.appendChild(btn('ارفع الوقف', 'rs-btn', () => resumeForm(x)));
      f.append(r, el('p', 'rs-meta', 'الوقفُ حمايةٌ لا إهمال — ويبقى الإخطارُ والرعاية'));
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize($('halCard'));
  }
  function resumeForm(x) {
    V.form({
      title: 'رفعُ وقفِ التصعيد', what: x.student || '',
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الرفع — ويبقى معه سببُ الوقف', rows: 3 }],
      ok: 'ارفع الوقف',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_resume_escalation', { p_case: x.case, p_reason: v.why }, 'رفع وقف التصعيد');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُثبته الجسر';
        flash('ok', data.note_ar || '');
        loadHalted();
        return null;
      },
    });
  }

  M.start({ screen: 'hirman', onChange: () => refresh() });
})();
