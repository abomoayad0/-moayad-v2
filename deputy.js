// مؤيّد · قرارات الوكيل — وكيل شؤون الطلاب يرى ويقرّر ولا يرصد.
// الإقفال وإعادة الفتح والبتّ في الأعذار. وكل عدد وحكم من القاعدة:
// v2_day_summary · v2_day_classes · v2_close_day · v2_reopen_day · v2_day_log
// v2_pending_excuses · v2_decide_excuse
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, el, toast, errText, showLoadErr } = M;

  const ui = { summary: null, classes: [], log: [], excuses: [], lastResult: null };

  // أسماء القيم كما تُخزَّن في absence_excuse_claims — للعرض فقط
  const BY_AR = { guardian: 'ولي الأمر', student: 'الطالب' };
  const CHANNEL_AR = {
    in_person: 'حضورياً', whatsapp: 'واتساب', portal: 'بوابة ولي الأمر',
    guardian_portal: 'بوابة ولي الأمر', email: 'البريد',
  };
  // القنوات تأتي من v2_day_log نصّاً مفصولاً بـ « · »
  function channelsAr(s) {
    if (!s || s === '—') return '—';
    return s.split(' · ').map((c) => CHANNEL_AR[c] || c).join(' · ');
  }

  // اسم الفصل كما تسمّيه القاعدة (label_ar من v2_day_classes)
  function classLabel(grade, section) {
    if (grade == null) return '';
    const c = ui.classes.find((k) => k.grade === grade && k.section === section);
    return c ? c.label_ar : grade + ' — ' + section;
  }

  // نافذة تأكيد تُرجع وعداً بقيمة الزرّ
  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  function countsBox(pairs, extraCls) {
    const box = el('div', 'counts' + (extraCls ? ' ' + extraCls : ''));
    for (const [n, label, red] of pairs) {
      const d = el('div', red ? 'red' : '');
      d.append(el('b', null, String(n)), el('span', null, label));
      box.appendChild(d);
    }
    return box;
  }

  // ---------- الجلب ----------
  async function refreshDay() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    const args = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, log] = await Promise.all([
      sb.rpc('v2_day_summary', args),
      sb.rpc('v2_day_classes', args),
      sb.rpc('v2_day_log', args),
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
    if (!M.state.me.can.decide_excuse) { $('excusePanel').hidden = true; return; }
    const { data, error } = await sb.rpc('v2_pending_excuses', { p_school: M.state.school });
    if (error) { showLoadErr('تعذّر جلب الأعذار: ' + errText(error)); return; }
    ui.excuses = data || [];
    renderExcuses();
  }

  // ---------- ملخّص اليوم والإقفال ----------
  function renderDay() {
    const s = ui.summary;
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, s.day_kind);
    else $('dates').textContent = '';

    const isStudy = !!s && (s.day_kind === 'study' || s.day_kind === 'exam');
    $('noStudy').hidden = !s || isStudy;
    if (s && !isStudy) {
      $('noStudy').textContent = 'هذا اليوم ليس يوم دراسة (' + (M.DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا رصد فيه ولا إقفال.';
    }
    $('summaryPanel').hidden = !s || !isStudy;
    $('closePanel').hidden = !s || !isStudy;
    if (!s || !isStudy) { $('logPanel').hidden = true; return; }

    const st = $('dayStatus');
    st.textContent = s.closed ? 'مقفَل' : (s.reopened ? 'أُعيد فتحه' : 'مفتوح');
    st.className = 'chip ' + (s.closed ? 'c-closed' : (s.reopened ? 'c-reopened' : 'c-open'));

    // من لم يُرصد — بارز بالأحمر ولا يُطوى
    const u = $('unrecLine');
    u.classList.toggle('zero', s.unrecorded === 0);
    u.textContent = s.unrecorded === 0
      ? 'رُصد جميع المقيّدين (' + s.enrolled + ')'
      : s.unrecorded + ' طالباً لم يُرصد بعد — من ' + s.enrolled;

    $('cPresent').textContent = s.present;
    $('cAbsent').textContent = s.absent;
    $('cLate').textContent = s.late;
    $('cPermitted').textContent = s.permitted;
    $('cMissed').textContent = s.missed_assembly;

    // الفصول التي لم تكتمل — حكم الاكتمال is_done من القاعدة
    const oc = $('openClasses');
    oc.textContent = '';
    const open = ui.classes.filter((c) => !c.is_done);
    if (open.length) {
      oc.appendChild(el('div', 'oc-title', 'فصول لم يكتمل رصدها:'));
      for (const c of open) oc.appendChild(el('span', 'oc', c.label_ar + ' — لم يُرصد ' + c.unrecorded));
    }

    // الإقفال: يظهر زرّه في اليوم المفتوح، وإعادة الفتح في المقفَل — كلٌّ بما يملكه في can
    const can = M.state.me.can;
    $('closeBtn').hidden = s.closed || !can.close_day;
    $('reopenBox').hidden = !s.closed || !can.reopen_day;
    $('closeHint').textContent = s.closed
      ? 'اليوم مقفَل. وإعادة فتحه لا تقع إلا بسبب مكتوب يُقيَّد في السجل.'
      : (s.unrecorded > 0
        ? 'تنبيه: ' + s.unrecorded + ' طالباً لم يُرصد بعد. راجع المساعد الإداري قبل الإقفال.'
        : 'رُصد الجميع، واليوم جاهز للإقفال.');
    $('closeHint').classList.toggle('warn', !s.closed && s.unrecorded > 0);

    renderResult();
    renderLog(s.closed);
  }

  function renderResult() {
    const box = $('closeResult');
    box.textContent = '';
    const r = ui.lastResult;
    box.hidden = !r || r.date !== M.state.date || r.school !== M.state.school;
    if (box.hidden) return;
    if (r.kind === 'close') {
      box.appendChild(el('h3', 'res-h', 'أُقفل اليوم — ما أرجعته القاعدة:'));
      box.appendChild(countsBox([
        [r.data.enrolled, 'المقيّدون'], [r.data.recorded, 'المرصودون'],
        [r.data.absent, 'غياب'], [r.data.late, 'تأخر'], [r.data.derived, 'مشتق من الحصص'],
        [r.data.unrecorded, 'لم يُرصد', r.data.unrecorded > 0], [r.data.events, 'وقائع وبلاغات'],
      ], 'res'));
    } else {
      box.appendChild(el('h3', 'res-h', 'أُعيد فتح اليوم — ما نُقض:'));
      box.appendChild(countsBox([
        [r.data.behavior_voided, 'رصدات سلوكية نُقضت'], [r.data.cases_voided, 'حالات غياب نُقضت'],
        [r.data.deductions_restored, 'حسومات رُدّت'], [r.data.events_cancelled, 'بلاغات أُلغيت'],
      ], 'res'));
    }
  }

  // ما وقع بعد الإقفال — اسماً اسماً، ولا يُعرض قبل الإقفال
  function renderLog(closed) {
    $('logPanel').hidden = !closed;
    const box = $('log');
    box.textContent = '';
    if (!closed) return;
    if (ui.log.length === 0) {
      box.appendChild(el('div', 'empty', 'لم يقع حسم ولا تصعيد ولا بلاغ في هذا اليوم.'));
      return;
    }
    for (const e of ui.log) {
      const c = el('div', 'ev' + (e.needs_action ? ' act' : ''));
      const top = el('div', 'row1');
      const who = el('div');
      who.append(el('div', 'name', e.student_name),
        el('div', 'meta', classLabel(e.grade, e.section)));
      top.append(who, el('span', 'badge b-ev', e.title_ar));
      c.appendChild(top);
      if (e.body_ar) c.appendChild(el('div', 'detail', e.body_ar));
      if (e.needs_action) c.appendChild(el('div', 'need', 'يحتاج إجراءً: ' + (e.action_ar || '—')));
      c.appendChild(el('div', 'meta', 'القنوات: ' + channelsAr(e.channels)));
      box.appendChild(c);
    }
  }

  $('closeBtn').addEventListener('click', async () => {
    const s = ui.summary;
    if (!s) return;
    const body = $('confirmCloseBody');
    body.textContent = '';
    body.appendChild(countsBox([
      [s.enrolled, 'المقيّدون'], [s.absent, 'غائب'], [s.late, 'متأخر'],
      [s.permitted, 'مستأذن'], [s.unrecorded, 'لم يُرصد', s.unrecorded > 0],
    ]));
    if (s.unrecorded > 0) {
      body.appendChild(el('p', 'warn', s.unrecorded + ' طالباً لم يُرصد بعد، وسيُقفل اليوم وهم كذلك.'));
    }
    if (await ask($('confirmClose')) !== 'ok') return;

    $('closeBtn').disabled = true;
    const { data, error } = await sb.rpc('v2_close_day', { p_school: M.state.school, p_date: M.state.date });
    $('closeBtn').disabled = false;
    if (error) { toast('لم يُقفل اليوم:\n' + errText(error)); return; }
    ui.lastResult = { kind: 'close', date: M.state.date, school: M.state.school, data: (data && data[0]) || {} };
    toast('أُقفل اليوم.', true);
    await refreshDay();
  });

  $('reopenReason').addEventListener('input', () => {
    $('reopenBtn').disabled = $('reopenReason').value.trim() === '';
  });

  $('reopenBtn').addEventListener('click', async () => {
    const reason = $('reopenReason').value.trim();
    if (!reason) return;
    $('confirmReopenReason').textContent = 'السبب: ' + reason;
    if (await ask($('confirmReopen')) !== 'ok') return;

    $('reopenBtn').disabled = true;
    const { data, error } = await sb.rpc('v2_reopen_day', {
      p_school: M.state.school, p_date: M.state.date, p_reason: reason,
    });
    if (error) {
      $('reopenBtn').disabled = false;
      toast('لم يُعد فتح اليوم:\n' + errText(error));
      return;
    }
    $('reopenReason').value = '';
    ui.lastResult = { kind: 'reopen', date: M.state.date, school: M.state.school, data: (data && data[0]) || {} };
    toast('أُعيد فتح اليوم.', true);
    await refreshDay();
  });

  // ---------- الأعذار ----------
  function renderExcuses() {
    $('excusePanel').hidden = false;
    const box = $('excuses');
    box.textContent = '';
    $('excuseCount').textContent = ui.excuses.length;
    $('excuseCount').className = 'chip ' + (ui.excuses.length ? 'c-closed' : 'c-open');
    if (ui.excuses.length === 0) {
      box.appendChild(el('div', 'empty', 'لا أعذار منتظرة.'));
      return;
    }
    for (const x of ui.excuses) box.appendChild(excuseCard(x));
  }

  function period(x) {
    const p = el('span');
    if (x.from_date === x.to_date) {
      p.append(M.ltr(x.from_h), ' هـ (', M.ltr(x.from_date), ' م)');
    } else {
      p.append('من ', M.ltr(x.from_h), ' إلى ', M.ltr(x.to_h), ' هـ (', M.ltr(x.from_date), ' – ', M.ltr(x.to_date), ' م)');
    }
    return p;
  }

  function excuseCard(x) {
    const c = el('div', 'st exc');
    const top = el('div', 'row1');
    const who = el('div');
    who.append(el('div', 'name', x.student_name),
      el('div', 'meta', classLabel(x.grade, x.section)));
    top.append(who, el('span', 'badge b-late', x.days + (x.days === 1 ? ' يوم' : ' أيام')));
    c.appendChild(top);

    const d1 = el('div', 'detail');
    d1.append('الغياب: ', period(x));
    c.appendChild(d1);

    const d2 = el('div', 'detail');
    d2.append('قُدّم ', M.ltr(x.submitted_h), ' هـ (', M.ltr(x.submitted_on), ' م) · من ',
      BY_AR[x.by_whom] || x.by_whom, ' · ', CHANNEL_AR[x.channel] || x.channel);
    c.appendChild(d2);

    c.appendChild(el('div', 'detail', 'السبب: ' + (x.reason_text || '—')));
    c.appendChild(el('div', x.attachment_name ? 'detail' : 'detail red',
      x.attachment_name ? 'المرفق: ' + x.attachment_name : 'بلا مرفق'));
    c.appendChild(el('div', 'verdict', 'أيام العمل المستغرقة ' + x.working_days_used + ' — ' + x.window_verdict));

    const acts = el('div', 'acts two');
    const ok = el('button', 'a-accept', 'قبول');
    ok.type = 'button';
    ok.addEventListener('click', () => decide(x, true));
    const no = el('button', 'a-reject', 'ردّ بسبب');
    no.type = 'button';
    no.addEventListener('click', () => decide(x, false));
    acts.append(ok, no);
    c.appendChild(acts);
    return c;
  }

  function updateDecideOk(accept) {
    $('decideOk').disabled = !accept && $('decideNote').value.trim() === '';
  }

  async function decide(x, accept) {
    $('decideTitle').textContent = accept ? 'قبول العذر' : 'ردّ العذر';
    $('decideWho').textContent = x.student_name + ' — ' + x.days + (x.days === 1 ? ' يوم' : ' أيام') + ' · ' + x.reason_text;
    $('decideNoteLabel').textContent = accept ? 'ملاحظة (اختيارية)' : 'سبب الردّ — إلزامي';
    $('decideNote').value = '';
    $('decideNote').oninput = () => updateDecideOk(accept);
    $('decideExt').checked = false;
    $('decideOk').textContent = accept ? 'اقبل العذر' : 'اردد العذر';
    $('decideOk').className = accept ? 'btn-accept' : 'btn-danger';
    updateDecideOk(accept);
    if (await ask($('decideDlg')) !== 'ok') return;

    const note = $('decideNote').value.trim();
    const { data, error } = await sb.rpc('v2_decide_excuse', {
      p_claim: x.claim_id, p_accept: accept, p_note: note || null, p_principal_ext: $('decideExt').checked,
    });
    if (error) { toast('لم يُبتّ في العذر:\n' + errText(error)); return; }
    const r = data || {};
    toast((accept ? 'قُبل العذر' : 'رُدّ العذر') +
      ' · أيام الغياب ' + (r['أيام_الغياب'] ?? '—') +
      ' · درجات رُدّت ' + (r['درجات_رُدّت'] ?? '—') +
      ' · حالات أُوقف تصعيدها ' + (r['حالات_أُوقف_تصعيدها'] ?? '—'), true);
    await refreshExcuses();
  }

  M.start({
    screen: 'deputy',
    onChange: (why) => {
      if (why === 'date') return refreshDay();
      return Promise.all([refreshDay(), refreshExcuses()]);
    },
  });
})();
