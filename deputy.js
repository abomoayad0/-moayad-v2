// مؤيّد · قرارات الوكيل — على نموذج المحاكي. يرى ويقرّر ولا يرصد:
// الإقفال (close_day) · إعادةُ الفتح بسببٍ مكتوب (reopen_day) · البتُّ في الأعذار (decide_excuse).
// وكلُّ عددٍ وحكمٍ من القاعدة:
// v2_day_summary · v2_day_classes · v2_close_day · v2_reopen_day · v2_day_log · v2_pending_excuses · v2_decide_excuse
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn } = V;

  const ui = { summary: null, classes: [], log: [], excuses: [], excErr: '', last: null };
  const can = (k) => !!(M.state.me && M.state.me.can && M.state.me.can[k]);

  // أسماءُ القيم كما تُخزَّن في absence_excuse_claims — للعرض فقط
  const BY_AR = { guardian: 'وليّ الأمر', student: 'الطالب' };
  const CHANNEL_AR = { in_person: 'حضوريًّا', whatsapp: 'واتساب', portal: 'بوّابة وليّ الأمر', guardian_portal: 'بوّابة وليّ الأمر', email: 'البريد' };
  const channelsAr = (s) => (!s || s === '—') ? '—' : s.split(' · ').map((c) => CHANNEL_AR[c] || c).join(' · ');
  const classLabel = (g, s) => { if (g == null) return ''; const c = ui.classes.find((k) => k.grade === g && k.section === s); return c ? c.label_ar : g + ' — ' + s; };
  const isStudy = () => !!ui.summary && (ui.summary.day_kind === 'study' || ui.summary.day_kind === 'exam');

  // أعدادٌ كما رجعت: [[عدد، اسم]]
  function legend(box, pairs) {
    box.textContent = '';
    for (const [n, label] of pairs) box.append(el('i', 'k', label + ':'), el('i', null, String(n == null ? '—' : n)));
  }

  // ---------- الجلب ----------
  async function refreshDay() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    const a = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, log] = await Promise.all([
      M.rpc('v2_day_summary', a, 'ملخّص اليوم'), M.rpc('v2_day_classes', a, 'فصول اليوم'), M.rpc('v2_day_log', a, 'ما وقع بعد الإقفال'),
    ]);
    const err = sum.error || cls.error || log.error;
    if (err) { showLoadErr('تعذّر جلب اليوم: ' + errText(err)); return; }
    ui.summary = (sum.data && sum.data[0]) || null;
    ui.classes = cls.data || [];
    ui.log = log.data || [];
    renderDay();
  }

  async function refreshExcuses() {
    if (!M.state.school) return;
    if (!can('decide_excuse')) { ui.excuses = []; ui.excErr = ''; renderExcuses(); return; }
    const { data, error } = await M.rpc('v2_pending_excuses', { p_school: M.state.school }, 'الأعذار المنتظرة');
    ui.excErr = error ? 'تعذّر جلب الأعذار: ' + errText(error) : '';
    ui.excuses = data || [];
    renderExcuses();
  }

  // ---------- ① اليوم ----------
  function renderDay() {
    V.renderRole();
    const s = ui.summary;
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, s.day_kind); else $('dates').textContent = '';
    $('noStudy').hidden = !s || isStudy();
    if (s && !isStudy()) $('noStudy').textContent = 'هذا اليوم ليس يومَ دراسة (' + (M.DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا رصدَ فيه ولا إقفال.';
    $('dayCard').hidden = !s || !isStudy();
    if (!s || !isStudy()) { $('logCard').hidden = true; return; }

    $('dayStatus').textContent = s.closed ? 'مقفَل' : (s.reopened ? 'أُعيد فتحُه' : 'مفتوح');
    $('dayStatus').className = 'rs-occ ' + (s.closed ? 'rs-state-done' : 'rs-state-open');
    $('unrecLine').textContent = s.unrecorded === 0 ? 'رُصد جميعُ المقيّدين (' + s.enrolled + ')' : s.unrecorded + ' طالبًا لم يُرصد بعد — من ' + s.enrolled;
    legend($('counts'), [[s.present, 'حاضر'], [s.absent, 'غائب'], [s.late, 'متأخّر'], [s.permitted, 'مستأذن'], [s.missed_assembly, 'تخلّف عن الاصطفاف']]);

    const oc = $('openClasses');
    oc.textContent = '';
    const open = ui.classes.filter((c) => !c.is_done);
    if (open.length) {
      oc.appendChild(el('div', 'rs-label', 'فصولٌ لم يكتمل رصدُها'));
      const p = el('div', 'rs-pick rs-off');
      for (const c of open) p.appendChild(el('span', null, c.label_ar + ' — لم يُرصد ' + c.unrecorded));
      oc.appendChild(p);
    }

    $('closeHint').textContent = s.closed ? 'اليومُ مقفَل. وإعادةُ فتحه لا تقع إلا بسببٍ مكتوبٍ يُقيَّد في السجلّ.'
      : s.unrecorded > 0 ? 'تنبيه: ' + s.unrecorded + ' طالبًا لم يُرصد بعد. راجع المساعدَ الإداريّ قبل الإقفال.' : 'رُصد الجميع، واليومُ جاهزٌ للإقفال.';
    const acts = $('dayActs');
    acts.textContent = '';
    if (!s.closed && can('close_day')) acts.appendChild(btn('أقفل اليوم', 'rs-btn', closeForm));
    if (s.closed && can('reopen_day')) acts.appendChild(btn('أعد فتحَ اليوم بسبب', 'rs-btn soft', reopenForm));
    const why = !s.closed && !can('close_day') ? M.lacks('إقفال اليوم') : s.closed && !can('reopen_day') ? M.lacks('إعادة فتح اليوم') : '';
    $('noCanDay').textContent = why;
    $('noCanDay').hidden = !why;

    renderResult();
    renderLog(s.closed);
    arabize($('dayCard'));
  }

  function renderResult() {
    const box = $('closeResult');
    box.textContent = '';
    const r = ui.last;
    box.hidden = !r || r.date !== M.state.date || r.school !== M.state.school;
    if (box.hidden) return;
    const d = r.data || {};
    box.appendChild(el('div', 'rs-label', r.kind === 'close' ? 'أُقفل اليوم — ما أرجعته القاعدة' : 'أُعيد فتحُ اليوم — ما نُقض'));
    const lg = el('div', 'rs-lgd');
    legend(lg, r.kind === 'close'
      ? [[d.enrolled, 'المقيّدون'], [d.recorded, 'المرصودون'], [d.absent, 'غياب'], [d.late, 'تأخّر'], [d.derived, 'مشتقٌّ من الحصص'], [d.unrecorded, 'لم يُرصد'], [d.events, 'وقائعُ وبلاغات']]
      : [[d.behavior_voided, 'رصداتٌ سلوكيّةٌ نُقضت'], [d.cases_voided, 'حالاتُ غيابٍ نُقضت'], [d.deductions_restored, 'حسوماتٌ رُدّت'], [d.events_cancelled, 'بلاغاتٌ أُلغيت']]);
    box.appendChild(lg);
  }

  // ما وقع بعد الإقفال — اسمًا اسمًا، ولا يُعرض قبل الإقفال
  function renderLog(closed) {
    $('logCard').hidden = !closed;
    const box = $('log');
    box.textContent = '';
    if (!closed) return;
    if (!ui.log.length) box.appendChild(el('p', 'rs-empty', 'لم يقع حسمٌ ولا تصعيدٌ ولا بلاغٌ في هذا اليوم.'));
    for (const e of ui.log) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, e.student_name), el('span', 'rs-who' + (e.needs_action ? ' rs-state-open' : ''), e.title_ar || ''));
      f.appendChild(hd);
      f.appendChild(el('p', null, [e.class_ar || classLabel(e.grade, e.section), e.body_ar].filter(Boolean).join(' · ')));
      if (e.needs_action) f.appendChild(el('p', null, 'يحتاج إجراءً: ' + (e.action_ar || '—')));
      f.appendChild(el('p', 'rs-meta', 'القنوات: ' + channelsAr(e.channels)));
      box.appendChild(f);
    }
    arabize(box);
  }

  function closeForm() {
    const s = ui.summary;
    V.form({
      title: 'إقفالُ اليوم',
      what: 'المقيّدون ' + s.enrolled + ' · غائب ' + s.absent + ' · متأخّر ' + s.late + ' · مستأذن ' + s.permitted + ' · لم يُرصد ' + s.unrecorded +
        (s.unrecorded > 0 ? ' — وسيُقفل اليومُ وهم كذلك.' : '') + ' وبعد الإقفال يقع الحسمُ والتصعيدُ والبلاغات، ولا يُعدَّل السجلُّ إلا بإعادة فتحٍ بسببٍ مكتوب.',
      fields: [],
      ok: 'أقفل اليوم',
      onOk: async () => {
        const { data, error } = await M.rpc('v2_close_day', { p_school: M.state.school, p_date: M.state.date }, 'إقفال اليوم');
        if (error) return error;
        ui.last = { kind: 'close', date: M.state.date, school: M.state.school, data: (data && data[0]) || {} };
        V.flash('ok', 'أُقفل اليوم');
        await refreshDay();
        return null;
      },
    });
  }

  function reopenForm() {
    V.form({
      title: 'إعادةُ فتح اليوم',
      what: 'سيُنقض ما ترتّب على الإقفال: الرصداتُ السلوكيّةُ الآليّة، والحسومات، وحالاتُ الغياب، والبلاغاتُ غيرُ المسلَّمة. ولا يُمحى شيء — يُقيَّد بسببه.',
      fields: [{ key: 'why', type: 'textarea', label: 'السببُ كما سيُقيَّد في السجلّ — إلزاميّ' }],
      ok: 'أعد الفتح',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_reopen_day', { p_school: M.state.school, p_date: M.state.date, p_reason: v.why || null }, 'إعادة فتح اليوم');
        if (error) return error;
        ui.last = { kind: 'reopen', date: M.state.date, school: M.state.school, data: (data && data[0]) || {} };
        V.flash('ok', 'أُعيد فتحُ اليوم');
        await refreshDay();
        return null;
      },
    });
  }

  // ---------- ② الأعذار ----------
  function renderExcuses() {
    $('excuseCard').hidden = false;
    const box = $('excuses');
    box.textContent = '';
    if (!can('decide_excuse')) { $('excuseCount').textContent = ''; box.appendChild(el('p', 'rs-meta nocan', M.lacks('البتّ في الأعذار'))); return; }
    if (ui.excErr) { $('excuseCount').textContent = ''; box.appendChild(el('div', 'notice err', ui.excErr)); return; }
    $('excuseCount').textContent = String(ui.excuses.length);
    if (!ui.excuses.length) box.appendChild(el('p', 'rs-empty', 'لا أعذارَ منتظرة.'));
    for (const x of ui.excuses) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, x.student_name), el('span', 'rs-who', x.days + (x.days === 1 ? ' يوم' : ' أيّام')));
      f.appendChild(hd);
      const span = x.from_date === x.to_date ? x.from_h + ' هـ' : 'من ' + x.from_h + ' إلى ' + x.to_h + ' هـ';
      f.appendChild(el('p', null, [x.class_ar || classLabel(x.grade, x.section), 'الغياب: ' + span].join(' · ')));
      f.appendChild(el('p', null, 'قُدّم ' + x.submitted_h + ' هـ · من ' + (BY_AR[x.by_whom] || x.by_whom) + ' · ' + (CHANNEL_AR[x.channel] || x.channel)));
      f.appendChild(el('p', null, 'السبب: ' + (x.reason_text || '—') + ' · ' + (x.attachment_name ? 'المرفق: ' + x.attachment_name : 'بلا مرفق')));
      f.appendChild(el('p', 'rs-meta', 'أيّامُ العمل المستغرقة ' + x.working_days_used + ' — ' + x.window_verdict));
      const row = el('div', 'rs-row');
      row.append(btn('اقبله', 'rs-btn', () => decideForm(x, true)), btn('ردّه بسبب', 'rs-btn ghost', () => decideForm(x, false)));
      f.appendChild(row);
      box.appendChild(f);
    }
    arabize($('excuseCard'));
  }

  function decideForm(x, accept) {
    V.form({
      title: accept ? 'قبولُ العذر' : 'ردُّ العذر',
      what: x.student_name + ' — ' + x.days + (x.days === 1 ? ' يوم' : ' أيّام') + ' · ' + (x.reason_text || ''),
      fields: [
        { key: 'note', type: 'textarea', label: accept ? 'ملاحظة (اختياريّة)' : 'سببُ الردّ — إلزاميّ', rows: 2 },
        { key: 'ext', type: 'pick', label: 'المهلة', items: [['no', 'في مهلتها'], ['yes', 'بتمديد المهلة بقرار مدير المدرسة (م٣١ بند ٦)']], value: 'no' },
      ],
      ok: accept ? 'اقبل العذر' : 'اردد العذر',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_decide_excuse', { p_claim: x.claim_id, p_accept: accept, p_note: v.note || null, p_principal_ext: v.ext === 'yes' }, 'البتّ في العذر');
        if (error) return error;
        // ما أرجعته القاعدةُ كما هو: مفاتيحُه وقيمُه
        const r = data || {};
        const parts = Object.keys(r).map((k) => k.replace(/_/g, ' ') + ' ' + (r[k] == null ? '—' : r[k]));
        V.flash('ok', (accept ? 'قُبل العذر' : 'رُدّ العذر') + (parts.length ? ' · ' + parts.join(' · ') : ''));
        await Promise.all([refreshExcuses(), refreshDay()]);
        return null;
      },
    });
  }

  M.start({
    screen: 'deputy',
    onChange: (why) => (why === 'date' ? refreshDay() : Promise.all([refreshDay(), refreshExcuses()])),
  });
})();
