// مؤيّد · شاشة الموجّه — viewM في المحاكي: دوري · مؤشّرُ الحالات · بطاقةُ الحالة · جلساتي · سجلُّ الملفّ.
// 🔒 دراسةُ الحالة والجلسات سرٌّ عند الموجّه: لا تُعرض في غير هذي الشاشة، والقاعدةُ تحرسها ورفضُها يُعرض بنصّه.
// v2_counsel_board · v2_case_card · v2_case_write · v2_session_add · v2_case_report · v2_student_timeline(p_student, 'counselor')
// وخطّةُ تعديل السلوك في بطاقة الحالة (plan.js · تكليف ⑯): الموجّهُ «القائم بتعديل السلوك» بنصّ ذيل ص٦١ — يكتبها ويُسجّل قياسَها
// ومحضرُ التوعية لم يُبنَ في المحرّك — فيُعرض معطّلًا بسببه.
// «مهامّي» (تكليف ٣٣): v2_counsel_my_tasks عدّادًا في الرأس، والصفُّ يفتح بطاقةَ حالة الطالب إن كانت له حالةٌ محوَّلة، وإلّا سجلَّ ملفّه — في هذي الشاشة
// و«مكتبةُ عملي» لسانٌ هنا: v2_counsel_stages (تسعُ مراحلَ بسؤال كلٍّ) · v2_counsel_works (لي أوّلًا · وغيرُ المبنيّ رماديٌّ بلا زرّ)
// و«سجلّاتي» (تكليف ٣٦ · riaya.js): فهرسُ سجلّات الرعاية بعدّاداتها · وسجلّاتُ رعاية الطالب في ملفّه — منه يُوسَم ويُخرَج بسبب
// وما كتبه إنسانٌ بيده (الدراسة · الجلسات · التقرير · ملاحظةُ الرصدة) يُعرض حرفًا بحرف: [data-raw] لا تُحوَّل أرقامُه
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { ar, arabize, btn, notBuilt, flash, pick } = V;

  // حالُ المعالجة كما تكتبه القاعدة في counsel_cases.state — يُمرَّر إليها فتصفّي هي
  const STATES = [['', 'الكلّ'], ['قيد المعالجة', 'قيد المعالجة'], ['تمّت المعالجة', 'تمّت المعالجة'], ['مغلقة', 'مغلقة']];
  // مدى الاستجابة: الأربعةُ التي يقبلها قيدُ counsel_sessions_response_check — والقاعدةُ ترفض غيرها
  const RESPONSES = ['تحسّنٌ ملحوظ', 'تحسّنٌ طفيف', 'السلوكُ مستمرّ', 'تراجُع'];

  const ui = { state: '', cases: [], caseId: null, card: null, resp: null, busy: false };
  const sess = V.sheet('sessModal');
  const rep = V.sheet('repModal');
  const raw = (n) => { n.setAttribute('data-raw', ''); return n; };

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    ui.caseId = null; ui.card = null;
    $('caseCard').hidden = true; $('tlCard').hidden = true; $('careCard').hidden = true;
    $('riaya').textContent = '';
    if ($('riayaBox').open) window.MoayadRiaya.tab($('riaya'), openStudent);
    // صندوقُه: نموذجُ الإحالة (٧) يصله سرًّا هنا وحدَه
    $('inboxCard').hidden = false;
    V.inbox($('inbox'), $('inboxTitle'));
    await loadBoard();
    loadTasks();
    if ($('libBox').open) loadLib();
  }

  // ---------- «مهامّي» ----------
  // ثلاثُ قوائم في بابٍ واحد — والصفرُ حالٌ لا خلل
  async function loadTasks() {
    const box = $('myTasks');
    box.textContent = '';
    const { data, error } = await M.rpc('v2_counsel_my_tasks', { p_school: M.state.school }, 'مهامّي');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    box.appendChild(el('p', 'rs-big', 'الجملة: ' + ar(d['الجملة'] == null ? 0 : d['الجملة'])));
    if (d['البيان']) box.appendChild(el('p', 'rs-meta', d['البيان']));
    for (const [k, n, title] of [['مهام_السلوك', 'عدد_السلوك', 'مهامُّ السلوك'], ['مهام_الغياب', 'عدد_الغياب', 'مهامُّ الغياب'], ['حالات_تنتظر_الدراسة', 'عدد_الحالات', 'حالاتٌ تنتظرُ الدراسة']]) {
      const rows = d[k] || [];
      box.appendChild(el('div', 'rs-label', title + ': ' + ar(d[n] == null ? rows.length : d[n])));
      if (!rows.length) continue;
      const ul = el('ul', 'rs-acts');
      for (const r of rows) {
        const li = el('li', 'click' + (r['متأخرة'] ? ' rs-red' : ''));
        li.setAttribute('role', 'button'); li.tabIndex = 0;
        const sp = el('span'); sp.style.flex = '1';
        sp.append(el('b', null, [r['الطالب'], r['الصف']].filter(Boolean).join(' · ')), el('div', 'rs-meta', [r['المهمة'], r['منذ_ar'], r['موعدها']].filter(Boolean).join(' · ')));
        li.appendChild(sp);
        V.tap(li, () => openStudent(r['الطالب_id']));
        ul.appendChild(li);
      }
      box.appendChild(ul);
    }
    arabize(box);
  }
  // بطاقتُه هنا: حالتُه المحوَّلةُ إن وُجدت في المؤشّر — وإلّا سجلُّ ملفّه (بصفة الموجّه)
  async function openStudent(sid) {
    if (!sid) return;
    const c = ui.cases.find((x) => x.student_id === sid);
    if (c) { openCase(c.case); return; }
    $('caseCard').hidden = true;
    await loadTimeline(sid);
    $('tlBox').open = true;
    $('tlCard').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  // ---------- «مكتبةُ عملي» ----------
  // المراحلُ التسعُ بسؤال كلٍّ تحت عنوانها — لا قائمةَ أعمالٍ واحدة
  async function loadLib() {
    const box = $('lib');
    box.textContent = '';
    const { data, error } = await M.rpc('v2_counsel_stages', { p_school: M.state.school }, 'مراحل عمل الموجّه');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-sum', d['البيان']));
    if (d['جملة_البيان']) box.appendChild(el('p', 'rs-meta', d['جملة_البيان']));
    for (const s of (d['المراحل'] || []).slice().sort((a, b) => (a['الترتيب'] || 0) - (b['الترتيب'] || 0))) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, s['المرحلة'] || ''), el('p', 'rs-big', s['السؤال'] || ''));
      if (s['البيان']) f.appendChild(el('p', 'rs-meta', s['البيان']));
      const w = el('div');
      f.appendChild(btn('أعمالُ هذي المرحلة', 'rs-btn soft', () => loadWorks(w, s['مفتاح'])));
      f.appendChild(w);
      box.appendChild(f);
    }
    arabize(box);
  }
  async function loadWorks(box, stage) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_counsel_works', { p_school: M.state.school, p_stage: stage }, 'أعمال المرحلة');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-meta', d['البيان']));
    // «لي» أوّلًا — وما لغيره يراه ليعرف موضعَه منه · والسرّيُّ بلا مشاركة · وغيرُ المبنيّ رماديٌّ بلا زرّ
    const rows = (d['الأعمال'] || []).slice().sort((a, b) => (b['لي'] === true) - (a['لي'] === true) || (a['الترتيب'] || 0) - (b['الترتيب'] || 0));
    for (const x of rows) {
      const f = el('div', 'rs-file' + (x['حاله_عندنا'] === 'غيرُ مبنيّ' ? ' rs-prev' : ''));
      f.appendChild(el('h5', null, x['العمل'] || ''));
      f.appendChild(el('p', 'rs-meta', [x['نوعه'], x['المجموعة'], x['النموذج'] ? 'النموذج ' + x['النموذج'] : null, x['حاله_عندنا'], x['سنده'], x['سرّي'] ? 'سرّي' : null, x['لي'] ? null : (x['مالكه_ar'] ? 'لغيرك: ' + x['مالكه_ar'] : 'لغيرك')].filter(Boolean).join(' · ')));
      if (x['مما_يعبّأ']) f.appendChild(el('p', 'rs-meta', x['مما_يعبّأ']));
      if (x['ملاحظة']) f.appendChild(el('p', 'rs-meta', x['ملاحظة']));
      box.appendChild(f);
    }
    if (!rows.length) box.appendChild(el('p', 'rs-empty', 'لا أعمال.'));
    arabize(box);
  }
  $('libBox').addEventListener('toggle', () => { if ($('libBox').open && !$('lib').children.length) loadLib(); });
  // «سجلّاتي» (تكليف ٣٦) — riaya.js · والطالبُ يُفتح ملفُّه هنا
  $('riayaBox').addEventListener('toggle', () => { if ($('riayaBox').open && !$('riaya').children.length) window.MoayadRiaya.tab($('riaya'), openStudent); });

  // ---------- ② المؤشّر ----------
  async function loadBoard() {
    pick($('fState'), STATES, ui.state, (v) => { ui.state = v; loadBoard(); });
    const { data, error } = await M.rpc('v2_counsel_board', { p_school: M.state.school, p_state: ui.state || null }, 'مؤشّر متابعة الحالات');
    const box = $('board');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); ui.cases = []; renderMine(); return; }
    ui.cases = data || [];
    if (!ui.cases.length) {
      box.appendChild(el('p', 'rs-meta', 'لم يُحَل إليك شيءٌ بعد — يُحال الملفُّ آليًّا من مؤشّر السلوك.'));
      renderMine();
      return;
    }
    const wrap = el('div', 'rs-tablewrap');
    const t = el('table', 'rs-table');
    t.style.minWidth = '0';
    // كلُّ حالةٍ سطرُها من الباب (said_ar · تكليف ⑮): الطالبُ والمشكلةُ والدرجةُ والرصداتُ وتاريخُ الفتح وموضعُها من المسار
    // و state بلفظه من القاعدة — لا يُترجم ولا يُركَّب حولهما شيء
    for (const c of ui.cases) {
      const tr = el('tr', 'click' + (c.case === ui.caseId ? ' on' : ''));
      tr.tabIndex = 0;
      const stTd = el('td');
      stTd.appendChild(el('span', c.state === 'تمّت المعالجة' ? 'rs-state-done' : 'rs-state-open', c.state || ''));
      tr.append(el('td', null, c.said_ar || ''), stTd);
      tr.addEventListener('click', () => openCase(c.case));
      tr.addEventListener('keydown', (e) => { if (e.key === 'Enter') openCase(c.case); });
      t.appendChild(tr);
    }
    wrap.appendChild(t);
    box.appendChild(wrap);
    box.appendChild(el('div', 'rs-note', 'اجتهادٌ لا نصّ: هيكلُ المؤشّر مأخوذٌ من شاشة نور، وشكلُ الدراسة من تصميمنا — فالدليلُ يوجب الفعلَ ولا نموذجَ له.'));
    arabize(box);
    renderMine();
  }

  // ---------- ③ بطاقةُ الحالة ----------
  async function openCase(id) {
    ui.caseId = id;
    for (const tr of document.querySelectorAll('#board tr.click')) tr.classList.remove('on');
    await loadCase();
    $('caseCard').scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  async function loadCase() {
    const { data, error } = await M.rpc('v2_case_card', { p_case: ui.caseId }, 'بطاقة الحالة');
    $('caseCard').hidden = false;
    if (error) {
      ui.card = null;
      $('caseFacts').textContent = '';
      $('caseFacts').appendChild(el('div', 'notice err', errText(error)));
      return;
    }
    ui.card = data || {};
    renderCase();
    const sid = ui.card.case && ui.card.case.student_id;
    if (sid) loadTimeline(sid);
    const i = ui.cases.findIndex((c) => c.case === ui.caseId);
    const rows = document.querySelectorAll('#board tr.click');
    if (i >= 0 && rows[i]) rows[i].classList.add('on');
  }

  function kv(t, k, v) {
    const tr = el('tr');
    const td = el('td', null, v == null || v === '' ? '—' : String(v));
    // المفتاحُ خانةٌ لا رأس — فقاعدةُ الجوّال تُخفي كلَّ صفٍّ فيه th (رأسُ الجدول)، فكان الجدولُ يختفي على الهاتف
    tr.append(el('td', 'kv-k', k), td);
    t.appendChild(tr);
    return td;
  }

  function renderCase() {
    const d = ui.card;
    const c = d.case || {};
    const st = d.student || {};
    const g = d.guardian || {};
    const p = d.problem || {};
    $('caseTitle').textContent = p.text || 'بطاقةُ الحالة';
    // سطرُ الحالة من الباب (said_ar) — الجملةُ نفسُها التي في المكتب، فيتّسق المؤشّرُ والبطاقة · و state بلفظه
    $('caseMeta').textContent = [d.said_ar, c.state].filter(Boolean).join(' · ');

    // ما يعرفه النظام — عرضًا فقط
    const f = $('caseFacts');
    f.textContent = '';
    f.appendChild(el('div', 'rs-label', 'ما يعرفه النظام — عرضًا فقط'));
    const t = el('table', 'rs-table');
    t.style.minWidth = '0';
    kv(t, 'الطالب', st.name);
    raw(kv(t, 'رقم القيد', st.student_no)); // رقمُ القيد يبقى كما هو
    kv(t, 'وليُّ أمره', (g.name || '') + (g.relation ? ' — ' + g.relation : ''));
    kv(t, 'المشكلة', [p.text, p.degree_ar, p.source_ar].filter(Boolean).join(' · '));
    kv(t, 'المحسوم', d.deducted_ar);
    kv(t, 'الفصل الدراسيّ', c.term_ar);
    kv(t, 'حالُ المعالجة', c.state);
    kv(t, 'الجلسات', d.sessions_ar);
    kv(t, 'التقرير', d.reported_ar);
    if (c.closed_on_ar) kv(t, 'تاريخ الإغلاق', c.closed_on_ar);
    f.appendChild(t);
    const recs = d.records || [];
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, ['الرصدات', d.records_ar].filter(Boolean).join(' — ')));
    const db = el('div', 'rs-dtb');
    // كلُّ رصدةٍ بألفاظها (no_ar · on_ar · step_ar) — ومن دوّنها ومكانُها في خانات، وملاحظتُها كما كُتبت
    for (const r of recs) {
      const row = el('div');
      row.appendChild(el('b', null, [r.no_ar, r.on_ar, r.step_ar].filter(Boolean).join(' · ')));
      const lg = el('div', 'rs-lgd');
      if (r.by) lg.append(el('i', 'k', 'دوّنها:'), el('i', null, r.by));
      if (r.place) lg.append(el('i', 'k', 'المكان:'), raw(el('i', null, r.place)));
      if (r.note) lg.append(el('i', 'k', 'ملاحظة:'), raw(el('i', null, r.note)));
      if (lg.childNodes.length) row.appendChild(lg);
      db.appendChild(row);
    }
    if (!recs.length) db.appendChild(el('div', null, 'لا رصدات مرتبطة.'));
    det.appendChild(db);
    f.appendChild(det);
    arabize(f);
    arabize($('caseMeta'));

    // دراسةُ الحالة بحقولها الأربعة — وتحتها ما تقوله القاعدة: لا حقلَ للأسرة ولا للحالة الصحّيّة
    $('cwView').value = c.student_view || '';
    $('cwObs').value = c.observed || '';
    $('cwFac').value = c.factors || '';
    $('cwPlan').value = c.plan_ar || '';
    $('cwNote').textContent = d.note || '';
    $('cwNote').hidden = !d.note;
    $('cwAt').textContent = c.written_at_ar ? 'تاريخ كتابة الدراسة: ' + c.written_at_ar : (c.written_at ? '' : 'لم تُكتب بعد');
    $('cwSave').textContent = c.written_at ? 'احفظ تعديلَ الدراسة' : 'احفظ الدراسة';
    $('cwSave').className = c.written_at ? 'rs-btn soft' : 'rs-btn big';

    // الجلسات — لا يظهر زرُّها قبل الدراسة
    const sb = $('sessBox');
    sb.textContent = '';
    const ss = d.sessions || [];
    if (c.written_at) sb.appendChild(btn('قيّد جلسةَ متابعة', 'rs-btn', openSession));
    else sb.appendChild(el('p', 'rs-meta', 'لا تُفتح جلسةٌ قبل أن تُكتب دراسةُ الحالة.'));
    if (ss.length) sb.appendChild(sessionList(ss));
    else if (c.written_at) sb.appendChild(el('p', 'rs-meta', 'لا جلساتِ بعد.'));
    arabize(sb);

    // التقرير — لا يظهر زرُّه بلا جلسة
    const rb = $('repBox');
    rb.textContent = '';
    const r = d.report;
    if (r) {
      const t2 = el('table', 'rs-table');
      t2.style.minWidth = '0';
      // حقولُ التقرير المصرَّحة (تكليف ⑯) — والرأيُ والتوصيةُ كما كتبهما الموجّه
      kv(t2, 'تاريخ الرفع', r.issued_on_ar);
      kv(t2, 'الجلسات', r.sessions_ar);
      kv(t2, 'المدى', r.span_ar);
      kv(t2, 'آخرُ تقديرٍ للاستجابة', r.last_resp);
      kv(t2, 'الحكم', r.judgement);
      raw(kv(t2, 'الرأيُ الفنّيّ', r.opinion));
      raw(kv(t2, 'التوصية', r.recommend));
      rb.append(t2, el('div', 'rs-note', 'رُفع التقريرُ للّجنة — ولا يُرفع مرّتين.'));
    } else if (ss.length) {
      rb.appendChild(btn('ارفع تقريرَ دراسة الحالة', 'rs-btn', openReport));
    } else {
      rb.appendChild(el('p', 'rs-meta', 'لا تقريرَ بلا جلسةِ متابعةٍ واحدةٍ على الأقلّ.'));
    }
    arabize(rb);

    const off = $('caseOff');
    off.textContent = '';
    off.append(notBuilt('محضرُ التوعية'));
    loadPlans();
  }

  // خطّةُ تعديل السلوك للطالب (v2_plan_of) — مربوطةً برصدة الحالة فيُقاس على مخالفتها، وبنكُ العبارات بمشكلتها
  async function loadPlans() {
    const c = (ui.card && ui.card.case) || {};
    const box = $('casePlans');
    if (!c.student_id) { box.textContent = ''; return; }
    const caseId = ui.caseId;
    const res = await M.rpc('v2_plan_of', { p_student: c.student_id }, 'خطّة تعديل السلوك');
    if (caseId !== ui.caseId) return;
    window.MoayadPlan.render(box, { result: res, student: { student_id: c.student_id, name: (ui.card.student || {}).name }, task: null, record: c.record_id || null, problem: c.problem_id == null ? null : c.problem_id, reload: loadPlans });
  }

  // الجلساتُ سجلٌّ .acts — الأحدثُ أعلى كما ترجعه القاعدة
  function sessionList(ss, label) {
    const ul = el('ul', 'rs-acts');
    for (const x of ss) {
      const li = el('li');
      const body = el('span');
      body.style.flex = '1';
      // no_ar · on_ar · minutes_ar من الباب (تكليف ⑰) — والمدّةُ تسقط إن لم تأتِ، ولا تُلصق «دقيقة» بعدد
      body.appendChild(el('b', null, [label ? label(x) : null, x.no_ar, x.minutes_ar].filter(Boolean).join(' · ')));
      const lg = el('div', 'rs-lgd');
      lg.append(el('i', 'k', 'ما نُوقش:'), raw(el('i', null, x.discussed || '')),
        el('i', 'k', 'الاستجابة:'), el('i', null, x.response || ''),
        el('i', 'k', 'التالي:'), raw(el('i', null, x.next || '')));
      body.appendChild(lg);
      li.append(el('i', 'rs-tick ok', '✓'), body, el('small', 'rs-who', x.on_ar || ''));
      ul.appendChild(li);
    }
    return ul;
  }

  $('cwSave').addEventListener('click', async () => {
    if (ui.busy || !ui.caseId) return;
    ui.busy = true;
    $('cwSave').disabled = true;
    flash('wait', 'يُحفظ…');
    const { error } = await M.rpc('v2_case_write', {
      p_case: ui.caseId, p_student_view: $('cwView').value.trim(), p_observed: $('cwObs').value.trim(),
      p_factors: $('cwFac').value.trim(), p_plan: $('cwPlan').value.trim(),
    }, 'دراسة الحالة');
    ui.busy = false;
    $('cwSave').disabled = false;
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', 'حُفظت دراسةُ الحالة');
    await loadCase();
    loadBoard();
  });

  // ---------- جلسةُ متابعة ----------
  function renderResp() { pick($('sResp'), RESPONSES.map((x) => [x, x]), ui.resp, (v) => { ui.resp = v; renderResp(); }); }
  function openSession() {
    $('sOn').value = M.state.date || '';
    $('sMin').value = '';
    $('sDisc').value = '';
    $('sNext').value = '';
    ui.resp = null; // يُختار صراحةً — لا قيمةَ مسبقة
    renderResp();
    sess.open();
    $('sDisc').focus();
  }
  $('sCancel').addEventListener('click', sess.close);
  $('sOk').addEventListener('click', async () => {
    if (ui.busy) return;
    ui.busy = true;
    $('sOk').disabled = true;
    const { data, error } = await M.rpc('v2_session_add', {
      p_case: ui.caseId, p_on: $('sOn').value || null, p_minutes: $('sMin').value ? Number($('sMin').value) : null,
      p_discussed: $('sDisc').value.trim(), p_response: ui.resp, p_next: $('sNext').value.trim(),
    }, 'جلسة متابعة');
    ui.busy = false;
    $('sOk').disabled = false;
    // رُفضت ⇒ يبقى اللوحُ بما كُتب فيه، ونصُّ الرفض كما هو
    if (error) { flash('bad', errText(error)); return; }
    sess.close();
    flash('ok', (data && data.said_ar) || ''); // جملتُه من الباب (تكليف ⑰) — لا «قُيّدت» تُكتب هنا
    await loadCase();
    loadBoard();
  });

  // ---------- التقرير ----------
  function openReport() {
    // ما يُجمع آليًّا يُعرض كما في بطاقة الحالة — والحكمُ يضعه النظامُ عند الرفع
    const ss = ui.card.sessions || [];
    const a = $('repAuto');
    a.textContent = '';
    if (ui.card.sessions_ar) a.appendChild(el('div', null, 'الجلسات: ' + ui.card.sessions_ar));
    if (ss.length) a.appendChild(el('div', null, 'آخرُ تقديرٍ للاستجابة: ' + (ss[0].response || '—')));
    a.appendChild(el('div', null, 'والحكمُ يضعه النظامُ عند الرفع.'));
    arabize(a);
    $('rOpinion').value = '';
    $('rRec').value = '';
    rep.open();
    $('rOpinion').focus();
  }
  $('rCancel').addEventListener('click', rep.close);
  $('rOk').addEventListener('click', async () => {
    if (ui.busy) return;
    ui.busy = true;
    $('rOk').disabled = true;
    const { data, error } = await M.rpc('v2_case_report', {
      p_case: ui.caseId, p_opinion: $('rOpinion').value.trim(), p_recommend: $('rRec').value.trim(),
    }, 'تقرير دراسة الحالة');
    ui.busy = false;
    $('rOk').disabled = false;
    if (error) { flash('bad', errText(error)); return; }
    rep.close();
    flash('ok', 'رُفع التقريرُ إلى لجنة التوجيه — الحكم: ' + ((data && data.judgement) || '') + ' · ' + ((data && data.state) || ''));
    await loadCase();
    loadBoard();
  });

  // ---------- ④ جلساتي — من بطاقات الحالات التي فيها جلسات ----------
  async function renderMine() {
    const withS = ui.cases.filter((c) => c.sessions > 0);
    $('mineCard').hidden = !withS.length;
    if (!withS.length) return;
    const res = await Promise.all(withS.map((c) => M.rpc('v2_case_card', { p_case: c.case }, 'بطاقة الحالة')));
    const box = $('mine');
    box.textContent = '';
    let n = 0;
    res.forEach((r, i) => {
      if (r.error) { box.appendChild(el('div', 'notice err', errText(r.error))); return; }
      const c = withS[i];
      const ss = (r.data && r.data.sessions) || [];
      n += ss.length;
      box.appendChild(sessionList(ss, () => (c.student || '') + ' — ' + (c.problem || '')));
    });
    $('mineSum').textContent = 'جلساتي (' + n + ')';
    arabize($('mineCard'));
  }

  // ---------- ⑤ سجلُّ الملفّ — بصفة الموجّه ----------
  async function loadTimeline(sid) {
    const { data, error } = await M.rpc('v2_student_timeline', { p_student: sid, p_as: 'counselor' }, 'السجلّ الزمنيّ');
    $('tlCard').hidden = false;
    const box = $('timeline');
    if (error) { box.textContent = ''; box.appendChild(el('div', 'notice err', errText(error))); return; }
    const evs = (data && data.events) || [];
    // سجلّاتُ رعايته — ووسمُه من ملفّه (تكليف ٣٦)
    $('careCard').hidden = false;
    window.MoayadRiaya.studentBlock($('care'), { id: sid, name: (ui.card && ui.card.student && ui.card.student.name && ui.card.case && ui.card.case.student_id === sid) ? ui.card.student.name : (data && (data.student_ar || data.name_ar)) || '' });
    $('tlSum').textContent = 'سجلُّ الملفّ (' + ar(evs.length) + ') — تنظر بصفة ' + ((data && data.as_ar) || '—');
    V.events(box, evs);
  }

  M.start({ screen: 'muwajjih', onChange: () => refresh() });
})();
