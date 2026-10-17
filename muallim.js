// مؤيّد · صفحةُ المعلّم (تكليف ⑤) — بيتٌ واحدٌ بستّة أقسامٍ وشريطِ «صفتي»
// الأقسام: صفّي · توزيعُ المنهج · يومي في المدرسة · ما كُلِّفتُ به · ما وصلني · ما يُقاس بي
// والظهورُ بالتكليف لا بالصلاحية: قسمُ التوزيع لمن صفتُه النافذةُ معلّمُ موادّ أو تربيةٍ خاصّة أو موهوبين
// ⓖ قسمُ «درجات المادّة» (تكليف ⑥): موادّي (v2_grade_my_subjects) · الفتح · بطاقةُ التوزيع بخاناتها وبنودها · بطاقةُ الطالب
//    وكشفُ الفصل بحرف الفصل (sections[].section) · وحكمُ النجاح في الحال full وحدَها (state من الباب)
// ① قسمُ «توزيع المنهج»: موادّي (v2_my_plan_subjects) ومن كلّ سطرٍ لوحاتُه — البطاقة · بلا أسبوع · المنهج · الكفاية · المخارج · حدُّ الفصلين
// ② «صفّي» قسمٌ في الصفحة (طبقاتُ hissa.js بعينها في safiHost) · و«يومي» و«ما كُلِّفتُ به» و«ما وصلني» ما زالت في «ما عليّ»
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn } = V;

  const TEACHING = ['subject_teacher', 'sped_teacher', 'gifted_teacher'];
  const ui = { sec: 'mine' };
  const role = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };

  const SECTIONS = [
    ['mine', 'صفّي'], ['plan', 'توزيعُ المنهج'], ['grades', 'درجاتُ المادّة'], ['day', 'يومي في المدرسة'],
    ['tasks', 'ما كُلِّفتُ به'], ['inbox', 'ما وصلني'], ['measured', 'ما يُقاس بي'],
  ];

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    // بالتكليف: قسمُ التوزيع لمن يُدرّس وحدَه
    const list = SECTIONS.filter(([k]) => !['plan', 'grades'].includes(k) || TEACHING.includes(role()));
    if (!list.some(([k]) => k === ui.sec)) ui.sec = list[0][0];
    V.pick($('sections'), list, ui.sec, (v) => { ui.sec = v; render(); });
    render();
  }

  function render() {
    const box = $('sectionBody'); box.textContent = '';
    // «صفّي» قسمٌ في الصفحة: طبقاتُ الحصّة الثلاث (hissa.js) في safiHost — وتُطوى إذا فُتح قسمٌ غيرُه
    const safi = ui.sec === 'mine';
    $('safiHost').hidden = !safi;
    if (safi) { if (window.MoayadSafi) window.MoayadSafi.refresh(); return; }
    ({ plan: secPlan, grades: secGrades, day: secLink('mukallaf.html', 'افتح «ما عليّ»'),
      tasks: secTasks, inbox: secInbox, measured: secMeasured }[ui.sec])(box);
  }
  // الأقسامُ القائمةُ في شاشتَين — تُفتح منهما حتى تُنقل
  const secLink = (href, label) => (box) => {
    const c = el('section', 'rs-card');
    c.appendChild(el('p', 'rs-meta', 'هذا القسمُ قائمٌ اليومَ في شاشةٍ مستقلّة، ويُنقل إلى هذي الصفحة بترتيب العمل.'));
    const r = el('div', 'rs-row'); r.appendChild(btn(label, 'rs-btn', () => { location.href = href; })); c.appendChild(r);
    box.appendChild(c);
  };
  // ما كُلِّفتُ به: «مناوبتي» هنا (البدلُ الذي ينتظر جوابي · طلباتُ المبادلة — munawaba.js) · وبقيّتُه في «ما عليّ»
  function secTasks(box) {
    const c = el('section', 'rs-card');
    c.appendChild(el('h3', null, 'مناوبتي'));
    const b = el('div'); c.appendChild(b);
    box.appendChild(c);
    window.MoayadMunawaba.mineTool(b);
    secLink('mukallaf.html', 'افتح «ما عليّ»')(box);
  }
  // ما وصلني: «شاهدٌ في شكوى» هنا (تكليف ٢١ §③ — shakwa.js: الصندوقُ بلا تفصيل ثمّ تعهّدُ السرّيّة ثمّ القراءةُ والجواب) · وبقيّتُه في «ما عليّ»
  function secInbox(box) {
    const c = el('section', 'rs-card');
    c.appendChild(el('h3', null, 'شاهدٌ في شكوى'));
    const b = el('div'); c.appendChild(b);
    box.appendChild(c);
    window.MoayadShakwa.teacherAsks(b);
    secLink('mukallaf.html', 'افتح «ما عليّ»')(box);
  }
  function secMeasured(box) {
    const c = el('section', 'rs-card');
    c.appendChild(el('p', 'rs-meta', 'لم يُبنَ هذا القسم: ملفُّ الأداء وشواهدُه والأداءُ الوظيفيُّ لا أبوابَ لها بعد.'));
    box.appendChild(c);
  }

  // ---------- توزيعُ المنهج ----------
  // المدخل: v2_my_plan_subjects — سطرٌ لكلّ صفٍّ ومادّة (grade يُرسل · grade_ar يُعرض)، ومن السطر تُفتح لوحاتُه
  // وأبوابُ الكتابة بنسخها الطويلة وحدَها: v2_plan_build/v2_plan_card بـ p_person فارغًا (توزيعُك أنت) · v2_plan_mark بـ p_sections
  // وليس هنا: رأيُ المعلّم (لوحة ٢٢ ناقصة — لا باب) · ولا أبوابُ الإدارة (plans_board · review · review_assign · approve · lock)
  // ولا v2_term_split_set/bulk — فحدُّ الفصلين للمعلّم إقرارٌ أو اعتراضٌ بدليل
  const plan = { term: null, terms: null, subj: null, panel: 'card', card: null };
  const PANELS = [
    ['card', 'بطاقةُ توزيعي'], ['pending', 'بلا أسبوع'], ['curr', 'منهجُ مادّتي'],
    ['cap', 'كفايةُ النصاب'], ['fix', 'مخارجُ النقص'], ['split', 'حدُّ الفصلين'],
  ];
  const line = (box, cls, t) => { if (t) box.appendChild(el('p', cls, t)); };
  const errBox = (box, error) => box.appendChild(el('div', 'notice err', errText(error)));
  const said = (d) => [d.summary_ar, d.note_ar].filter(Boolean).join(' — ');

  async function secPlan(box) {
    if (plan.subj) return subjView(box);
    const c = el('section', 'rs-card');
    c.appendChild(el('h3', null, 'موادّي في التوزيع'));
    const tp = el('div', 'rs-pick'); const sum = el('p', 'rs-sum'); const body = el('div');
    c.append(tp, sum, body);
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_my_plan_subjects', { p_school: M.state.school, p_term: plan.term }, 'موادّي في التوزيع');
    if (error) { errBox(body, error); return; }
    const d = data || {};
    if (plan.term == null) plan.term = d.term;
    // الفصلان باسميهما من الباب: الجاري من هذا النداء، والآخرُ من ندائه
    if (!plan.terms && d.term != null) {
      const other = Number(d.term) === 1 ? 2 : 1;
      const o = await M.rpc('v2_my_plan_subjects', { p_school: M.state.school, p_term: other }, 'اسم الفصل الآخر');
      plan.terms = [[Number(d.term), d.term_ar || '']];
      if (!o.error && o.data && o.data.term_ar) plan.terms.push([other, o.data.term_ar]);
      plan.terms.sort((a, b) => a[0] - b[0]);
    }
    if (plan.terms && plan.terms.length > 1) V.pick(tp, plan.terms, Number(plan.term), (v) => { plan.term = v; render(); });
    sum.textContent = d.summary_ar || '';
    const ul = el('ul', 'rs-acts');
    for (const r of d.rows || []) {
      const li = el('li', 'click');
      li.setAttribute('role', 'button'); li.tabIndex = 0;
      const b = el('span'); b.style.flex = '1';
      b.appendChild(el('b', null, r.said_ar || ''));
      const sub = [r.weekly_ar, r.items_ar, r.done_ar, r.locked_ar].filter(Boolean).join(' · ');
      if (sub) b.appendChild(el('div', 'rs-meta', sub));
      li.append(el('i', 'rs-tick', '›'), b);
      V.tap(li, () => { plan.subj = r; plan.panel = 'card'; plan.card = null; render(); });
      ul.appendChild(li);
    }
    body.appendChild(ul);
    line(body, 'rs-meta', d.note_ar);
    arabize(c);
    await weeksCard(box);
  }

  // أسابيعي في هذا العام (v2_plan_weeks): الأسابيعُ بلا أسابيع الاختبار، وأيّامُ الدراسة بعد خصم الإجازات
  async function weeksCard(box) {
    const c = el('details', 'rs-card rs-dt');
    c.appendChild(el('summary', null, 'أسابيعي في هذا العام'));
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_plan_weeks', { p_school: M.state.school, p_term: null }, 'أسابيع التوزيع');
    if (error) { errBox(c, error); return; }
    const d = data || {};
    line(c, 'rs-sum', d.summary_ar);
    const ul = el('ul', 'rs-acts');
    for (const w of d.weeks || []) {
      const li = el('li', w.is_current ? 'on' : null);
      const b = el('span'); b.style.flex = '1';
      b.appendChild(el('b', null, (w.from_h || '') + ' — ' + (w.to_h || '')));
      const hol = (w.holidays || []).join(' · ');
      if (hol) b.appendChild(el('div', 'rs-meta', hol));
      li.append(el('i', 'rs-tick' + (w.is_current ? ' ok' : ''), w.is_current ? '●' : '○'), b);
      ul.appendChild(li);
    }
    c.appendChild(ul);
    line(c, 'rs-meta', d.note_ar);
    arabize(c);
  }

  // ما يُرسل إلى أبواب الصفّ والمادّة
  const key = () => ({ p_school: M.state.school, p_grade: plan.subj.grade, p_subject: plan.subj.subject_ar });

  function subjView(box) {
    const r = plan.subj;
    const head = el('section', 'rs-card');
    const row = el('div', 'rs-row');
    row.appendChild(btn('‹ موادّي', 'rs-btn ghost', () => { plan.subj = null; plan.card = null; render(); }));
    head.append(row, el('h3', null, r.said_ar || ''));
    const pk = el('div', 'rs-pick');
    head.appendChild(pk);
    const body = el('div');
    box.append(head, body);
    V.pick(pk, PANELS, plan.panel, (v) => { plan.panel = v; body.textContent = ''; panel(body); });
    arabize(head);
    panel(body);
  }
  function panel(body) {
    ({ card: pCard, pending: pPending, curr: pCurr, cap: pCap, fix: pFix, split: pSplit }[plan.panel])(body);
  }

  // البطاقةُ تُقرأ مرّةً وتُشارَك بين «بطاقتي» و«بلا أسبوع» — وتُعاد بعد كلّ كتابة
  async function loadCard() {
    const { data, error } = await M.rpc('v2_plan_card', Object.assign(key(), { p_term: plan.term, p_person: null }), 'بطاقة التوزيع');
    plan.card = error ? null : (data || {});
    return error;
  }
  const again = () => { plan.card = null; render(); };

  // ⑴ «احسب توزيعي» · ⑵ البطاقة بأسابيعها وبنودها · «أعددتُ توزيعي»
  async function pCard(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const acts = el('div', 'rs-row');
    const bBuild = btn('احسب توزيعي', 'rs-btn pri');
    bBuild.addEventListener('click', () => V.send(bBuild, async () => {
      const { data, error } = await M.rpc('v2_plan_build', Object.assign(key(), { p_term: plan.term, p_person: null }), 'احسب توزيعي');
      if (error) { V.flash('bad', errText(error)); return; }
      V.flash('ok', said(data || {}));
      again();
    }));
    acts.appendChild(bBuild);
    c.appendChild(acts);
    const err = plan.card ? null : await loadCard();
    if (err) { errBox(c, err); arabize(c); return; }
    const d = plan.card;
    if (d.plan) {
      const bPrep = btn('أعددتُ توزيعي', 'rs-btn');
      bPrep.addEventListener('click', () => V.send(bPrep, async () => {
        const { data, error } = await M.rpc('v2_plan_prepared', { p_plan: d.plan }, 'أعددتُ توزيعي');
        if (error) { V.flash('bad', errText(error)); return; }
        V.flash('ok', said(data || {}));
        again();
      }));
      acts.appendChild(bPrep);
    }
    line(c, 'rs-sum', d.summary_ar);
    line(c, 'rs-meta', [d.status_ar, d.lock_ar, d.lock_why, d.build_no_ar].filter(Boolean).join(' · '));
    line(c, 'rs-meta', d.scope_ar);
    const ca = d.counts_ar || {};
    const cl = ['items', 'done', 'deferred', 'lost', 'unplaced'].map((k) => ca[k]).filter(Boolean);
    if (cl.length) line(c, 'rs-meta', cl.join(' · '));
    line(c, 'rs-meta', d.note_ar);
    for (const w of d.weeks || []) {
      const det = el('details', 'rs-dt');
      if (w.is_current) det.open = true;
      det.appendChild(el('summary', null, [w.week_ar, w.on_ar, w.state_ar].filter(Boolean).join(' · ') + (w.is_current ? ' ●' : '')));
      const ul = el('ul', 'rs-acts');
      for (const it of w.items || []) ul.appendChild(itemLine(it));
      if ((w.items || []).length) det.appendChild(ul);
      c.appendChild(det);
    }
    arabize(c);
  }
  function itemLine(it) {
    const li = el('li', 'click');
    li.setAttribute('role', 'button'); li.tabIndex = 0;
    const b = el('span'); b.style.flex = '1';
    b.appendChild(el('b', null, it.title_ar || ''));
    b.appendChild(el('div', 'rs-meta', [it.kind_ar, it.periods_ar, it.state_ar, it.done_sections_ar, it.pages_ar, it.unit_ar].filter(Boolean).join(' · ')));
    if (it.why || it.move_why) b.appendChild(V.line('div', 'rs-meta', [it.why ? V.typed(it.why) : null, it.move_why ? V.typed(it.move_why) : null], ' — '));
    li.append(el('i', 'rs-tick' + (it.state === 'done' ? ' ok' : ''), it.state === 'done' ? '✓' : '○'), b);
    V.tap(li, () => itemSheet(it));
    return li;
  }

  // «بلا أسبوع»: ما لم يجد أسبوعًا يُقيَّد هنا — ومنه يُنقل إلى أسبوعٍ أو يُدمج، ومدخلُه «مخارجُ النقص»
  async function pPending(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const err = plan.card ? null : await loadCard();
    if (err) { errBox(c, err); arabize(c); return; }
    const d = plan.card;
    c.appendChild(el('h3', null, 'بلا أسبوع'));
    line(c, 'rs-sum', (d.counts_ar || {}).unplaced);
    const ul = el('ul', 'rs-acts');
    for (const p of d.pending || []) {
      const li = el('li', 'click');
      li.setAttribute('role', 'button'); li.tabIndex = 0;
      const b = el('span'); b.style.flex = '1';
      b.append(el('b', null, p.title_ar || ''), el('div', 'rs-meta', p.periods_ar || ''));
      li.append(el('i', 'rs-tick', '○'), b);
      V.tap(li, () => itemSheet(Object.assign({ pending: true }, p), 'move'));
      ul.appendChild(li);
    }
    if ((d.pending || []).length) c.appendChild(ul);
    const r = el('div', 'rs-row');
    r.appendChild(btn('مخارجُ النقص', 'rs-btn', () => { plan.panel = 'fix'; render(); }));
    c.appendChild(r);
    arabize(c);
  }

  // لوحُ البند: حالُه في فصوله (plan_mark الطويل بـ p_sections) · نقلُه · حصصُه · وسمُه · دمجُه وفكُّه
  // والأحوالُ والأنواعُ بألفاظها كاملةً من v2_plan_vocab — ولو لم تقع بعدُ في الخطّة
  let vocab = null;
  async function itemSheet(it, first) {
    if (!vocab) {
      const { data, error } = await M.rpc('v2_plan_vocab', {}, 'ألفاظ التوزيع');
      if (error) { V.flash('bad', errText(error)); return; }
      vocab = data || {};
    }
    const d = plan.card || {};
    const all = [];
    for (const w of d.weeks || []) for (const x of w.items || []) all.push(x);
    const byOrd = (a, b) => (a.ord || 0) - (b.ord || 0);
    const states = (vocab.states || []).slice().sort(byOrd).map((x) => [x.key, x.label_ar || '']);
    const kinds = (vocab.kinds || []).slice().sort(byOrd).map((x) => [x.key, x.label_ar || '']);
    const weeks = (d.weeks || []).filter((w) => !w.is_exam).map((w) => [w.week_no, w.week_ar || '', w.on_ar || '']);
    const others = all.filter((x) => x.lesson !== it.lesson).map((x) => [x.lesson, x.title_ar || '', [x.kind_ar, x.periods_ar].filter(Boolean).join(' · ')]);
    const acts = it.pending ? [['move', 'نقلُه إلى أسبوع'], ['merge', 'دمجُه']]
      : [['mark', 'حالُه'], ['move', 'نقلُه'], ['periods', 'حصصُه'], ['kind', 'وسمُه'], ['merge', 'دمجُه'], ['unmerge', 'فكُّ دمجه']];
    // فصولُ البند: مربّعاتٌ بأسمائها — وتركُها فارغةً يسِم فصولَك كلَّها (كما يقول الباب)
    const secBox = el('div');
    secBox.appendChild(el('div', 'rs-label', 'في أيّ فصولك'));
    const per = new Map((it.by_section || []).map((s) => [s.section, s]));
    const checks = [];
    for (const s of d.sections || []) {
      const lab = el('label', 'rs-chk');
      const cb = el('input'); cb.type = 'checkbox'; cb.value = s.section;
      const st = per.get(s.section);
      lab.append(cb, document.createTextNode(' ' + (s.label_ar || '') + (st ? ' — ' + [st.state_ar, st.on_ar].filter(Boolean).join(' · ') : '')));
      if (st && st.why) lab.append(document.createTextNode(' · '), V.typed(st.why));
      secBox.appendChild(lab); checks.push(cb);
    }
    const isA = (k) => (v) => v.act === k;
    V.form({
      title: it.title_ar || '',
      what: [it.kind_ar, it.periods_ar, it.state_ar, it.done_sections_ar].filter(Boolean).join(' · '),
      ok: 'سجّل',
      fields: [
        { key: 'act', type: 'pick', label: 'ما تفعل', items: acts, value: first || acts[0][0] },
        { key: 'state', type: 'pick', label: 'حالُه', items: states, value: it.state, show: isA('mark') },
        { key: 'secs', type: 'node', node: secBox, show: isA('mark') },
        { key: 'used', type: 'number', label: 'الحصصُ التي استُعملت (إن شئت)', show: isA('mark') },
        { key: 'week', type: 'choose', label: 'إلى أيّ أسبوع', items: weeks, show: isA('move') },
        { key: 'periods', type: 'number', label: 'عددُ حصصه', show: isA('periods') },
        { key: 'kind', type: 'pick', label: 'وسمُه في خطّتك', items: kinds, value: it.kind, show: isA('kind') },
        { key: 'into', type: 'choose', label: 'يُدمج في', items: others, show: isA('merge') },
        { key: 'why', type: 'textarea', label: 'السبب', show: (v) => v.act !== 'kind' },
      ],
      onOk: async (v) => {
        const p = d.plan; const l = it.lesson; let r;
        if (v.act === 'mark') {
          const secs = checks.filter((x) => x.checked).map((x) => x.value);
          r = await M.rpc('v2_plan_mark', { p_plan: p, p_lesson: l, p_state: v.state, p_why: v.why, p_periods_used: v.used, p_sections: secs.length ? secs : null }, 'حال البند');
        } else if (v.act === 'move') r = await M.rpc('v2_plan_move', { p_plan: p, p_lesson: l, p_week: v.week, p_why: v.why }, 'نقل البند');
        else if (v.act === 'periods') r = await M.rpc('v2_plan_periods', { p_plan: p, p_lesson: l, p_periods: v.periods, p_why: v.why }, 'حصص البند');
        else if (v.act === 'kind') r = await M.rpc('v2_plan_kind', { p_plan: p, p_lesson: l, p_kind: v.kind }, 'وسم البند');
        else if (v.act === 'merge') r = await M.rpc('v2_plan_merge', { p_plan: p, p_lesson: l, p_into: v.into, p_why: v.why }, 'دمج البند');
        else r = await M.rpc('v2_plan_unmerge', { p_plan: p, p_lesson: l, p_why: v.why }, 'فكّ الدمج');
        if (r.error) return r.error;
        V.flash('ok', said(r.data || {}));
        again();
        return null;
      },
    });
  }

  // منهجُ المادّة كما في الكتاب: الوحداتُ بلفظها (unit_no_ar · said_ar) ودروسُها (no_ar · periods_ar)
  async function pCurr(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_curriculum_of', { p_grade: plan.subj.grade, p_subject: plan.subj.subject_ar }, 'منهج مادّتي');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    line(c, 'rs-sum', [d.summary_ar, d.periods_total_ar].filter(Boolean).join(' · '));
    for (const u of d.rows || []) {
      const det = el('details', 'rs-dt');
      det.appendChild(el('summary', null, u.said_ar || [u.unit_no_ar, u.unit_title_ar || u.unit_ar, u.periods_ar].filter(Boolean).join(' · ')));
      if (u.term_ar) det.appendChild(el('p', 'rs-meta', u.term_ar));
      const ul = el('ul', 'rs-acts');
      for (const x of u.lessons || []) ul.appendChild(el('li', null, [x.no_ar, x.title, x.periods_ar].filter(Boolean).join(' · ')));
      det.appendChild(ul);
      if (u.source_doc) det.appendChild(el('p', 'rs-meta', u.source_doc));
      c.appendChild(det);
    }
    line(c, 'rs-meta', d.note_ar);
    arabize(c);
  }

  // كفايةُ النصاب — لمادّاتك أنت (mine_only) وعلى السنة كلِّها
  async function pCap(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_plan_capacity', { p_school: M.state.school, p_grade: plan.subj.grade }, 'كفاية النصاب');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    line(c, 'rs-meta', d.scope_ar);
    const ul = el('ul', 'rs-acts');
    for (const r of d.rows || []) {
      const li = el('li');
      const b = el('span'); b.style.flex = '1';
      b.appendChild(el('b', null, r.said_ar || ''));
      if (r.verdict_ar) b.appendChild(el('div', 'rs-meta', r.verdict_ar));
      li.appendChild(b); ul.appendChild(li);
    }
    c.appendChild(ul);
    line(c, 'rs-meta', d.note_ar);
    arabize(c);
  }

  // مخارجُ النقص: الحاجةُ والسعةُ من الحساب نفسِه · واقتراحاتُ الدمج · وحصصُ الانتظار الفارغة · وما يُرفع لإدارة التعليم
  async function pFix(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const id = (plan.card && plan.card.plan) || plan.subj.plan_id;
    if (!id) { line(c, 'rs-meta', plan.subj.status_ar); arabize(c); return; }
    const { data, error } = await M.rpc('v2_plan_fix', { p_plan: id }, 'مخارج النقص');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    line(c, 'rs-sum', d.summary_ar);
    line(c, 'rs-meta', [d.periods_need_ar, d.capacity_ar, d.short_ar, d.unplaced_ar, d.merged_now_ar].filter(Boolean).join(' · '));
    const ms = d.merge_suggestions || [];
    if (ms.length) {
      c.appendChild(el('h4', null, 'دمجٌ يُقترح'));
      const ul = el('ul', 'rs-acts');
      for (const m of ms) ul.appendChild(el('li', null, m.said_ar || m.summary_ar || m.text_ar || ''));
      c.appendChild(ul);
    }
    const fs = d.free_slots || [];
    if (fs.length) {
      c.appendChild(el('h4', null, 'حصصُ انتظارك الفارغة'));
      const ul = el('ul', 'rs-acts');
      for (const f of fs) ul.appendChild(el('li', null, [f.weekday_ar, f.period_ar].filter(Boolean).join(' · ')));
      c.appendChild(ul);
    }
    line(c, 'rs-meta', d.escalate_ar);
    line(c, 'rs-meta', d.note_ar);
    arabize(c);
  }

  // حدُّ الفصلين: الاقتراحُ لا يتجاوز السعة · والوحداتُ موسومةٌ بما يسع · وللمعلّم إقرارٌ أو اعتراضٌ بدليل
  async function pSplit(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_term_split_suggest', key(), 'حدّ الفصلين');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    line(c, 'rs-sum', d.summary_ar);
    line(c, 'rs-meta', [d.already_set_ar, d.cap_t1_ar && ('سعةُ الأوّل ' + d.cap_t1_ar), d.cap_t2_ar && ('سعةُ الثاني ' + d.cap_t2_ar)].filter(Boolean).join(' · '));
    line(c, 'rs-meta', d.note_ar);
    const ul = el('ul', 'rs-acts');
    for (const u of d.units || []) {
      const li = el('li');
      li.append(el('i', 'rs-tick' + (u.fits ? ' ok' : ''), u.fits ? '✓' : '○'), el('span', null, u.said_ar || ''));
      ul.appendChild(li);
    }
    c.appendChild(ul);
    const units = (d.units || []).map((u) => [u.unit_no, u.unit_ar || '', u.title_ar || '']);
    const r = el('div', 'rs-row');
    r.appendChild(btn('أُقرّ حدًّا', 'rs-btn', () => V.form({
      title: 'أُقرّ حدَّ الفصلين', what: d.summary_ar, ok: 'أُقرّ',
      fields: [
        { key: 'unit', type: 'choose', label: 'ينتهي الفصلُ الأوّلُ بـ', items: units, value: d.suggest_until_unit },
        { key: 'note', type: 'textarea', label: 'ملاحظة' },
      ],
      onOk: async (v) => {
        const x = await M.rpc('v2_term_split_confirm', Object.assign(key(), { p_until_unit: v.unit, p_note: v.note }), 'إقرار حدّ الفصلين');
        if (x.error) return x.error;
        V.flash('ok', said(x.data || {})); render(); return null;
      },
    })));
    r.appendChild(btn('أعترض بدليل', 'rs-btn ghost', () => V.form({
      title: 'اعتراضٌ على حدّ الفصلين', what: d.already_set_ar, ok: 'ارفع الاعتراض',
      fields: [
        { key: 'unit', type: 'choose', label: 'الحدُّ الذي تراه', items: units },
        { key: 'evidence', type: 'textarea', label: 'الدليل' },
      ],
      onOk: async (v) => {
        const x = await M.rpc('v2_term_split_object', Object.assign(key(), { p_evidence: v.evidence, p_claim_unit: v.unit }), 'اعتراض حدّ الفصلين');
        if (x.error) return x.error;
        V.flash('ok', said(x.data || {})); return null;
      },
    })));
    c.appendChild(r);
    arabize(c);
  }

  // ---------- درجاتُ المادّة ----------
  // الأبواب: v2_grade_my_subjects · v2_grade_plan_open · v2_grade_plan_card (بخمسة وسائط و p_person فارغًا) · v2_grade_item_add/set/drop
  //          v2_grade_student · وأدواتُ التقويم من v2_reference('assess_tools') — يُرسل key ويُعرض label_ar، مجموعتين بـ kind
  // ولا حسابَ في الشاشة: المجاميعُ والسقوفُ وألفاظُها من الباب · والخانةُ التي سقفُها صفرٌ لا تُعرض
  // وكشفُ الفصل (v2_grade_sheet) بحرف الفصل من v2_my_plan_subjects (sections[].section) — ولا يُقتطع من اسم الفصل
  const gr = { term: null, terms: null, subj: null, panel: 'card', card: null, tools: null, stuSec: null };
  const GPANELS = [['card', 'بطاقةُ التوزيع'], ['student', 'بطاقةُ طالب'], ['sheet', 'كشفُ الفصل'], ['prac', 'ممارساتُ مادّتي']];
  const MM = () => window.MoayadMumarasa;
  // رقمُ خطّة المادّة من بطاقة التوزيع — وبنودُ الممارسات فيها (تكليف ⑳)
  const gPlan = async () => { if (!gr.card) await loadGCard(); return (gr.card && gr.card.plan && gr.card.plan.id) || null; };
  const gkey = () => ({ p_grade: gr.subj.grade, p_subject: gr.subj.subject_ar, p_school: M.state.school, p_term: gr.term });

  async function secGrades(box) {
    if (gr.subj) return gradeView(box);
    const c = el('section', 'rs-card');
    c.appendChild(el('h3', null, 'موادّي في الدرجات'));
    const tp = el('div', 'rs-pick'); const sum = el('p', 'rs-sum'); const body = el('div');
    c.append(tp, sum, body);
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_grade_my_subjects', { p_school: M.state.school, p_term: gr.term }, 'موادّي في الدرجات');
    if (error) { errBox(body, error); arabize(c); return; }
    const d = data || {};
    if (gr.term == null) gr.term = d.term_no;
    // الفصلان الدراسيّان باسميهما من الباب (والفتراتُ داخلَهما)
    if (!gr.terms && d.term_no != null) {
      const other = Number(d.term_no) === 1 ? 2 : 1;
      const o = await M.rpc('v2_grade_my_subjects', { p_school: M.state.school, p_term: other }, 'اسم الفصل الآخر');
      gr.terms = [[Number(d.term_no), d.term_ar || '']];
      if (!o.error && o.data && o.data.term_ar) gr.terms.push([other, o.data.term_ar]);
      gr.terms.sort((a, b) => a[0] - b[0]);
    }
    if (gr.terms && gr.terms.length > 1) V.pick(tp, gr.terms, Number(gr.term), (v) => { gr.term = v; render(); });
    sum.textContent = d.summary_ar || '';
    line(sum.parentNode, 'rs-meta', d.note_ar);
    const ul = el('ul', 'rs-acts');
    for (const r of d.rows || []) {
      const li = el('li', r.opened ? 'click' : null);
      const b = el('span'); b.style.flex = '1';
      b.appendChild(el('b', null, r.said_ar || ''));
      if (r.kind_ar) b.appendChild(el('div', 'rs-meta', r.kind_ar));
      li.append(el('i', 'rs-tick' + (r.opened ? ' ok' : ''), r.opened ? '›' : '○'), b);
      if (r.opened) {
        li.setAttribute('role', 'button'); li.tabIndex = 0;
        V.tap(li, () => { gr.subj = r; gr.panel = 'card'; gr.card = null; render(); });
      } else if (d.periods_set !== false) {
        // سطرٌ لم يُفتح ⇐ زرٌّ واحد — ولا يُعرض إن لم تُضبط فتراتُ الفصل (summary_ar يقولها)
        const ob = btn('افتح الدرجات', 'rs-btn');
        ob.addEventListener('click', () => V.send(ob, async () => {
          const x = await M.rpc('v2_grade_plan_open', { p_grade: r.grade, p_subject: r.subject_ar, p_school: M.state.school, p_term: gr.term }, 'افتح الدرجات');
          if (x.error) { V.flash('bad', errText(x.error)); return; }
          V.flash('ok', (x.data && x.data.said_ar) || '');
          render();
        }));
        const w = el('span', 'rs-ibs'); w.appendChild(ob); li.appendChild(w);
      }
      ul.appendChild(li);
    }
    body.appendChild(ul);
    arabize(c);
  }

  function gradeView(box) {
    const head = el('section', 'rs-card');
    const row = el('div', 'rs-row');
    row.appendChild(btn('‹ موادّي', 'rs-btn ghost', () => { gr.subj = null; gr.card = null; render(); }));
    head.append(row, el('h3', null, gr.subj.said_ar || ''));
    const pk = el('div', 'rs-pick');
    head.appendChild(pk);
    const body = el('div');
    box.append(head, body);
    V.pick(pk, GPANELS, gr.panel, (v) => { gr.panel = v; body.textContent = ''; gpanel(body); });
    arabize(head);
    gpanel(body);
  }
  function gpanel(body) { ({ card: gCard, student: gStudent, sheet: gSheet, prac: gPrac }[gr.panel])(body); }
  // ممارساتُ مادّتي: القائمةُ والقيمةُ والمصبُّ وبنودُ الممارسات — mumarasa.js
  async function gPrac(body) { MM().panel(body, await gPlan()); }

  async function loadGCard() {
    const { data, error } = await M.rpc('v2_grade_plan_card', Object.assign(gkey(), { p_person: null }), 'بطاقة توزيع الدرجات');
    gr.card = error ? null : (data || {});
    return error;
  }
  const gagain = () => { gr.card = null; render(); };

  // بطاقةُ التوزيع (تكليف ⑦): المئةُ للفصل الدراسيّ — الخاناتُ بسقوفها في الأعلى بأشرطة امتلاء
  // ثمّ الفترتان (periods[]) تبويبين ببنودهما · ثمّ «للفصل الدراسيّ» (term_items: القبليُّ والنهائيُّ المقفل) · ثمّ المجموع
  // ونافذةُ التعديل (edit_window) تُقال بنصّها والأزرارُ باقيةٌ — يردّها الحارسُ بنصّه · ولا رقمَ يُجمع في الشاشة
  async function gCard(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const err = gr.card ? null : await loadGCard();
    if (err) { errBox(c, err); arabize(c); return; }
    const d = gr.card; const pl = d.plan || {};
    if (!pl.id) { line(c, 'rs-sum', d.said_ar); arabize(c); return; }
    line(c, 'rs-meta', [pl.grade_ar, pl.term_ar, pl.status_ar, pl.locked_ar].filter(Boolean).join(' · '));
    const ew = d.edit_window || {};
    if (ew.open === false && ew.said_ar) c.appendChild(el('div', 'rs-info', ew.said_ar));
    const ro = !!pl.locked; // بعد الإقفال: التوزيعُ للقراءة · والرصدُ يبقى مفتوحًا
    gr.pitems = await MM().practiceItems(pl.id, true);
    const counted = (d.buckets || []).filter((b) => b.counts !== false && b.cap !== 0);
    for (const b of counted) {
      const bx = el('div', 'gr-bucket');
      const h = el('div', 'gr-bhead');
      h.appendChild(el('b', null, b.label_ar || ''));
      bx.appendChild(h);
      if (b.cap != null && Number(b.cap) > 0) {
        const bar = el('div', 'gr-bar' + (b.fits === false ? ' over' : ''));
        const f = el('i'); f.style.width = Math.min(100, (Number(b.sum) / Number(b.cap)) * 100) + '%';
        bar.appendChild(f); bx.appendChild(bar);
      }
      line(bx, 'rs-meta', b.said_ar);
      // البندُ الجديدُ يُنسب للفترة الجارية آليًّا — والنهائيُّ لا يُضاف إليه (بندُه مقفل)
      if (!ro && b.key !== 'final') { const r = el('div', 'rs-row'); r.appendChild(btn('أضف بندًا', 'rs-btn ghost', () => itemForm(b, null))); bx.appendChild(r); }
      c.appendChild(bx);
    }
    const pers = d.periods || [];
    if (pers.length) {
      if (gr.per == null || !pers.some((x) => x.period_no === gr.per)) gr.per = d.now_period != null && pers.some((x) => x.period_no === d.now_period) ? d.now_period : pers[0].period_no;
      const pk = el('div', 'rs-pick'); const pb = el('div');
      c.append(pk, pb);
      const drawPer = () => {
        pb.textContent = '';
        const x = pers.find((y) => y.period_no === gr.per) || {};
        line(pb, 'rs-meta', [x.from_week_ar && x.to_week_ar ? x.from_week_ar + ' ← ' + x.to_week_ar : null, x.sum_ar, x.said_ar].filter(Boolean).join(' · '));
        pb.appendChild(itemList(x.items || [], ro, pers));
        arabize(pb);
      };
      V.pick(pk, pers.map((x) => [x.period_no, x.period_ar || '']), gr.per, (v) => { gr.per = v; drawPer(); });
      drawPer();
    }
    const ti = d.term_items || [];
    if (ti.length) {
      const tb = el('div', 'gr-bucket pre');
      tb.appendChild(el('div', 'gr-bhead', 'للفصل الدراسيّ'));
      tb.appendChild(itemList(ti, ro, []));
      c.appendChild(tb);
    }
    line(c, 'rs-sum', d.said_ar);
    line(c, 'rs-meta', d.note_ar);
    arabize(c);
  }
  // بنودٌ بأزرارها: القبليُّ وسمُه «لا يُحتسب» · والمقفلُ 🔒 بلا أزرار · والحضورُ «يُحسب آليًّا»
  function itemList(items, ro, pers) {
    const ul = el('ul', 'rs-acts');
    for (const it of items) {
      const li = el('li');
      const sp = el('span'); sp.style.flex = '1';
      sp.appendChild(el('b', null, (it.locked ? '🔒 ' : '') + (it.title_ar || '')));
      const pit = gr.pitems && gr.pitems.get(it.id);
      sp.appendChild(el('div', 'rs-meta', [it.bucket_ar, it.max_ar, it.tool_ar, it.is_attendance ? 'يُحسب آليًّا' : null, pit ? 'من الممارسات — تُحسب ولا تُكتب' : null, it.counts === false ? 'لا يُحتسب' : null].filter(Boolean).join(' · ')));
      if (it.note_ar) sp.appendChild(el('div', 'rs-meta', it.note_ar));
      if (pit && pit['البيان']) sp.appendChild(el('div', 'rs-meta', pit['البيان']));
      li.appendChild(sp);
      if (!ro && !it.locked && !it.is_attendance) {
        const w = el('span', 'rs-ibs');
        w.append(btn('عدّل', 'rs-btn ghost', () => itemForm({ key: it.bucket, label_ar: it.bucket_ar }, it)), btn('ارفع', 'rs-btn ghost', () => dropForm(it)));
        // تعليمُه «من الممارسات» بابٌ وحدَه بعد إنشائه (v2_grade_item_practice) — والدرجةُ المبدئيّةُ فيه لا في نموذج الإنشاء
        const planId = gr.card && gr.card.plan && gr.card.plan.id;
        if (pit) w.appendChild(btn('أرجِعه بندًا عاديًّا', 'rs-btn ghost', () => MM().unmarkForm({ id: it.id, title_ar: it.title_ar }, planId, gagain)));
        else if (it.bucket !== 'final' && it.bucket !== 'pre') w.appendChild(btn('من الممارسات', 'rs-btn ghost', () => MM().markForm({ id: it.id, title_ar: it.title_ar, max_ar: it.max_ar }, planId, gagain)));
        if (pers.length > 1) w.appendChild(btn('انقل إلى فترةٍ أخرى', 'rs-btn ghost', () => movePeriodForm(it, pers)));
        li.appendChild(w);
      }
      ul.appendChild(li);
    }
    return ul;
  }
  // نقلُ البند بين الفترتين: v2_grade_item_period — والفتراتُ بأسمائها من البطاقة
  function movePeriodForm(it, pers) {
    const others = pers.filter((x) => x.period_no !== gr.per).map((x) => [x.period_no, x.period_ar || '']);
    V.form({
      title: 'نقلُ البند إلى فترةٍ أخرى', what: it.title_ar || '', ok: 'انقله',
      fields: [{ key: 'p', type: 'pick', label: 'إلى', items: others, value: others.length === 1 ? others[0][0] : null }],
      onOk: async (v) => {
        const x = await M.rpc('v2_grade_item_period', { p_item: it.id, p_period: v.p }, 'نقل البند بين الفترتين');
        if (x.error) return x.error;
        V.flash('ok', (x.data && (x.data.said_ar || x.data.summary_ar)) || '');
        gagain(); return null;
      },
    });
  }

  // أدواتُ التقويم: يُرسل key ويُعرض label_ar · مجموعتان بـ kind كما جاء من الباب («أداة» · «أسلوب»)
  async function loadTools() {
    if (gr.tools) return null;
    const { data, error } = await M.rpc('v2_reference', { p_key: 'assess_tools' }, 'أدوات التقويم');
    if (error) return error;
    gr.tools = ((data && data.items) || []).slice().sort((a, b) => (a.ord || 0) - (b.ord || 0));
    gr.toolsNote = data && data.note;
    return null;
  }
  async function itemForm(b, it) {
    const e = await loadTools();
    if (e) { V.flash('bad', errText(e)); return; }
    const kinds = [...new Set(gr.tools.map((t) => t.kind).filter(Boolean))];
    const cur = it && it.tool_key ? gr.tools.find((t) => t.key === it.tool_key) : null;
    const fields = [
      { key: 'title', label: 'اسمُ البند', value: it ? it.title_ar : '' },
      { key: 'max', type: 'number', label: 'درجتُه العظمى', value: it ? it.max_points : null },
      { key: 'kind', type: 'pick', label: 'الأداةُ أو الأسلوب (اختياريّ)', items: kinds.map((k) => [k, k]), value: cur ? cur.kind : null, hint: gr.toolsNote },
    ];
    for (const k of kinds) fields.push({ key: 'tool_' + k, type: 'choose', label: k, items: gr.tools.filter((t) => t.kind === k).map((t) => [t.key, t.label_ar || '']), value: cur && cur.kind === k ? cur.key : null, show: (v) => v.kind === k });
    V.form({
      title: it ? 'تعديلُ بند' : 'بندٌ جديد', what: b.label_ar || '', ok: it ? 'احفظ' : 'أضف',
      fields,
      onOk: async (v) => {
        const tool = v.kind ? v['tool_' + v.kind] : null;
        const x = it
          ? await M.rpc('v2_grade_item_set', { p_item: it.id, p_title: v.title, p_max: v.max, p_tool: tool }, 'تعديل البند')
          : await M.rpc('v2_grade_item_add', { p_plan: gr.card.plan.id, p_bucket: b.key, p_title: v.title, p_max: v.max, p_tool: tool }, 'إضافة بند');
        if (x.error) return x.error;
        // والبندُ الجديدُ نُسب للفترة الجارية آليًّا — فتُقال فترتُه من الباب
        V.flash('ok', [x.data && (x.data.said_ar || x.data.summary_ar), x.data && x.data.period_ar].filter(Boolean).join(' · '));
        gagain(); return null;
      },
    });
  }
  // «ارفع» لا «احذف»: البندُ يبقى في السجلّ
  function dropForm(it) {
    V.form({
      title: 'رفعُ البند', what: it.title_ar || '', ok: 'ارفعه',
      onOk: async () => {
        const x = await M.rpc('v2_grade_item_drop', { p_item: it.id }, 'رفع البند');
        if (x.error) return x.error;
        V.flash('ok', (x.data && (x.data.said_ar || x.data.summary_ar)) || '');
        gagain(); return null;
      },
    });
  }

  // بطاقةُ الطالب: الفصلُ من v2_my_plan_subjects (section_id · class_ar) والطلّابُ من v2_loyalty_of_section
  // وحالُ الرصد (state · state_ar) من الباب: لا حكمَ قبل اكتمال الرصد — والتقديرُ (band_ar) في الحال full وحدَها
  async function gStudent(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_my_plan_subjects', { p_school: M.state.school, p_term: null }, 'فصولي');
    if (error) { errBox(c, error); arabize(c); return; }
    const row = ((data && data.rows) || []).find((r) => Number(r.grade) === Number(gr.subj.grade) && r.subject_ar === gr.subj.subject_ar);
    const secs = ((row && row.sections) || []).map((s) => [s.section_id, s.class_ar || '']);
    if (!secs.length) { line(c, 'rs-meta', data && data.summary_ar); arabize(c); return; }
    if (!gr.stuSec || !secs.some((s) => s[0] === gr.stuSec)) gr.stuSec = secs[0][0];
    const pk = el('div', 'rs-pick'); const list = el('div');
    c.append(pk, list);
    if (secs.length > 1) V.pick(pk, secs, gr.stuSec, (v) => { gr.stuSec = v; students(list); });
    else c.insertBefore(el('p', 'rs-meta', secs[0][1]), pk);
    students(list);
    arabize(c);
  }
  async function students(list) {
    list.textContent = '';
    const { data, error } = await M.rpc('v2_loyalty_of_section', { p_section: gr.stuSec }, 'طلّاب الفصل');
    if (error) { errBox(list, error); return; }
    const items = ((data && data.rows) || []).map((x) => [x.student_id, x.name || '']);
    V.chooser(list, items, null, (id) => studentCard(id, items.find((x) => x[0] === id)));
  }
  async function studentCard(id, it) {
    const { data, error } = await M.rpc('v2_grade_student', { p_student: id, p_grade: gr.subj.grade, p_subject: gr.subj.subject_ar, p_school: M.state.school, p_term: gr.term }, 'درجات الطالب');
    const n = el('div');
    if (error) n.appendChild(el('div', 'notice err', errText(error)));
    else {
      const d = data || {};
      // حالُ الرصد من الباب: none · partial بلا حكم — و full وحدَه يُعرض فيه التقديرُ وجملتُه
      if (d.state_ar) n.appendChild(el('p', 'rs-sum', d.state_ar));
      if (d.state === 'full') { if (d.band_ar) n.appendChild(el('p', 'rs-score', d.band_ar)); if (d.said_ar) n.appendChild(el('p', 'rs-meta', d.said_ar)); }
      if (d.total_ar) n.appendChild(el('p', 'rs-meta', d.total_ar));
      if (d.note_ar) n.appendChild(el('p', 'rs-meta', d.note_ar));
      // الفترتان: مجموعُ كلٍّ منهما بجملته (periods[].said_ar) ثمّ بنودُها — والنهائيُّ والقبليُّ صندوقان منفصلان
      const pers = d.periods || [];
      for (const pr of pers) {
        n.appendChild(el('h4', null, pr.period_ar || ''));
        // ومجموعُها بلفظه (sum_ar) وسقفُها (max_ar) — ولا يُكرَّر إن كانت جملتُها تقوله
        const sm = pr.sum_ar && !(pr.said_ar || '').includes(pr.sum_ar) ? pr.sum_ar : null;
        const pl2 = [pr.said_ar, sm, pr.max_ar ? 'من ' + pr.max_ar : null].filter(Boolean);
        if (pl2.length) n.appendChild(el('p', 'rs-meta', pl2.join(' · ')));
        const ul = el('ul', 'rs-acts');
        for (const x of (d.items || []).filter((y) => y.period_no === pr.period_no && y.counts !== false)) {
          const li = el('li'); const sp = el('span'); sp.style.flex = '1';
          sp.append(el('b', null, x.title_ar || ''), el('div', 'rs-meta', [x.points_ar, x.max_ar && !x.points_ar ? x.max_ar : null, x.said_ar].filter(Boolean).join(' · ')));
          li.appendChild(sp); ul.appendChild(li);
        }
        n.appendChild(ul);
      }
      const fin = d.final || [];
      if (fin.length) {
        const fb = el('div', 'gr-bucket');
        fb.appendChild(el('div', 'gr-bhead', 'للفصل الدراسيّ'));
        for (const x of fin) fb.appendChild(el('p', 'rs-meta', [x.title_ar, x.points_ar, x.max_ar && !x.points_ar ? x.max_ar : null].filter(Boolean).join(' · ')));
        n.appendChild(fb);
      }
      const pre = d.pre || [];
      if (pre.length) {
        const pb = el('div', 'gr-bucket pre');
        pb.appendChild(el('div', 'gr-bhead', 'التقويم القبليّ — لا يؤثّر في الدرجة'));
        for (const x of pre) pb.appendChild(el('p', 'rs-meta', [x.title_ar, x.points_ar].filter(Boolean).join(' · ')));
        n.appendChild(pb);
      }
    }
    // بنودُ الممارسات: درجتُها محسوبةٌ من v2_practice_item_mark — لا من v2_grade_student
    const pb = await MM().studentBox(await gPlan(), id);
    if (pb) n.appendChild(pb);
    arabize(n);
    V.form({ title: (data && data.name_ar) || (it && it[1]) || '', what: gr.subj.said_ar || '', ok: false, cancel: 'إغلاق', fields: [{ key: 'n', type: 'node', node: n }] });
  }

  // كشفُ الفصل (v2_grade_sheet): الطلّابُ صفوفًا والبنودُ أعمدة · والفصلُ بحرفه (sections[].section) يُرسل كما جاء
  // خليّةُ البند تُكتب فيها الدرجة ⇐ v2_grade_mark · وخليّةُ الحضور للقراءة وتُظهر said_ar · والقبليُّ عمودٌ بلونٍ آخر
  // والمجموعُ total_ar من الباب · ويبقى الكشفُ مفتوحًا بعد إقفال التوزيع
  async function gSheet(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_my_plan_subjects', { p_school: M.state.school, p_term: null }, 'فصولي');
    if (error) { errBox(c, error); arabize(c); return; }
    const row = ((data && data.rows) || []).find((r) => Number(r.grade) === Number(gr.subj.grade) && r.subject_ar === gr.subj.subject_ar);
    const secs = ((row && row.sections) || []).filter((x) => x.section).map((x) => [x.section, x.class_ar || '']);
    if (!secs.length) { line(c, 'rs-meta', data && data.summary_ar); arabize(c); return; }
    if (!gr.sheetSec || !secs.some((x) => x[0] === gr.sheetSec)) gr.sheetSec = secs[0][0];
    const pk = el('div', 'rs-pick'); const body = el('div');
    c.append(pk, body);
    if (secs.length > 1) V.pick(pk, secs, gr.sheetSec, (v) => { gr.sheetSec = v; drawSheet(body); });
    arabize(c);
    drawSheet(body);
  }
  async function drawSheet(body) {
    body.textContent = '';
    const { data, error } = await M.rpc('v2_grade_sheet', { p_grade: gr.subj.grade, p_subject: gr.subj.subject_ar, p_section: gr.sheetSec, p_school: M.state.school, p_term: gr.term }, 'كشف الفصل');
    if (error) { errBox(body, error); arabize(body); return; }
    const d = data || {};
    line(body, 'rs-sum', d.said_ar);
    line(body, 'rs-meta', [d.section_ar, d.term_ar, d.kind_ar, d.now_period_ar].filter(Boolean).join(' · '));
    line(body, 'rs-meta', d.note_ar);
    const studs = d.students || [];
    if (!studs.length) { arabize(body); return; }
    const pitems = await MM().practiceItems(await gPlan());
    // الأعمدةُ مجموعةٌ بفتراتها (period_no) بترتيبها · وما لا فترةَ له (القبليُّ والنهائيُّ) تحت «للفصل»
    const gk = (it) => (it.period_no == null ? 99 : it.period_no);
    const cols = (studs[0].items || []).map((it, i) => [it, i]).sort((a, b) => gk(a[0]) - gk(b[0]) || a[1] - b[1]).map((x) => x[0]);
    const wrap = el('div', 'gr-sheet');
    const tb = el('table');
    const gh = el('tr');
    gh.appendChild(el('th', 'gr-name', ''));
    for (let i = 0; i < cols.length;) {
      let j = i; while (j < cols.length && gk(cols[j]) === gk(cols[i])) j++;
      const th = el('th', 'gr-grp' + (cols[i].period_no == null ? ' pre' : ''), cols[i].period_no == null ? 'للفصل' : (cols[i].period_ar || ''));
      th.colSpan = j - i; gh.appendChild(th); i = j;
    }
    gh.appendChild(el('th', null, ''));
    tb.appendChild(gh);
    const hr = el('tr');
    hr.appendChild(el('th', 'gr-name', 'الطالب'));
    for (const it of cols) {
      const th = el('th', it.bucket === 'pre' ? 'pre' : null);
      th.append(el('b', null, it.title_ar || ''), el('small', null, it.max_ar || ''));
      hr.appendChild(th);
    }
    hr.appendChild(el('th', null, 'المجموع'));
    tb.appendChild(hr);
    for (const st of studs) {
      const tr = el('tr');
      tr.appendChild(el('td', 'gr-name', st.name_ar || ''));
      const tot = el('td', 'gr-tot', st.total_ar || '');
      const byId = new Map((st.items || []).map((x) => [x.item_id, x]));
      for (const col of cols) {
        const it = byId.get(col.item_id);
        if (!it) { tr.appendChild(el('td')); continue; }
        const td = el('td', it.bucket === 'pre' ? 'pre' : null);
        if (pitems.has(it.item_id)) {
          // بندُ الممارسات يُحسب ولا يُكتب — لا حقل، وعند اللمس بيانُه من v2_practice_item_mark
          td.appendChild(MM().markCell(it.item_id, st.student_id, st.name_ar));
        } else if (it.is_attendance) {
          // الحضورُ يُحسب آليًّا — للقراءة، وعند اللمس نصُّه
          const b = btn('يُحسب آليًّا', 'gr-auto', () => V.flash('ok', it.said_ar || ''));
          td.appendChild(b);
        } else {
          const inp = el('input'); inp.type = 'number'; inp.inputMode = 'decimal'; inp.setAttribute('data-raw', '');
          inp.setAttribute('aria-label', (st.name_ar || '') + ' — ' + (it.title_ar || ''));
          if (it.points != null) inp.value = String(Number(it.points));
          let was = inp.value;
          inp.addEventListener('change', async () => {
            if (inp.value === was) return;
            const v = inp.value === '' ? null : Number(inp.value);
            const x = await M.rpc('v2_grade_mark', { p_item: it.item_id, p_student: st.student_id, p_points: v }, 'رصد درجة');
            if (x.error) { V.flash('bad', errText(x.error)); inp.value = was; return; }
            was = inp.value;
            V.flash('ok', (x.data && x.data.said_ar) || '');
            // المجموعُ بلفظه من الباب بعد الرصد
            const y = await M.rpc('v2_grade_sheet', { p_grade: gr.subj.grade, p_subject: gr.subj.subject_ar, p_section: gr.sheetSec, p_school: M.state.school, p_term: gr.term }, 'كشف الفصل');
            const me = ((y.data && y.data.students) || []).find((z) => z.student_id === st.student_id);
            if (me) { tot.textContent = me.total_ar || ''; arabize(tot); }
          });
          td.appendChild(inp);
        }
        tr.appendChild(td);
      }
      tr.appendChild(tot);
      tb.appendChild(tr);
    }
    wrap.appendChild(tb);
    body.appendChild(wrap);
    arabize(body);
  }

  M.start({ screen: 'muallim', onChange: () => refresh() });
})();
