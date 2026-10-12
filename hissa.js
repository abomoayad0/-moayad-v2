// مؤيّد · الحصّة (تكليفُ الباني ④) — شاشةٌ واحدةٌ بثلاث طبقات: جلسةُ الحصّة ← شبكةُ الفصل ← بطاقةُ الطالب
// ① الجلسة: v2_my_now · v2_my_sessions (غيرُ ثابت: ينادي الإقفالَ الآليّ — فيُنادى عند الفتح وبعد كلّ فعلٍ وحدَه، ولا يُخزَّن)
//    v2_session_open · v2_session_attendance · v2_session_lesson · v2_session_close — والجلسةُ من الجدول، وbasis_ar كما جاء
//    وما ينتظرني: v2_card_my_steps ⇒ v2_card_step_do · ومن خرج الآن: v2_exit_now ⇒ v2_exit_back
// ② الشبكة: v2_loyalty_of_section (الطلّابُ بالترتيب الذي جاء — ولا ترتيبَ من الشاشة) · v2_roles_of_section · v2_exit_now · v2_work_board
// ③ البطاقة: v2_card_open بابٌ واحد — التبويباتُ العشرةُ بترتيبها في صفّين، والمغلقُ مغلقٌ بسببه ولا يُخفى
//    ممارسات/إيجابيات: v2_card_act (practice) · ملاحظة: v2_card_act (note) · تصحيح: v2_card_undo · اللائحة: v2_conduct_list ⇒ v2_record_behavior
//    واجب: v2_work_set · v2_work_void · خروج: v2_exit_out · v2_exit_back · دور: v2_role_assign · v2_role_end
//    صحّته: v2_card_health للقراءة وحدها (health_from) · الدرسُ من v2_session_lesson_options · وأنواعُ العمل من v2_work_kinds · نقاطُ الولاء: v2_loyalty_catalog · v2_loyalty_wallet · v2_loyalty_record · v2_loyalty_spend · v2_loyalty_undo
// ولا رقمَ في الشاشة: كلُّ مهلةٍ وسقفٍ وعتبةٍ من الباب · وكلُّ رفضٍ بنصّه · ولا زرَّ يُعطَّل بحساب
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash } = V;

  const ui = { sec: null, stu: null, card: null, tab: null, healthT: null };
  const arr = (x) => (Array.isArray(x) ? x : (x && Array.isArray(x.rows) ? x.rows : []));
  const err = (box, e) => { box.textContent = ''; box.appendChild(el('div', 'notice err', errText(e))); };
  const hm = (t) => (t ? String(t).slice(0, 5) : '');

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    show(1);
    await Promise.all([loadNow(), loadSessions(), loadSteps(), loadExitsNow()]);
  }
  function show(n) {
    $('layer1').hidden = n !== 1;
    $('gridCard').hidden = n !== 2;
    $('cardView').hidden = n !== 3;
    if (n !== 3 && ui.healthT) { clearTimeout(ui.healthT); ui.healthT = null; }
    window.scrollTo(0, 0);
  }
  $('gridBack').addEventListener('click', () => { show(1); loadSessions(); });
  $('cardBack').addEventListener('click', () => { if (ui.sec) { show(2); loadGrid(); } else show(1); });

  // ---------- ① الآن ----------
  async function loadNow() {
    const { data, error } = await M.rpc('v2_my_now', { p_school: M.state.school }, 'الآن');
    const box = $('now');
    if (error) { err(box, error); return; }
    box.textContent = '';
    const rows = arr(data);
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', 'لا حصّةَ عليك الآن.')); return; }
    for (const x of rows) box.appendChild(el('p', null, ['الحصّة ' + x.period_no, x.section_label, x.subject_ar, x.room_ar, hm(x.starts_at) + ' — ' + hm(x.ends_at), x.state].filter(Boolean).join(' · ')));
    arabize(box);
  }

  // ---------- ① حصصي اليوم ----------
  async function loadSessions() {
    const { data, error } = await M.rpc('v2_my_sessions', { p_date: M.state.date || null }, 'حصصي اليوم');
    const box = $('sessions');
    if (error) { err(box, error); return; }
    box.textContent = '';
    const rows = arr(data);
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', 'لا حصصَ لك اليومَ.')); return; }
    for (const s of rows) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, 'الحصّة ' + s.period + ' · ' + (s.section_ar || '') + ' · ' + (s.subject || '')),
        el('p', 'rs-meta', [s.at, s.basis_ar].filter(Boolean).join(' · ')));
      // الحالُ كما جاء — والمقفلةُ آليًّا بنقصٍ غيرُ المقفلة تامّة
      const st = el('p');
      const cls = !s.opened ? 'wait' : s.closed ? (s.auto_closed && (!s.attendance_done || !s.lesson_ar) ? 'late' : 'done') : 'open';
      st.appendChild(el('span', 'rs-state ' + cls, s.state_ar || ''));
      if (s.auto_closed) st.appendChild(el('span', 'rs-tag', 'أُقفلت آليًّا'));
      f.appendChild(st);
      if (s.note_ar) f.appendChild(el('div', 'rs-info', s.note_ar));
      if (s.lesson_ar) f.appendChild(el('p', null, 'الدرس: ' + s.lesson_ar));
      const r = el('div', 'rs-row');
      if (!s.opened || s.closed) r.appendChild(btn('افتح الحصّة', 'rs-btn' + (s.opened ? '' : ' pri'), () => openSession(s)));
      if (s.opened && !s.closed) {
        if (!s.attendance_done) r.appendChild(btn('اعتمد الحضور', 'rs-btn pri', () => attendance(s)));
        r.appendChild(btn(s.lesson_ar ? 'غيّر الدرس' : 'سمِّ الدرس', 'rs-btn', () => lessonForm(s)));
        r.appendChild(btn('أقفِل الحصّة', 'rs-btn', () => closeForm(s)));
      }
      r.appendChild(btn('افتح الفصل', 'rs-btn ghost', () => { ui.sec = { id: s.section, label: s.section_ar, subject: s.subject, period: s.period }; show(2); loadGrid(); }));
      f.appendChild(r);
      box.appendChild(f);
    }
    arabize(box);
  }
  async function act(fn, args, label, after) {
    const { data, error } = await M.rpc(fn, args, label);
    if (error) { flash('bad', errText(error)); return null; }
    flash('ok', (data && (data.msg || data.note_ar || data.summary_ar)) || '');
    if (after) after(data);
    return data;
  }
  const openSession = (s) => act('v2_session_open', { p_period: s.period, p_section: s.section }, 'فتح الحصّة', loadSessions);
  const attendance = (s) => act('v2_session_attendance', { p_session: s.session }, 'اعتماد الحضور', loadSessions);
  // الدرس: بنودُ التوزيع من v2_session_lesson_options (والصفُّ يُستخرج من قسم الجلسة) — و note_ar يقول حالَ التوزيع كما جاء
  //        فإن لم يكن توزيعٌ بقي النصُّ الحرّ · والبندُ يُرسل في p_item والنصُّ في p_text
  async function lessonForm(s) {
    const { data: o, error: oe } = await M.rpc('v2_session_lesson_options', { p_session: s.session }, 'بنود الدرس');
    const n = el('div');
    const rows = (o && o.rows) || [];
    if (oe) n.appendChild(el('div', 'notice err', errText(oe)));
    else {
      const d = o || {};
      n.appendChild(el('p', 'rs-meta', [d.grade_ar, d.subject_ar, d.plan_status_ar ? 'التوزيع: ' + d.plan_status_ar : null].filter(Boolean).join(' · ')));
      if (d.note_ar) n.appendChild(el('div', 'rs-info', d.note_ar));
    }
    const items = rows.map((r) => [r.item, [r.week_no != null ? 'الأسبوع ' + r.week_no : null, r.title_ar, r.unit_ar, r.state_ar, r.page_from != null ? 'ص ' + r.page_from + (r.page_to != null ? '–' + r.page_to : '') : null].filter(Boolean).join(' · ')]);
    const cur = rows.find((r) => r.is_current);
    const fields = [{ key: 'info', type: 'node', node: n }];
    if (items.length) fields.push({ key: 'item', type: 'pick', label: 'من التوزيع', items, value: cur ? cur.item : null });
    // والنصُّ لا يُملأ مسبقًا إن كانت بنود: فالبابُ يقدّم النصَّ على البند، فلا يُرسل اسمٌ قديمٌ مع بندٍ مختار
    fields.push({ key: 't', label: items.length ? 'أو اكتبه' : 'الدرس', value: items.length ? '' : (s.lesson_ar || '') });
    V.form({
      title: 'درسُ الحصّة', what: 'الحصّة ' + s.period + ' · ' + (s.section_ar || ''),
      fields,
      ok: 'سمِّه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_session_lesson', { p_session: s.session, p_item: v.item || null, p_text: v.t || null }, 'تسمية الدرس');
        if (error) return error;
        flash('ok', (data && data.msg) || ''); loadSessions(); return null;
      },
    });
  }
  function closeForm(s) {
    V.form({
      title: 'إقفالُ الحصّة', what: 'الحصّة ' + s.period + ' · ' + (s.section_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظةٌ (اختياريّة)', rows: 2 }],
      ok: 'أقفِلها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_session_close', { p_session: s.session, p_note: v.n }, 'إقفال الحصّة');
        if (error) return error;
        flash('ok', (data && data.msg) || ''); loadSessions(); return null;
      },
    });
  }

  // ---------- ① ما ينتظرني أنا ----------
  async function loadSteps() {
    const { data, error } = await M.rpc('v2_card_my_steps', { p_school: M.state.school }, 'ما ينتظرني');
    const box = $('steps');
    if (error) { $('stepsSum').textContent = ''; err(box, error); return; }
    const d = data || {};
    $('stepsSum').textContent = d.summary_ar || '';
    box.textContent = '';
    for (const x of arr(d)) {
      const f = el('div', 'rs-file' + (x.late ? ' rs-late' : ''));
      f.append(el('h5', null, (x.student_ar || '') + ' — ' + (x.title_ar || '')), el('p', 'rs-meta', [x.state_ar, x.opened_on].filter(Boolean).join(' · ')));
      const r = el('div', 'rs-row'); r.appendChild(btn('أنجزتُها', 'rs-btn', () => stepForm(x))); f.appendChild(r);
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize($('steps').parentNode);
  }
  function stepForm(x, after) {
    V.form({
      title: 'إنجازُ خطوة', what: (x.student_ar ? x.student_ar + ' — ' : '') + (x.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ما فعلتَ', rows: 3 }],
      ok: 'أنجزتُها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_step_do', { p_step: x.step, p_note: v.n }, 'إنجاز خطوة');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg)) || ''); loadSteps(); if (after) after(); return null;
      },
    });
  }

  // ---------- ① من خرج الآن ----------
  async function loadExitsNow() {
    const { data, error } = await M.rpc('v2_exit_now', { p_school: M.state.school }, 'من خرج الآن');
    const box = $('exitsNow');
    if (error) { err(box, error); return; }
    box.textContent = '';
    const rows = arr(data);
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', 'لا طالبَ خارجَ فصله الآن.')); return; }
    for (const x of rows) {
      const f = el('div', 'rs-file' + (x.long ? ' rs-late' : ''));
      f.append(el('h5', null, (x.student_ar || '') + ' · ' + (x.section_ar || '')), el('p', 'rs-meta', [x.to_ar, x.minutes_ar, x.by_ar].filter(Boolean).join(' · ')));
      if (x.long_ar) f.appendChild(el('p', 'rs-need', x.long_ar));
      if (x.note_ar) f.appendChild(el('p', 'rs-meta', x.note_ar));
      const r = el('div', 'rs-row'); r.appendChild(btn('عاد', 'rs-btn', () => act('v2_exit_back', { p_exit: x.exit, p_note: null }, 'عودة الطالب', loadExitsNow))); f.appendChild(r);
      box.appendChild(f);
    }
    arabize(box);
  }

  // ---------- ② شبكةُ الفصل ----------
  async function loadGrid() {
    const s = ui.sec;
    $('gridTitle').textContent = (s.label || '') + ' · ' + (s.subject || '');
    const [loy, roles, outs, work] = await Promise.all([
      M.rpc('v2_loyalty_of_section', { p_section: s.id }, 'أرصدة الفصل'),
      M.rpc('v2_roles_of_section', { p_section: s.id, p_subject: s.subject }, 'قادة الصفّ'),
      M.rpc('v2_exit_now', { p_school: M.state.school }, 'من خرج الآن'),
      M.rpc('v2_work_board', { p_section: s.id, p_subject: s.subject }, 'لوحة أعمال الفصل'),
    ]);
    const g = $('grid');
    g.textContent = '';
    $('gridNote').textContent = (loy.data && loy.data.note_ar) || '';
    if (loy.error) { err(g, loy.error); } else {
      const rl = arr(roles.data); const ex = arr(outs.data);
      // بالترتيب الذي جاء به الباب — لا ترتيبَ من الشاشة
      for (const x of arr(loy.data)) {
        const t = btn('', 'hs-tile', () => openCard({ id: x.student_id, name: x.name }));
        t.appendChild(el('b', null, x.name || ''));
        if (x.balance_ar) t.appendChild(el('small', null, x.balance_ar));
        for (const r of rl.filter((y) => y.student === x.student_id)) t.appendChild(el('span', 'rs-tag', r.role_ar || ''));
        const o = ex.find((y) => y.student === x.student_id);
        if (o) t.appendChild(el('span', 'rs-tag own', 'خارج الفصل — ' + (o.to_ar || '')));
        g.appendChild(t);
      }
      if (!arr(loy.data).length) g.appendChild(el('p', 'rs-meta', 'لا طالبَ في هذا الفصل.'));
    }
    if (roles.error) g.appendChild(el('div', 'notice err', errText(roles.error)));
    renderWork($('workBoard'), work, true);
    arabize($('gridCard'));
  }
  function renderWork(box, r, board) {
    box.textContent = '';
    if (r.error) { err(box, r.error); return; }
    const rows = arr(r.data);
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', board ? 'لا عملَ قائمٌ في هذا الفصل.' : 'لا عملَ عليه.')); return; }
    for (const w of rows) {
      const f = el('div', 'rs-file');
      const h = el('h5', null, [w.kind_ar, w.subject, w.student_ar].filter(Boolean).join(' · '));
      if (w.voided) h.style.textDecoration = 'line-through';
      f.append(h, el('p', null, w.body || ''), el('p', 'rs-meta', [w.page, w.due_ar, w.scope_ar, w.by_ar, w.late ? 'متأخّر' : null].filter(Boolean).join(' · ')));
      if (w.voided) f.appendChild(el('p', 'rs-meta', 'أُلغي: ' + (w.void_reason || '')));
      else if (w.mine) { const rr = el('div', 'rs-row'); rr.appendChild(btn('ألغِه', 'rs-btn', () => voidWork(w))); f.appendChild(rr); }
      box.appendChild(f);
    }
  }
  function voidWork(w) {
    V.form({
      title: 'إلغاءُ عمل', what: w.body || '',
      fields: [{ key: 'r', type: 'textarea', label: 'السبب', rows: 2 }],
      ok: 'ألغِه', okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_work_void', { p_work: w.id, p_reason: v.r }, 'إلغاء العمل');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg)) || '');
        if (!$('cardView').hidden) reloadCard(); else loadGrid();
        return null;
      },
    });
  }

  // ---------- ③ بطاقةُ الطالب ----------
  async function openCard(stu) {
    ui.stu = stu; ui.tab = null;
    show(3);
    await reloadCard();
  }
  async function reloadCard() {
    const { data, error } = await M.rpc('v2_card_open', { p_student: ui.stu.id, p_date: M.state.date || null }, 'بطاقة الطالب');
    const head = $('cardHead');
    $('cardName').textContent = ui.stu.name || '';
    $('cardSub').textContent = '';
    if (error) { err(head, error); $('tabs').textContent = ''; $('tabBody').textContent = ''; $('loyalty').textContent = ''; return; }
    const c = ui.card = data || {};
    if (c.student && c.student.name_ar) $('cardName').textContent = c.student.name_ar;
    // الصفُّ باسمه من الباب (class_ar) — فتعمل البطاقةُ من أيّ مدخل
    $('cardSub').textContent = (c.student && c.student.class_ar) || '';
    head.textContent = '';
    // نافذةُ الكتابة وسببُ المنع كما جاءا
    if (c.note_ar) head.appendChild(el('div', 'rs-info', c.note_ar));
    else if (c.can_write && c.window) head.appendChild(el('p', 'rs-meta', 'نافذةُ الكتابة مفتوحة' + (c.window.closes ? ' حتى ' + c.window.closes : '') + (c.window.subject_ar ? ' · ' + c.window.subject_ar : '')));
    const gl = c.glance || {};
    // اللمحةُ جملٌ مصوغةٌ من الباب تُقرأ متّصلةً بترتيبها — ولا عددَ يُصاغ في الشاشة
    head.appendChild(el('p', 'rs-meta', [gl.window_ar, gl.absent_ar, gl.late_ar, gl.absent_periods_ar, gl.exits_ar].filter(Boolean).join(' ')));
    // يمرّون بلا أن يُروا — silent_ar كما جاء، ولا عدَّ في الشاشة
    if (gl.silent_ar) {
      head.appendChild(el('div', 'rs-need', gl.silent_ar));
      head.appendChild(el('p', 'rs-meta', 'يمرّون بلا أن يُروا — فالظلمُ أن تُرصد عليه وأن لا تراه أصلًا'));
    }
    const mine = arr(c.my_steps_here);
    if (mine.length) {
      head.appendChild(el('div', 'rs-label', 'ما ينتظرك في هذا الطالب'));
      for (const x of mine) {
        const p = el('p', x.late ? 'rs-need' : null, [x.title_ar, x.due_ar, x.late_ar].filter(Boolean).join(' · '));
        p.appendChild(btn('أنجزتُها', 'rs-btn', () => stepForm(Object.assign({ student_ar: ui.stu.name }, x), reloadCard)));
        head.appendChild(p);
      }
    }
    renderTabs();
    renderLoyalty();
    arabize($('cardView'));
  }
  // التبويباتُ العشرةُ بترتيبها في صفّين — والمغلقُ يُعرض مغلقًا بسببه
  function renderTabs() {
    const box = $('tabs'); box.textContent = '';
    const tabs = arr(ui.card.tabs);
    if (!ui.tab || !tabs.find((t) => t.key === ui.tab)) ui.tab = (tabs.find((t) => t.open) || tabs[0] || {}).key;
    for (const t of tabs) {
      const b = btn((t.open ? '' : '🔒 ') + (t.label_ar || ''), 'hs-tab' + (t.key === ui.tab ? ' on' : '') + (t.open ? '' : ' shut'), () => { ui.tab = t.key; renderTabs(); });
      b.setAttribute('role', 'tab'); b.setAttribute('aria-selected', String(t.key === ui.tab));
      box.appendChild(b);
    }
    renderTab(tabs.find((t) => t.key === ui.tab));
  }
  function renderTab(t) {
    const box = $('tabBody'); box.textContent = '';
    if (ui.healthT) { clearTimeout(ui.healthT); ui.healthT = null; }
    if (!t) return;
    if (!t.open) { box.appendChild(el('div', 'rs-info', t.why_ar || '')); arabize(box); return; }
    const R = { laiha: tabLaiha, record: tabRecord, med: tabHealth, hw: tabWork, fix: tabFix, prac: (b) => tabPractices(b, false), pos: (b) => tabPractices(b, true), role: tabRole, exit: tabExit, scatter: tabThreshold };
    (R[t.key] || (() => {}))(box);
    arabize(box);
  }
  const studentArgs = () => ({ p_student: ui.stu.id });
  const secOf = () => (ui.sec ? { id: ui.sec.id, subject: ui.sec.subject } : { id: (ui.card.window || {}).section_id || null, subject: (ui.card.window || {}).subject_ar || null });
  const periodOf = () => ((ui.card.window || {}).period_no != null ? ui.card.window.period_no : null);

  // اللائحة: البطاقةُ تُحيل إلى محرّك الدليل ولا تنسخه — القائمةُ من v2_conduct_list والرصدُ بـv2_record_behavior
  function tabLaiha(box) {
    const lf = ui.card.laiha_from || {};
    if (lf.why_ar) box.appendChild(el('p', 'rs-meta', lf.why_ar + (lf.owner_ar ? ' · ' + lf.owner_ar : '')));
    const r = el('div', 'rs-row');
    r.appendChild(btn('ارصد مخالفة', 'rs-btn pri', laihaForm));
    box.appendChild(r);
  }
  async function laihaForm() {
    const { data, error } = await M.rpc('v2_conduct_list', { p_student: ui.stu.id, p_mode: null, p_target: 'general' }, 'قائمة المخالفات');
    if (error) { flash('bad', errText(error)); return; }
    const list = arr(data);
    const n = el('div');
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث في السلوك'; q.autocomplete = 'off';
    const sel = el('select'); sel.id = 'laihaSel';
    const paint = () => {
      const t = q.value.trim(); const keep = sel.value;
      sel.textContent = '';
      const o0 = el('option', null, 'اختر السلوك'); o0.value = ''; sel.appendChild(o0);
      for (const p of list.filter((x) => !t || (x.text || '').includes(t))) { const o = el('option', null, p.text + ' — ' + (p.degree_ar || '')); o.value = String(p.id); sel.appendChild(o); }
      sel.value = keep;
    };
    q.addEventListener('input', paint); paint();
    n.append(el('label', null, 'السلوك'), q, sel);
    V.form({
      title: 'رصدُ مخالفة', what: ui.stu.name || '',
      fields: [{ key: 'pick', type: 'node', node: n }, { key: 'place', label: 'المكان (اختياريّ)' }, { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      ok: 'ارصد',
      onOk: async (v) => {
        const p = list.find((x) => String(x.id) === sel.value);
        const { data: d, error: e } = await M.rpc('v2_record_behavior', { p_student: ui.stu.id, p_problem: p ? p.id : null, p_place: v.place || null, p_note: v.note || null, p_period: p && p.needs_period ? periodOf() : null }, 'رصد مخالفة');
        if (e) return e;
        flash('ok', (d && d.headline) || ''); reloadCard(); return null;
      },
    });
  }
  // سجلّه: ما رُصد اليومَ · أدوارُه · أعمالُه · خروجُه — للقراءة · ومنه «اكتب ملاحظة»
  function tabRecord(box) {
    const c = ui.card;
    box.appendChild(el('div', 'rs-label', 'ما رُصد اليومَ'));
    const today = arr(c.today);
    if (!today.length) box.appendChild(el('p', 'rs-meta', 'لا شيءَ اليومَ.'));
    for (const x of today) box.appendChild(el('p', null, (x.title_ar || '') + ' · ' + [x.period != null ? 'الحصّة ' + x.period : null, x.by_ar].filter(Boolean).join(' · ')));
    box.appendChild(el('div', 'rs-label', 'أدوارُه الآن'));
    const rn = arr(c.roles_now);
    if (!rn.length) box.appendChild(el('p', 'rs-meta', 'لا دورَ له الآن.'));
    for (const x of rn) box.appendChild(el('p', null, [x.role_ar, x.subject, x.until_ar, x.by_ar].filter(Boolean).join(' · ')));
    box.appendChild(el('div', 'rs-label', 'أعمالُه'));
    const wb = el('div'); renderWork(wb, { data: c.work }, false); box.appendChild(wb);
    box.appendChild(el('div', 'rs-label', 'خروجُه'));
    exitsList(box);
    const r = el('div', 'rs-row');
    r.appendChild(btn('اكتب ملاحظة', 'rs-btn', () => V.form({
      title: 'ملاحظة', what: ui.stu.name || '',
      fields: [{ key: 'n', type: 'textarea', label: 'الملاحظة', rows: 3 }],
      ok: 'احفظها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_act', Object.assign(studentArgs(), { p_kind: 'note', p_code: null, p_note: v.n, p_place: null, p_payload: {} }), 'ملاحظة');
        if (error) return error;
        flash('ok', (data && data.summary_ar) || ''); reloadCard(); return null;
      },
    })));
    box.appendChild(r);
  }
  // صحّته: للقراءة وحدها — بإقرار الخصوصيّة، وتُطوى بعد الثواني التي يقولها الباب
  async function tabHealth(box) {
    // health_from يقول إنّ التبويبَ قراءةٌ فقط (write: [])
    const hf = ui.card.health_from || {};
    if (hf.why_ar) box.appendChild(el('p', 'rs-meta', hf.why_ar));
    const { data, error } = await M.rpc('v2_card_health', { p_student: ui.stu.id, p_private_ack: false }, 'صحّته');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    box.appendChild(el('div', 'rs-info', d.gate_ar || ''));
    if (d.warn_ar) box.appendChild(el('p', 'rs-meta', d.warn_ar));
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    const r = el('div', 'rs-row');
    r.appendChild(btn(d.ask_ar || 'أظهِرها', 'rs-btn', async () => {
      const { data: h, error: e } = await M.rpc('v2_card_health', { p_student: ui.stu.id, p_private_ack: true }, 'صحّته');
      box.textContent = '';
      if (e) { box.appendChild(el('div', 'notice err', errText(e))); return; }
      const x = h || {};
      box.append(el('p', 'rs-sum', x.state_ar || ''));
      for (const k of arr(x.cases)) box.appendChild(el('p', null, typeof k === 'string' ? k : (k.text_ar || k.title_ar || '')));
      if (x.note_ar) box.appendChild(el('p', 'rs-meta', x.note_ar));
      if (x.gap_ar) box.appendChild(el('p', 'rs-meta', x.gap_ar));
      arabize(box);
      if (x.seconds) ui.healthT = setTimeout(() => { if (ui.tab === 'med') renderTabs(); }, x.seconds * 1000);
    }));
    box.appendChild(r);
  }
  // كلّفه بواجب: v2_work_set — الأنواعُ والمدى وقواعدُ التسليم من v2_work_kinds لا من الشاشة
  function tabWork(box) {
    const wf = ui.card.work_from || {};
    if (wf.why_ar) box.appendChild(el('p', 'rs-meta', wf.why_ar));
    const wb = el('div'); renderWork(wb, { data: ui.card.work }, false); box.appendChild(wb);
    const r = el('div', 'rs-row');
    r.appendChild(btn('كلّفه بعمل', 'rs-btn pri', async () => {
      const s = secOf();
      const { data: wk, error: we } = await M.rpc('v2_work_kinds', {}, 'أنواع العمل');
      if (we) { flash('bad', errText(we)); return; }
      const k = wk || {}; const ru = k.rules || {};
      const kinds = (k.kinds || []).map((x) => [x.code, x.label_ar]);
      const scopes = (k.scopes || []).map((x) => [x.code, x.label_ar + (x.code === 'student' ? ' — ' + (ui.stu.name || '') : '')]);
      const hint = el('div');
      for (const x of k.kinds || []) if (x.note_ar) hint.appendChild(el('p', 'rs-meta', x.label_ar + ': ' + x.note_ar));
      if (k.rules_ar) hint.appendChild(el('p', 'rs-meta', k.rules_ar));
      V.form({
        title: 'تكليفٌ بعمل', what: [ui.stu.name, s.subject].filter(Boolean).join(' · '),
        fields: [
          { key: 'kind', type: 'pick', label: 'النوع', items: kinds, value: kinds.length ? kinds[0][0] : null },
          { key: 'scope', type: 'pick', label: 'لمن', items: scopes, value: 'student' },
          { key: 'body', type: 'textarea', label: 'نصُّ العمل', rows: 3 },
          { key: 'page', label: 'الصفحة (اختياريّة)' },
          { key: 'due', type: 'date', label: 'موعدُ التسليم' },
          { key: 'hint', type: 'node', node: hint },
        ],
        ok: 'كلّف',
        onOk: async (v) => {
          const { data, error } = await M.rpc('v2_work_set', { p_section: s.id, p_subject: s.subject, p_body: v.body, p_kind: v.kind, p_page: v.page || null, p_due: v.due || null, p_period: periodOf(), p_scope: v.scope, p_student: v.scope === 'student' ? ui.stu.id : null, p_shows: null, p_notify: null }, 'التكليف بعمل');
          if (error) return error;
          flash('ok', (data && (data.note_ar || data.msg || data.summary_ar)) || ''); reloadCard(); return null;
        },
      });
    }));
    box.appendChild(r);
  }
  // تصحيح: ما يقبل التراجعَ بحاله من الباب — وما مُنح لا يُنزَع فلا زرَّ عليه، بل سببُه
  function tabFix(box) {
    const rows = arr(ui.card.correctable);
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', 'لا شيءَ يقبل التصحيح.')); return; }
    for (const x of rows) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, x.title_ar || ''), el('p', 'rs-meta', x.days_ago_ar || ''));
      const st = x.state || {};
      if (st.can_undo) { const r = el('div', 'rs-row'); r.appendChild(btn('تراجع', 'rs-btn', () => undoForm(x))); f.appendChild(r); if (st.law_ar) f.appendChild(el('p', 'rs-meta', st.law_ar)); }
      else f.appendChild(el('p', 'rs-meta', st.why_ar || ''));
      box.appendChild(f);
    }
  }
  function undoForm(x) {
    V.form({
      title: 'تراجعٌ عن رصد', what: x.title_ar || '',
      fields: [{ key: 'r', type: 'textarea', label: 'السبب', rows: 2 }],
      ok: 'تراجع',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_undo', { p_event: x.event, p_reason: v.r }, 'التراجع');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.summary_ar || data.msg)) || ''); reloadCard(); return null;
      },
    });
  }
  // ممارسات (السلبيّة والمحايدة) · إيجابيات — من قائمة الباب بترتيبها، وتُرفع في اللحظة نفسِها
  function tabPractices(box, positive) {
    const all = arr(ui.card.practices).filter((p) => (p.polarity === 'positive') === positive);
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث'; q.autocomplete = 'off';
    const list = el('div', 'rs-list');
    const paint = () => {
      list.textContent = '';
      const t = q.value.trim();
      for (const p of all.filter((x) => !t || (x.title_ar || '').includes(t))) {
        const b = btn('', 'rs-item', () => practiceForm(p));
        b.append(el('b', null, p.title_ar || ''), el('small', null, [p.done_today ? 'رُصدت اليومَ' : null, p.threshold_ar].filter(Boolean).join(' · ')));
        list.appendChild(b);
      }
      arabize(list);
    };
    q.addEventListener('input', paint);
    // الممارساتُ دفترٌ منفصلٌ عن دليل السلوك ومحفظة الولاء — والنصُّ من الباب
    if (ui.card.practices_note_ar) box.appendChild(el('p', 'rs-meta', ui.card.practices_note_ar));
    box.append(q, list);
    paint();
  }
  function practiceForm(p) {
    V.form({
      title: p.polarity === 'positive' ? 'إيجابيّة' : 'ممارسة', what: (ui.stu.name || '') + ' — ' + (p.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      ok: 'سجّلها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_act', Object.assign(studentArgs(), { p_kind: 'practice', p_code: p.code, p_note: v.n || null, p_place: null, p_payload: {} }), 'رصد ممارسة');
        if (error) return error;
        flash('ok', [data && data.summary_ar, data && data.note_ar].filter(Boolean).join(' — ')); reloadCard(); return null;
      },
    });
  }
  // كلّفه بدور: القائمةُ من لوحة التحكّم (class_roles) · وأدوارُه الآن ومنها العزل
  function tabRole(box) {
    const s = secOf();
    box.appendChild(el('div', 'rs-label', 'أدوارُه الآن'));
    const rn = arr(ui.card.roles_now);
    if (!rn.length) box.appendChild(el('p', 'rs-meta', 'لا دورَ له الآن.'));
    for (const x of rn) {
      const p = el('p', null, [x.role_ar, x.subject, x.until_ar].filter(Boolean).join(' · '));
      if (x.mine) p.appendChild(btn('اعزله', 'rs-btn', () => V.form({
        title: 'عزلٌ من دور', what: (ui.stu.name || '') + ' — ' + (x.role_ar || ''),
        fields: [{ key: 'r', type: 'textarea', label: 'السبب', rows: 2 }],
        ok: 'اعزله',
        onOk: async (v) => {
          const { data, error } = await M.rpc('v2_role_end', { p_holder: x.holder, p_reason: v.r }, 'العزل');
          if (error) return error;
          flash('ok', (data && (data.note_ar || data.msg)) || ''); reloadCard(); return null;
        },
      })));
      box.appendChild(p);
    }
    box.appendChild(el('div', 'rs-label', 'أسنِد إليه دورًا'));
    for (const r of arr(ui.card.class_roles).filter((x) => x.active !== false)) {
      const b = btn('', 'rs-item', () => act('v2_role_assign', { p_section: s.id, p_subject: s.subject, p_code: r.code, p_student: ui.stu.id, p_days: null }, 'إسناد دور', reloadCard));
      b.append(el('b', null, r.title_ar || ''), el('small', null, r.note_ar || ''));
      box.appendChild(b);
    }
  }
  // خروجٌ مؤقّت: الأماكنُ من exit_from.places · والعدُّ والحدُّ من الباب
  function exitsList(box) {
    const e = ui.card.exits || {};
    const line = [e.today_ar, e.month_ar].filter(Boolean).join(' ');
    if (line) box.appendChild(el('p', 'rs-meta', line));
    if (e.warn_ar) box.appendChild(el('p', 'rs-need', e.warn_ar));
    if (e.note_ar) box.appendChild(el('p', 'rs-meta', e.note_ar));
    for (const x of arr(e)) {
      const p = el('p', null, [x.on_ar, x.period != null ? 'الحصّة ' + x.period : null, x.to_ar, x.minutes_ar, x.by_ar].filter(Boolean).join(' · '));
      if (!x.returned) p.appendChild(btn('عاد', 'rs-btn', () => act('v2_exit_back', { p_exit: x.exit, p_note: null }, 'عودة الطالب', reloadCard)));
      box.appendChild(p);
    }
  }
  function tabExit(box) {
    const ef = ui.card.exit_from || {};
    exitsList(box);
    const r = el('div', 'rs-row');
    r.appendChild(btn('أخرِجه', 'rs-btn pri', () => V.form({
      title: 'خروجٌ مؤقّت', what: ui.stu.name || '',
      fields: [{ key: 'to', type: 'pick', label: 'إلى', items: arr(ef.places).map((p) => [p.key, p.label_ar]) }, { key: 'n', label: 'ملاحظة (اختياريّة)' }],
      ok: 'أخرِجه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_exit_out', { p_student: ui.stu.id, p_to_where: v.to || null, p_note: v.n || null }, 'الخروج المؤقّت');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg || data.summary_ar)) || ''); reloadCard(); return null;
      },
    })));
    box.appendChild(r);
  }
  // العتبة: الممارساتُ التي لها عتبةٌ بعددها ومدّتها من الباب · وما صار عليك منها
  function tabThreshold(box) {
    const rows = arr(ui.card.practices).filter((p) => p.threshold_count);
    if (!rows.length) box.appendChild(el('p', 'rs-meta', 'لا ممارسةَ لها عتبة.'));
    for (const p of rows) box.appendChild(el('p', null, [p.title_ar, p.threshold_ar].filter(Boolean).join(' · ')));
  }

  // ---------- نقاطُ الولاء ----------
  // ما can_i فيه خطأٌ لا يُعرض زرُّه · والسقفُ الأسبوعيُّ (week_left) يُرى قبل أن يُرفض · والإشارةُ من نوع المصدر
  async function renderLoyalty() {
    const box = $('loyalty'); box.textContent = '';
    const L = ui.card.loyalty || {};
    box.appendChild(el('p', 'rs-sum', L.balance_ar || ''));
    const grant = arr(L.can_grant);
    for (const s of grant) {
      const b = btn('', 'rs-item', () => grantForm(s));
      b.append(el('b', null, (s.kind === 'deduct' ? '− ' : '+ ') + (s.title_ar || '') + ' · ' + s.points), el('small', null, [s.week_left_ar, s.needs_note ? 'بسببٍ مكتوب' : null].filter(Boolean).join(' · ')));
      box.appendChild(b);
    }
    const [cat, wal] = await Promise.all([
      M.rpc('v2_loyalty_catalog', {}, 'فهرس الولاء'),
      M.rpc('v2_loyalty_wallet', { p_student: ui.stu.id }, 'محفظة الطالب'),
    ]);
    if (cat.error) box.appendChild(el('div', 'notice err', errText(cat.error)));
    else {
      const rw = arr((cat.data || {}).rewards).filter((x) => x.can_i === true);
      if (rw.length) box.appendChild(el('div', 'rs-label', 'اصرف له'));
      for (const x of rw) {
        const b = btn('', 'rs-item', () => spendForm(x));
        b.append(el('b', null, (x.title_ar || '') + ' · ' + x.price), el('small', null, [x.stock != null ? 'المتاح ' + x.stock : null, x.note_ar].filter(Boolean).join(' · ')));
        box.appendChild(b);
      }
    }
    if (wal.error) box.appendChild(el('div', 'notice err', errText(wal.error)));
    else {
      const moves = arr((wal.data || {}).moves);
      if (moves.length) box.appendChild(el('div', 'rs-label', 'حركاتُه'));
      for (const m of moves) {
        const p = el('p', null, [m.title_ar, m.points, m.on_ar, m.by_ar, m.reason_ar].filter((v) => v != null && v !== '').join(' · '));
        if (m.can_undo) p.appendChild(btn('اسحبها', 'rs-btn', () => V.form({
          title: 'سحبُ حركة', what: m.title_ar || '',
          fields: [{ key: 'r', type: 'textarea', label: 'السبب', rows: 2 }],
          ok: 'اسحبها',
          onOk: async (v) => {
            const { data, error } = await M.rpc('v2_loyalty_undo', { p_id: m.id, p_reason: v.r }, 'سحب الحركة');
            if (error) return error;
            flash('ok', (data && (data.note_ar || data.msg)) || ''); reloadCard(); return null;
          },
        })));
        box.appendChild(p);
      }
    }
    arabize(box);
  }
  function grantForm(s) {
    V.form({
      title: (s.kind === 'deduct' ? 'خصمُ نقاط' : 'منحُ نقاط'), what: (ui.stu.name || '') + ' — ' + (s.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: s.needs_note ? 'السبب' : 'ملاحظة (اختياريّة)', rows: 2 }],
      ok: s.kind === 'deduct' ? 'اخصم' : 'امنح',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_loyalty_record', { p_student: ui.stu.id, p_source: s.code, p_note: v.n || null, p_period: periodOf() }, 'نقاط الولاء');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg || data.summary_ar)) || ''); reloadCard(); return null;
      },
    });
  }
  function spendForm(x) {
    V.form({
      title: 'صرفُ مكافأة', what: (ui.stu.name || '') + ' — ' + (x.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      ok: 'اصرفها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_loyalty_spend', { p_student: ui.stu.id, p_reward: x.code, p_note: v.n || null }, 'صرف مكافأة');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg || data.summary_ar)) || ''); reloadCard(); return null;
      },
    });
  }

  M.start({ screen: 'hissa', onChange: () => refresh() });
})();
