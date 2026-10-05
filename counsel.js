// مؤيّد · الموجّه الطلابي — مؤشّرُ متابعة الحالات · حالةٌ مفتوحة.
// v2_counsel_board · v2_case_card · v2_case_write · v2_session_add · v2_case_report · v2_student_timeline
// 🔒 ما هنا سرٌّ عند الموجّه: لا يُمرَّر منه شيءٌ إلى شاشةٍ أخرى. والقاعدةُ تحرسه ورفضُها يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'counsel';

  const ui = { school: null, state: '', cases: [], caseId: null, card: null };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }
  function btn(cls, text, fn) {
    const b = el('button', cls, text);
    b.type = 'button';
    b.addEventListener('click', fn);
    return b;
  }

  // ---------- المؤشّر ----------
  async function loadBoard() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_counsel_board', { p_school: ui.school, p_state: ui.state || null }, 'مؤشّر متابعة الحالات');
    if (error) { showLoadErr(errText(error)); ui.cases = []; renderBoard(); return; }
    ui.cases = data || [];
    renderBoard();
  }

  function renderBoard() {
    for (const b of document.querySelectorAll('#fState button')) b.setAttribute('aria-pressed', String(b.dataset.s === ui.state));
    const box = $('cases');
    box.textContent = '';
    if (!ui.cases.length) { box.appendChild(el('div', 'empty', 'لا حالات.')); return; }
    for (const c of ui.cases) {
      const r = el('div', 'ev kcase ' + (c.state === 'تمّت المعالجة' ? 'k-done' : 'k-open'));
      const top = el('div', 'row1');
      top.append(el('div', 'name', c.student || ''), el('span', 'badge kstate', c.state || ''));
      r.appendChild(top);
      r.appendChild(el('div', 'meta', 'المؤشّر: ' + (c.indicator || '—') + ' · ' + (c.problem || '') +
        (c.degree != null ? ' · الدرجة ' + c.degree : '') + ' · الرصدات: ' + (c.records == null ? 0 : c.records)));
      r.appendChild(el('div', 'meta', 'فُتحت في ' + (c.opened_on || '—')));
      if (c.studied === false) r.appendChild(el('div', 'detail red', 'دراسةُ الحالة لم تُكتب'));
      r.appendChild(el('div', 'meta', 'جلساتُ المتابعة: ' + (c.sessions || 0) + (c.reported ? ' · رُفع التقريرُ للّجنة' : '')));
      r.appendChild(btn('btn-ghost wide', 'افتح الحالة', () => openCase(c.case)));
      box.appendChild(r);
    }
  }

  // ---------- الحالة ----------
  async function openCase(id) {
    ui.caseId = id;
    $('boardView').hidden = true;
    $('caseView').hidden = false;
    window.scrollTo(0, 0);
    await loadCase();
  }

  async function loadCase() {
    const box = $('caseBox');
    box.textContent = '';
    box.appendChild(el('div', 'meta', 'جارٍ جلب الحالة…'));
    const card = await M.rpc('v2_case_card', { p_case: ui.caseId }, 'بطاقة الحالة');
    box.textContent = '';
    if (card.error) { box.appendChild(el('div', 'notice err', errText(card.error))); return; }
    ui.card = card.data;
    renderCase();
    const sid = ui.card && ui.card.case && ui.card.case.student_id;
    if (sid) loadTimeline(sid);
  }

  function kv(t, label, value) {
    const tr = el('tr');
    tr.append(el('th', null, label), el('td', null, value == null || value === '' ? '—' : String(value)));
    t.appendChild(tr);
  }

  function renderCase() {
    const d = ui.card || {};
    const c = d.case || {};
    const box = $('caseBox');
    box.textContent = '';

    // ١ · ما يعرفه النظام
    const s1 = el('section', 'panel');
    s1.appendChild(el('h2', 'ph', 'ما يعرفه النظام'));
    const t = el('table', 'kvt');
    const st = d.student || {};
    const g = d.guardian || {};
    const p = d.problem || {};
    kv(t, 'الطالب', (st.name || '') + (st.no ? ' — ' + st.no : ''));
    kv(t, 'وليّ أمره', (g.name || '') + (g.relation ? ' — ' + g.relation : ''));
    kv(t, 'المشكلة', (p.text || '') + (p.degree != null ? ' · الدرجة ' + p.degree : '') + (p.source ? ' · ' + p.source : ''));
    kv(t, 'المحسوم', d.deducted);
    kv(t, 'حالُ المعالجة', c.state);
    kv(t, 'فُتحت في', c.opened_on);
    s1.appendChild(t);
    s1.appendChild(el('h3', 'grp', 'الرصدات'));
    const recs = d.records || [];
    if (!recs.length) s1.appendChild(el('div', 'empty', 'لا رصدات مرتبطة.'));
    for (const r of recs) {
      s1.appendChild(el('div', 'meta', [r.on || r.on_date || r.date, r.no != null ? 'رقم ' + r.no : null, r.by ? 'دوّنها ' + r.by : null, r.place].filter(Boolean).join(' · ')));
    }
    box.appendChild(s1);

    // ٢ · ما يكتبه الموجّه
    const s2 = el('section', 'panel');
    s2.appendChild(el('h2', 'ph', 'دراسةُ الحالة'));
    const fields = [
      ['student_view', 'تفسيرُ الطالب للمشكلة — بلسانه'],
      ['observed', 'ما لاحظتَه أنت'],
      ['factors', 'العواملُ التي تراها'],
      ['plan_ar', 'التدخّلُ المخطَّط'],
    ];
    const ctl = {};
    for (const [k, label] of fields) {
      const id = 'cw_' + k;
      const l = el('label', null, label + ' — إلزامي');
      l.htmlFor = id;
      const a = document.createElement('textarea');
      a.id = id;
      a.rows = 3;
      a.value = c[k] || '';
      ctl[k] = a;
      s2.append(l, a);
    }
    if (d.note) s2.appendChild(el('p', 'hint', d.note));
    if (c.written_at) s2.appendChild(el('div', 'meta', 'كُتبت في ' + String(c.written_at).slice(0, 10)));
    const save = btn('btn-main', c.written_at ? 'احفظ تعديل الدراسة' : 'احفظ الدراسة', async () => {
      const { error } = await M.rpc('v2_case_write', {
        p_case: ui.caseId, p_student_view: ctl.student_view.value.trim(), p_observed: ctl.observed.value.trim(),
        p_factors: ctl.factors.value.trim(), p_plan: ctl.plan_ar.value.trim(),
      }, 'دراسة الحالة');
      if (error) { toast('لم تُحفظ الدراسة:\n' + errText(error)); return; }
      toast('حُفظت دراسةُ الحالة.', true);
      loadCase();
    });
    const ready = () => { save.disabled = fields.some(([k]) => !ctl[k].value.trim()); };
    for (const [k] of fields) ctl[k].addEventListener('input', ready);
    ready();
    s2.appendChild(save);
    box.appendChild(s2);

    // جلسات المتابعة — الأحدث أعلى
    const s3 = el('section', 'panel');
    s3.appendChild(el('h2', 'ph', 'جلساتُ المتابعة'));
    if (c.written_at) s3.appendChild(btn('btn-ghost wide', 'أضف جلسة', addSession));
    else s3.appendChild(el('p', 'hint nocan', 'لا تُفتح جلسةٌ قبل أن تُكتب دراسةُ الحالة.'));
    const sessions = (d.sessions || []).slice().sort((a, b) => (b.no || 0) - (a.no || 0));
    if (!sessions.length) s3.appendChild(el('div', 'empty', 'لا جلسات بعد.'));
    for (const x of sessions) {
      const r = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', 'الجلسة ' + x.no + ' · ' + (x.on || '') + (x.minutes ? ' · ' + x.minutes + ' دقيقة' : '')), el('span', 'badge', x.response || ''));
      r.appendChild(top);
      r.appendChild(el('div', 'detail', 'ما نُوقش: ' + (x.discussed || '')));
      r.appendChild(el('div', 'detail', 'الخطوة التالية: ' + (x.next || '')));
      s3.appendChild(r);
    }
    box.appendChild(s3);

    // التقرير
    const s4 = el('section', 'panel');
    s4.appendChild(el('h2', 'ph', 'تقريرُ دراسة الحالة'));
    const rep = d.report;
    if (rep) {
      const t2 = el('table', 'kvt');
      kv(t2, 'رُفع في', rep.issued_on);
      kv(t2, 'عدد الجلسات', rep.sessions_n);
      kv(t2, 'المدى', rep.span_ar);
      kv(t2, 'آخرُ تقديرٍ للاستجابة', rep.last_resp);
      kv(t2, 'الحكم', rep.judgement);
      kv(t2, 'الرأيُ الفنّيّ', rep.opinion);
      kv(t2, 'التوصية', rep.recommend);
      s4.appendChild(t2);
      s4.appendChild(el('div', 'meta', 'رُفع التقريرُ للّجنة — ولا يُرفع مرّتين.'));
    } else if (sessions.length) {
      s4.appendChild(btn('btn-main', 'ارفع التقرير للّجنة', report));
    } else {
      s4.appendChild(el('p', 'hint nocan', 'لا تقريرَ بلا جلسةِ متابعةٍ واحدةٍ على الأقلّ.'));
    }
    box.appendChild(s4);

    const s5 = el('section', 'panel');
    s5.id = 'tlBox';
    box.appendChild(s5);
  }

  async function loadTimeline(sid) {
    const { data, error } = await M.rpc('v2_student_timeline', { p_student: sid, p_as: 'counselor' }, 'السجلّ الزمنيّ');
    const box = $('tlBox');
    if (!box) return;
    box.textContent = '';
    box.appendChild(el('h2', 'ph', 'السجلّ الزمنيّ للطالب'));
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    box.appendChild(el('div', 'meta', 'تنظر بصفة: ' + ((data && (data.as_ar || data.as)) || '—')));
    const ev = (data && data.events) || [];
    if (!ev.length) box.appendChild(el('div', 'empty', 'لا أحداث.'));
    for (const e of ev) {
      const r = el('div', 'ev');
      r.appendChild(el('div', 'name', (e.on || '') + ' · ' + (e.title || '')));
      if (e.body) r.appendChild(el('div', 'meta', e.body));
      box.appendChild(r);
    }
  }

  async function addSession() {
    $('sOn').value = new Date().toISOString().slice(0, 10);
    $('sMin').value = '';
    $('sDisc').value = '';
    $('sNext').value = '';
    $('sResp').value = '';
    $('sOk').disabled = true;
    if (await ask($('sessDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_session_add', {
      p_case: ui.caseId, p_on: $('sOn').value || null, p_minutes: $('sMin').value ? Number($('sMin').value) : null,
      p_discussed: $('sDisc').value.trim(), p_response: $('sResp').value, p_next: $('sNext').value.trim(),
    }, 'جلسة متابعة');
    if (error) { toast('لم تُقيَّد الجلسة:\n' + errText(error)); return; }
    toast('قُيّدت الجلسة ' + ((data && data.session) || '') + '.', true);
    loadCase();
  }

  async function report() {
    // ما يُجمع آليًّا يُعرض قبل الإرسال من بطاقة الحالة كما هو — والحكمُ يضعه النظام عند الرفع
    const ss = (ui.card.sessions || []).slice().sort((a, b) => (a.no || 0) - (b.no || 0));
    const auto = $('repAuto');
    auto.textContent = '';
    auto.appendChild(el('div', null, 'عددُ الجلسات: ' + ss.length));
    if (ss.length) {
      auto.appendChild(el('div', null, 'من ' + ss[0].on + ' إلى ' + ss[ss.length - 1].on));
      auto.appendChild(el('div', null, 'آخرُ تقديرٍ للاستجابة: ' + (ss[ss.length - 1].response || '—')));
    }
    auto.appendChild(el('div', null, 'والحكمُ يضعه النظامُ عند الرفع.'));
    $('rOpinion').value = '';
    $('rRec').value = '';
    $('rOk').disabled = true;
    if (await ask($('repDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_case_report', {
      p_case: ui.caseId, p_opinion: $('rOpinion').value.trim(), p_recommend: $('rRec').value.trim(),
    }, 'تقرير دراسة الحالة');
    if (error) { toast('لم يُرفع التقرير:\n' + errText(error)); return; }
    toast('رُفع التقرير — الحكم: ' + ((data && data.judgement) || ''), true);
    loadCase();
  }

  // ---------- الأحداث ----------
  for (const b of document.querySelectorAll('#fState button')) {
    b.addEventListener('click', () => { ui.state = b.dataset.s; loadBoard(); });
  }
  $('backBoard').addEventListener('click', () => {
    ui.caseId = null;
    ui.card = null;
    $('caseView').hidden = true;
    $('boardView').hidden = false;
    loadBoard();
  });
  const sReady = () => { $('sOk').disabled = !$('sDisc').value.trim() || !$('sNext').value.trim() || !$('sResp').value; };
  $('sResp').addEventListener('change', sReady);
  $('sDisc').addEventListener('input', sReady);
  $('sNext').addEventListener('input', sReady);
  const rReady = () => { $('rOk').disabled = !$('rOpinion').value.trim() || !$('rRec').value.trim(); };
  $('rOpinion').addEventListener('input', rReady);
  $('rRec').addEventListener('input', rReady);
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  // ---------- الدخول ----------
  async function enter() {
    let me;
    try { await M.defaultRole(); me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    M.state.me = me;
    // تبديل الصفة يعيد الشاشة من أوّلها — فلا يبقى على الشاشة ما فُتح بصفةٍ أخرى
    M.renderHeader(me, async (r) => { const m = await M.actAs(r); if (m) location.reload(); });
    M.renderNav(me, 'counsel');
    if (!me) { M.gate('حسابك غير مسند إلى منسوب في مؤيّد.'); return; }
    const cur = (me.roles || []).find((r) => r.is_current === true && r.school_id);
    const schools = (me.schools || []).filter((x) => !cur || x.id === cur.school_id);
    if (!schools.length) { M.gate('لا مدرسة مسندة لحسابك.'); return; }
    ui.school = schools[0].id;
    $('kView').hidden = false;
    await loadBoard();
  }

  (async () => {
    const { data } = await M.sb.auth.getSession();
    if (!data.session) { location.replace('./'); return; }
    await enter();
  })();
})();
