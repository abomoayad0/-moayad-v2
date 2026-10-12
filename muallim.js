// مؤيّد · صفحةُ المعلّم (تكليف ⑤) — بيتٌ واحدٌ بستّة أقسامٍ وشريطِ «صفتي»
// الأقسام: صفّي · توزيعُ المنهج · يومي في المدرسة · ما كُلِّفتُ به · ما وصلني · ما يُقاس بي
// والظهورُ بالتكليف لا بالصلاحية: قسمُ التوزيع لمن صفتُه النافذةُ معلّمُ موادّ أو تربيةٍ خاصّة أو موهوبين
// ① قسمُ «توزيع المنهج»: موادّي (v2_my_plan_subjects) ومن كلّ سطرٍ لوحاتُه — البطاقة · بلا أسبوع · المنهج · الكفاية · المخارج · حدُّ الفصلين
// ② «صفّي» و«يومي» و«ما كُلِّفتُ به» و«ما وصلني» قائمةٌ اليومَ في شاشتَي «الحصّة» و«ما عليّ» — وتُنقل إلى هنا بترتيب مفرح
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn } = V;

  const TEACHING = ['subject_teacher', 'sped_teacher', 'gifted_teacher'];
  const ui = { sec: 'plan' };
  const role = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };

  const SECTIONS = [
    ['mine', 'صفّي'], ['plan', 'توزيعُ المنهج'], ['day', 'يومي في المدرسة'],
    ['tasks', 'ما كُلِّفتُ به'], ['inbox', 'ما وصلني'], ['measured', 'ما يُقاس بي'],
  ];

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    // بالتكليف: قسمُ التوزيع لمن يُدرّس وحدَه
    const list = SECTIONS.filter(([k]) => k !== 'plan' || TEACHING.includes(role()));
    if (!list.some(([k]) => k === ui.sec)) ui.sec = list[0][0];
    V.pick($('sections'), list, ui.sec, (v) => { ui.sec = v; render(); });
    render();
  }

  function render() {
    const box = $('sectionBody'); box.textContent = '';
    ({ mine: secLink('hissa.html', 'افتح «الحصّة»'), plan: secPlan, day: secLink('mukallaf.html', 'افتح «ما عليّ»'),
      tasks: secLink('mukallaf.html', 'افتح «ما عليّ»'), inbox: secLink('mukallaf.html', 'افتح «ما عليّ»'), measured: secMeasured }[ui.sec])(box);
  }
  // الأقسامُ القائمةُ في شاشتَين — تُفتح منهما حتى تُنقل
  const secLink = (href, label) => (box) => {
    const c = el('section', 'rs-card');
    c.appendChild(el('p', 'rs-meta', 'هذا القسمُ قائمٌ اليومَ في شاشةٍ مستقلّة، ويُنقل إلى هذي الصفحة بترتيب العمل.'));
    const r = el('div', 'rs-row'); r.appendChild(btn(label, 'rs-btn', () => { location.href = href; })); c.appendChild(r);
    box.appendChild(c);
  };
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
    const why = [it.why, it.move_why].filter(Boolean).join(' — ');
    if (why) b.appendChild(el('div', 'rs-meta', why));
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
  // والأحوالُ والأنواعُ تُعرض بألفاظها كما جاءت في البطاقة نفسِها — فلا بابَ يُعطي قائمتَها كاملةً بألفاظها (ثغرةٌ مرفوعة)
  function itemSheet(it, first) {
    const d = plan.card || {};
    const all = [];
    for (const w of d.weeks || []) for (const x of w.items || []) all.push(x);
    const states = new Map(); const kinds = new Map();
    for (const x of all) {
      if (x.state && x.state_ar) states.set(x.state, x.state_ar);
      for (const s of x.by_section || []) if (s.state && s.state_ar) states.set(s.state, s.state_ar);
      if (x.kind && x.kind_ar) kinds.set(x.kind, x.kind_ar);
    }
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
      lab.append(cb, document.createTextNode(' ' + (s.label_ar || '') + (st ? ' — ' + [st.state_ar, st.on_ar, st.why].filter(Boolean).join(' · ') : '')));
      secBox.appendChild(lab); checks.push(cb);
    }
    const isA = (k) => (v) => v.act === k;
    V.form({
      title: it.title_ar || '',
      what: [it.kind_ar, it.periods_ar, it.state_ar, it.done_sections_ar].filter(Boolean).join(' · '),
      ok: 'سجّل',
      fields: [
        { key: 'act', type: 'pick', label: 'ما تفعل', items: acts, value: first || acts[0][0] },
        { key: 'state', type: 'pick', label: 'حالُه', items: [...states], show: isA('mark') },
        { key: 'secs', type: 'node', node: secBox, show: isA('mark') },
        { key: 'used', type: 'number', label: 'الحصصُ التي استُعملت (إن شئت)', show: isA('mark') },
        { key: 'week', type: 'choose', label: 'إلى أيّ أسبوع', items: weeks, show: isA('move') },
        { key: 'periods', type: 'number', label: 'عددُ حصصه', show: isA('periods') },
        { key: 'kind', type: 'pick', label: 'وسمُه في خطّتك', items: [...kinds], show: isA('kind') },
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

  // منهجُ المادّة كما في الكتاب: الوحداتُ ودروسُها — والأعدادُ لا تُكتب: الباب يرجعها بلا ألفاظ (ثغرةٌ مرفوعة)
  async function pCurr(box) {
    const c = el('section', 'rs-card');
    box.appendChild(c);
    const { data, error } = await M.rpc('v2_curriculum_of', { p_grade: plan.subj.grade, p_subject: plan.subj.subject_ar }, 'منهج مادّتي');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    line(c, 'rs-sum', d.summary_ar);
    for (const u of d.rows || []) {
      const det = el('details', 'rs-dt');
      det.appendChild(el('summary', null, u.unit_ar || ''));
      const ul = el('ul', 'rs-acts');
      for (const x of u.lessons || []) ul.appendChild(el('li', null, x.title || ''));
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

  M.start({ screen: 'muallim', onChange: () => refresh() });
})();
