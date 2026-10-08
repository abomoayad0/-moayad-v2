// مؤيّد · شاشة الموجّه — viewM في المحاكي: دوري · مؤشّرُ الحالات · بطاقةُ الحالة · جلساتي · سجلُّ الملفّ.
// 🔒 دراسةُ الحالة والجلسات سرٌّ عند الموجّه: لا تُعرض في غير هذي الشاشة، والقاعدةُ تحرسها ورفضُها يُعرض بنصّه.
// v2_counsel_board · v2_case_card · v2_case_write · v2_session_add · v2_case_report · v2_student_timeline(p_student, 'counselor')
// وخطّةُ تعديل السلوك ومحضرُ التوعية وبنكُ العبارات لم تُبنَ في المحرّك — فتُعرض معطّلةً بسببها.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { ar, arabize, btn, notBuilt, flash, pick } = V;

  // حالُ المعالجة كما تكتبه القاعدة في counsel_cases.state — يُمرَّر إليها فتصفّي هي
  const STATES = [['', 'الكلّ'], ['قيد المعالجة', 'قيد المعالجة'], ['تمّت المعالجة', 'تمّت المعالجة']];
  // مدى الاستجابة: الأربعةُ التي يقبلها قيدُ counsel_sessions_response_check — والقاعدةُ ترفض غيرها
  const RESPONSES = ['تحسّنٌ ملحوظ', 'تحسّنٌ طفيف', 'السلوكُ مستمرّ', 'تراجُع'];

  const ui = { state: '', cases: [], caseId: null, card: null, resp: null, busy: false };
  const sess = V.sheet('sessModal');
  const rep = V.sheet('repModal');
  const degreeText = (n) => (n == null ? '' : 'الدرجة ' + ar(n));

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    ui.caseId = null; ui.card = null;
    $('caseCard').hidden = true; $('tlCard').hidden = true;
    // صندوقُه: نموذجُ الإحالة (٧) يصله سرًّا هنا وحدَه
    $('inboxCard').hidden = false;
    V.inbox($('inbox'), $('inboxTitle'));
    await loadBoard();
  }

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
    t.style.minWidth = '0'; // أربعةُ أعمدةٍ تسعها شاشةُ الجوّال بلا تمرير
    const hr = el('tr');
    for (const h of ['الطالب', 'المؤشّر', 'الرصدات', 'الحالة']) hr.appendChild(el('th', null, h));
    t.appendChild(hr);
    for (const c of ui.cases) {
      const tr = el('tr', 'click' + (c.case === ui.caseId ? ' on' : ''));
      tr.tabIndex = 0;
      const ind = (c.indicator || '') + ' — ' + (c.problem || '') + (c.degree != null ? ' · ' + degreeText(c.degree) : '');
      const stTd = el('td');
      stTd.appendChild(el('span', c.state === 'تمّت المعالجة' ? 'rs-state-done' : 'rs-state-open', c.state || ''));
      if (c.studied === false) stTd.appendChild(el('div', 'rs-meta', 'الدراسةُ لم تُكتب'));
      tr.append(el('td', null, c.student || ''), el('td', null, ind), el('td', null, String(c.records == null ? 0 : c.records)), stTd);
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
    tr.append(el('th', null, k), el('td', null, v == null || v === '' ? '—' : String(v)));
    t.appendChild(tr);
  }

  function renderCase() {
    const d = ui.card;
    const c = d.case || {};
    const st = d.student || {};
    const g = d.guardian || {};
    const p = d.problem || {};
    $('caseTitle').textContent = p.text || 'بطاقةُ الحالة';
    $('caseMeta').textContent = (st.name || '') + ' · فُتحت في ' + (c.opened_on || '—') + ' · ' + (c.state || '');

    // ما يعرفه النظام — عرضًا فقط
    const f = $('caseFacts');
    f.textContent = '';
    f.appendChild(el('div', 'rs-label', 'ما يعرفه النظام — عرضًا فقط'));
    const t = el('table', 'rs-table');
    t.style.minWidth = '0';
    kv(t, 'الطالب', (st.name || '') + (st.no ? ' — ' + st.no : ''));
    kv(t, 'وليُّ أمره', (g.name || '') + (g.relation ? ' — ' + g.relation : ''));
    kv(t, 'المشكلة', (p.text || '') + (p.degree != null ? ' · ' + degreeText(p.degree) : '') + (p.source ? ' · ' + p.source : ''));
    kv(t, 'المحسوم', d.deducted);
    kv(t, 'حالُ المعالجة', c.state);
    f.appendChild(t);
    const recs = d.records || [];
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, 'الرصدات (' + recs.length + ')'));
    const db = el('div', 'rs-dtb');
    for (const r of recs) {
      db.appendChild(el('div', null, ['الرصدة ' + (r.no == null ? '' : r.no), r.on, r.by ? 'دوّنها ' + r.by : null, r.place, r.note].filter(Boolean).join(' · ')));
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
    $('cwAt').textContent = c.written_at ? 'كُتبت في ' + ar(String(c.written_at).slice(0, 10)) : 'لم تُكتب بعد';
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
      kv(t2, 'رُفع في', r.issued_on || (r.created_at ? String(r.created_at).slice(0, 10) : null));
      kv(t2, 'عددُ الجلسات', r.sessions_n);
      kv(t2, 'المدى', r.span_ar);
      kv(t2, 'آخرُ تقديرٍ للاستجابة', r.last_resp);
      kv(t2, 'الحكم', r.judgement);
      kv(t2, 'الرأيُ الفنّيّ', r.opinion);
      kv(t2, 'التوصية', r.recommend);
      rb.append(t2, el('div', 'rs-note', 'رُفع التقريرُ للّجنة — ولا يُرفع مرّتين.'));
    } else if (ss.length) {
      rb.appendChild(btn('ارفع تقريرَ دراسة الحالة', 'rs-btn', openReport));
    } else {
      rb.appendChild(el('p', 'rs-meta', 'لا تقريرَ بلا جلسةِ متابعةٍ واحدةٍ على الأقلّ.'));
    }
    arabize(rb);

    const off = $('caseOff');
    off.textContent = '';
    off.append(notBuilt('خطّةُ تعديل السلوك'), notBuilt('محضرُ التوعية'), notBuilt('بنكُ العبارات'));
  }

  // الجلساتُ سجلٌّ .acts — الأحدثُ أعلى كما ترجعه القاعدة
  function sessionList(ss, label) {
    const ul = el('ul', 'rs-acts');
    for (const x of ss) {
      const li = el('li');
      const body = el('span');
      body.style.flex = '1';
      body.appendChild(el('b', null, (label ? label(x) + ' · ' : '') + 'الجلسةُ ' + (x.no == null ? '' : x.no) + (x.minutes ? ' · ' + x.minutes + ' دقيقة' : '')));
      const lg = el('div', 'rs-lgd');
      lg.append(el('i', 'k', 'ما نُوقش:'), el('i', null, x.discussed || ''),
        el('i', 'k', 'الاستجابة:'), el('i', null, x.response || ''),
        el('i', 'k', 'التالي:'), el('i', null, x.next || ''));
      body.appendChild(lg);
      li.append(el('i', 'rs-tick ok', '✓'), body, el('small', 'rs-who', x.on || ''));
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
    flash('ok', 'قُيّدت الجلسةُ ' + ((data && data.session) || ''));
    await loadCase();
    loadBoard();
  });

  // ---------- التقرير ----------
  function openReport() {
    // ما يُجمع آليًّا يُعرض كما في بطاقة الحالة — والحكمُ يضعه النظامُ عند الرفع
    const ss = ui.card.sessions || [];
    const a = $('repAuto');
    a.textContent = '';
    a.appendChild(el('div', null, 'عددُ الجلسات: ' + ss.length));
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
    $('tlSum').textContent = 'سجلُّ الملفّ (' + ar(evs.length) + ') — تنظر بصفة ' + ((data && data.as_ar) || '—');
    V.events(box, evs);
  }

  M.start({ screen: 'muwajjih', onChange: () => refresh() });
})();
