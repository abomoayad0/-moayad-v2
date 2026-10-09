// مؤيّد · المواظبة: الحرمانُ والوقفُ والإخطار (تكليفُ الشاشات ⑧)
// ① إخطاراتُ الغياب: v2_absence_notices — قراءةٌ محضة، ومن لم يُخطَر يُقال سببُه (why_ar) فلا يُظنّ خللًا
// ② لوحةُ الحرمان: v2_denial_board — need_ar تحت كلّ صفّ: ما يبقى حتى يصحّ القرار، لا «يستحقّ»
//    والقرار: v2_denial_decide (للمدير وحدَه) · ومحضرُ اللجنة يُختار من نموذج ١٢ للطالب (v2_form_open) لا يُكتب
//    والإلغاء: v2_denial_cancel — بسببٍ مكتوب، صفٌّ ثالثٌ لا حذف
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

  const cls = (x) => (x.grade != null ? 'الصفّ ' + x.grade + (x.section ? ' / ' + x.section : '') : '');
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
    // لا جدولَ فارغ: إن لم يكن صفٌّ فالملخّصُ وحدَه
    for (const x of d.rows || []) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (x.name || '') + (cls(x) ? ' — ' + cls(x) : '')),
        el('p', 'rs-meta', 'غيابُه بغير عذر ' + x.days + ' · والحدُّ ' + x.limit + ' من ' + x.year_days + ' يومًا دراسيًّا'));
      const tags = el('p');
      tags.append(el('span', 'rs-tag', x.crossed ? 'تجاوز الحدّ' : 'لم يبلغ الحدّ'), el('span', 'rs-tag', x.warned ? 'أُنذر وليُّه' : 'لم يُنذَر وليُّه'));
      if (x.decided) tags.appendChild(el('span', 'rs-tag own', 'صدر القرار'));
      f.appendChild(tags);
      // روحُ اللوحة: ما يبقى حتى يصحّ القرار — كما جاء
      if (x.need_ar) f.appendChild(el('div', 'rs-info', x.need_ar));
      const r = el('div', 'rs-row');
      r.appendChild(btn('قرارُ الحرمان', 'rs-btn', () => decideForm(x)));
      f.appendChild(r);
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize($('denCard'));
  }

  // القرار: محضرُ اللجنة يُختار من نموذج ١٢ للطالب (آخرُ محضرٍ غيرِ مسحوب كما يرجعه v2_form_open) — لا حقلًا يُكتب
  // ولا يُعطَّل الزرّ بحساب: إن نقص شرطٌ ردّه الجسرُ بنصّه
  async function decideForm(x) {
    const { data: fo, error: fe } = await M.rpc('v2_form_open', { p_form: 12, p_student: x.student, p_ref: null, p_task: null }, 'محضر لجنة التوجيه');
    const items = []; let pre = null;
    const n = el('div');
    if (fe) n.appendChild(el('div', 'notice err', errText(fe)));
    else if (fo && fo.entry && fo.entry.id) {
      items.push([fo.entry.id, (fo.title_ar || 'محضر لجنة التوجيه') + ' — ' + (fo.entry.status === 'final' ? 'مُقفَل' : 'لم يُقفل بعد')]);
      pre = fo.entry.id;
    } else n.appendChild(el('p', 'rs-meta', 'لا محضرَ لجنة توجيهٍ (نموذج ١٢) لهذا الطالب'));
    const fields = [{ key: 'info', type: 'node', node: n }];
    if (items.length) fields.push({ key: 'entry', type: 'pick', label: 'محضرُ لجنة التوجيه', items, value: pre });
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
        el('p', 'rs-meta', [x.triggered_ar ? 'بدأت ' + x.triggered_ar : null, 'أيّامُها ' + x.days, x.excused ? 'بعذر' : null, 'بنودٌ مفتوحة ' + x.open_tasks].filter(Boolean).join(' · ')));
      if (x.why_ar) f.appendChild(el('div', 'rs-info', x.why_ar));
      if (x.counsel_case === false) f.appendChild(el('div', 'rs-need', 'ولا حالةَ له عند الموجّه الطلابيّ — فأحِله إليه، فالوقفُ حمايةٌ لا إهمال'));
      const r = el('div', 'rs-row');
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
