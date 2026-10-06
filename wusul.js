// مؤيّد · الوصولُ والاصطفافُ والانصراف — شاشةٌ واحدةٌ بثلاثة أبواب على نموذج المحاكي.
// الاصطفاف (record_assembly) · الوصولُ المتأخّر (record_arrival) · تأخّرُ الانصراف (record_dismissal) — كلُّ بابٍ بمفتاحه في can.
// الأعدادُ والحالاتُ والدقائقُ والعتباتُ والإجراءُ كلُّها من القاعدة:
// v2_day_summary · v2_day_classes · v2_day_list · v2_day_dismissals · v2_record_assembly · v2_record_arrival · v2_record_dismissal
// v2_day_rules · v2_day_plan (رأسُ باب الوصول وخللُ التوقيتات) · v2_arrival_check (قبل حفظ الوصول — والحالُ منه لا من الشاشة)
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { ar, arabize, btn, pick } = V;

  // حالاتُ الاصطفاف كما في قيد attendance.assembly_state
  const ASM = [['attended', 'حاضر'], ['not_arrived', 'غائب'], ['missed_inside', 'تخلّف وهو في المدرسة']];
  const FILTERS = [['all', 'الكلّ'], ['unrecorded', 'لم يُرصد'], ['absent', 'غائب'], ['late', 'متأخّر'], ['permitted', 'مستأذن']];
  const DECISIONS = [['enter_class', 'دخولُ الفصل بإذن الموافقة'], ['to_counselor', 'تحويلٌ إلى الموجّه الطلابيّ']];
  const DECISION_AR = Object.fromEntries(DECISIONS);
  const TABS = [['asm', 'الاصطفاف', 'record_assembly', 'رصد الاصطفاف'], ['arr', 'الوصول', 'record_arrival', 'تسجيل الوصول المتأخّر'], ['dis', 'الانصراف', 'record_dismissal', 'رصد تأخّر الانصراف']];

  const ui = { rules: null, rulesErr: '', summary: null, classes: [], rows: [], dis: [], disErr: '', tab: null, cls: null, filter: 'all', busy: new Set() };
  const can = (k) => !!(M.state.me && M.state.me.can && M.state.me.can[k]);
  const owned = () => TABS.filter((t) => can(t[2]));
  const nowHM = () => new Date().toTimeString().slice(0, 5);
  const nameOf = (r) => r.display_name || r.full_name;
  const classKey = (c) => c.grade + '/' + c.section;
  const classLabel = (r) => { const c = ui.classes.find((k) => k.grade === r.grade && k.section === r.section); return c ? c.label_ar : r.grade + ' — ' + r.section; };
  const matches = (r, q) => { q = q.trim(); return !q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q); };
  const isStudy = () => !!ui.summary && (ui.summary.day_kind === 'study' || ui.summary.day_kind === 'exam');
  const open = () => isStudy() && !ui.summary.closed;

  // ---------- الجلب ----------
  async function refresh() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    const a = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, list, dis, rules, plan] = await Promise.all([
      M.rpc('v2_day_summary', a, 'ملخّص اليوم'),
      M.rpc('v2_day_classes', a, 'فصول اليوم'),
      M.rpc('v2_day_list', a, 'طلّاب اليوم'),
      can('record_dismissal') ? M.rpc('v2_day_dismissals', a, 'انصرافات اليوم') : Promise.resolve({ data: [] }),
      can('record_arrival') ? M.rpc('v2_day_rules', { p_school: M.state.school }, 'قواعد اليوم') : Promise.resolve({ data: null }),
      can('record_arrival') ? M.rpc('v2_day_plan', { p_school: M.state.school }, 'لوحة اليوم') : Promise.resolve({ data: null }),
    ]);
    const err = sum.error || cls.error || list.error;
    if (err) { showLoadErr('تعذّر جلب اليوم: ' + errText(err)); return; }
    ui.summary = (sum.data && sum.data[0]) || null;
    ui.classes = cls.data || [];
    ui.rows = list.data || [];
    ui.disErr = dis.error ? 'تعذّر جلب انصرافات اليوم: ' + errText(dis.error) : '';
    ui.dis = dis.data || [];
    ui.rules = rules.data || null;
    ui.rulesErr = rules.error ? errText(rules.error) : '';
    ui.issues = (plan.data && plan.data.issues) || [];
    if (ui.cls && !ui.classes.some((c) => classKey(c) === ui.cls)) ui.cls = null;
    render();
  }

  // ---------- العرض ----------
  function render() {
    V.renderRole();
    const s = ui.summary;
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, s.day_kind); else $('dates').textContent = '';
    $('noStudy').hidden = !s || isStudy();
    if (s && !isStudy()) $('noStudy').textContent = 'هذا اليوم ليس يومَ دراسة (' + (M.DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا يُرصد فيه اصطفافٌ ولا وصولٌ ولا انصراف.';
    $('closedNote').hidden = !s || !s.closed;

    const mine = owned();
    if (!mine.some((t) => t[0] === ui.tab)) ui.tab = mine.length ? mine[0][0] : null;
    $('tabs').hidden = mine.length < 2;
    pick($('tabs'), mine.map((t) => [t[0], t[1]]), ui.tab, (v) => { ui.tab = v; render(); });
    // ما لا تملكه يُكتب سببُه ولا يُخفى
    const lack = TABS.filter((t) => !can(t[2])).map((t) => t[3]);
    $('noCanTab').hidden = !lack.length;
    $('noCanTab').textContent = lack.length ? M.lacks(lack.join(' · ')) : '';
    for (const [k, id] of [['asm', 'asmView'], ['arr', 'arrView'], ['dis', 'disView']]) $(id).hidden = ui.tab !== k;
    if (ui.tab === 'asm') renderAssembly();
    if (ui.tab === 'arr') renderArrivals();
    if (ui.tab === 'dis') renderDismissals();
  }

  // ① الاصطفاف
  function renderAssembly() {
    const done = ui.classes.filter((c) => c.is_done).length;
    const total = ui.classes.length;
    $('asmProgress').textContent = !total ? 'لا فصولَ فيها طلّابٌ مقيّدون.'
      : done === total ? 'رُصدت الفصولُ كلُّها (' + total + ')' : 'رُصد ' + done + ' فصلًا من ' + total + ' — بقي ' + (total - done);
    pick($('classes'), ui.classes.map((c) => [classKey(c), c.label_ar + (c.is_done ? ' ✓' : ' · ' + c.unrecorded)]), ui.cls, (v) => { ui.cls = v; ui.filter = 'all'; $('qAsm').value = ''; render(); });
    arabize($('asmProgress'));
    const c = ui.classes.find((x) => classKey(x) === ui.cls);
    $('clsCard').hidden = !c;
    if (!c) return;
    $('clsTitle').textContent = c.label_ar;
    $('clsState').textContent = c.is_done ? 'رُصد كاملًا' : 'بقي ' + c.unrecorded + ' من ' + c.enrolled;
    $('clsCounts').textContent = 'حاضر ' + c.present + ' · غائب ' + c.absent + ' · متأخّر ' + c.late + ' · مستأذن ' + c.permitted + ' · تخلّف عن الاصطفاف ' + c.missed_assembly;
    pick($('filters'), FILTERS, ui.filter, (v) => { ui.filter = v; renderAssembly(); });
    const box = $('asmList');
    box.textContent = '';
    const q = $('qAsm').value;
    const inClass = ui.rows.filter((r) => r.grade === c.grade && r.section === c.section);
    const rows = inClass.filter((r) => (ui.filter === 'all' || r.state === ui.filter) && matches(r, q));
    if (!rows.length) box.appendChild(el('p', 'rs-empty', inClass.length ? 'لا أحدَ في هذا التصنيف.' : 'لا طلّابَ مقيّدون في هذا الفصل.'));
    for (const r of rows) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, nameOf(r)), el('span', 'rs-who', r.state_ar || ''));
      f.appendChild(hd);
      const bits = [r.student_no, r.assembly_ar,
        r.arrived_at ? 'وصل ' + r.arrived_at.slice(0, 5) + (r.minutes_late != null ? ' — متأخّرًا ' + r.minutes_late + ' دقيقة' : '') : null,
        r.has_permit ? 'إذنُ موافقة' + (r.permit_decision ? ' (' + (DECISION_AR[r.permit_decision] || r.permit_decision) + ')' : '') : null,
        r.recorded_role ? 'رصده: ' + r.recorded_role : null].filter(Boolean);
      f.appendChild(el('p', null, bits.join(' · ')));
      const chips = el('div', 'rs-pick');
      if (open() && !ui.busy.has(r.student_id)) pick(chips, ASM, r.assembly_state, (v) => recordAssembly(r, v));
      else { pick(chips, ASM, r.assembly_state, () => {}); chips.classList.add('rs-off'); }
      f.appendChild(chips);
      box.appendChild(f);
    }
    const nav = $('clsNav');
    nav.textContent = '';
    const next = ui.classes.find((x) => !x.is_done && classKey(x) !== ui.cls);
    if (next) nav.appendChild(btn('الفصلُ التالي: ' + next.label_ar, 'rs-btn soft', () => { ui.cls = classKey(next); ui.filter = 'all'; $('qAsm').value = ''; render(); window.scrollTo(0, 0); }));
    arabize($('clsCard'));
  }

  async function recordAssembly(r, state) {
    if (ui.busy.has(r.student_id)) return;
    ui.busy.add(r.student_id);
    V.flash('wait', 'يُرصد ' + nameOf(r) + '…');
    const { error } = await M.rpc('v2_record_assembly', { p_student: r.student_id, p_date: M.state.date, p_state: state }, 'رصد الاصطفاف');
    ui.busy.delete(r.student_id);
    if (error) { V.flash('bad', 'لم يُرصد ' + nameOf(r) + ': ' + errText(error)); renderAssembly(); return; }
    V.flash('ok', 'رُصد ' + nameOf(r) + ': ' + (ASM.find((a) => a[0] === state) || [])[1]);
    await refresh();
  }

  // ② الوصول
  function stuRow(r, lines, label, fn) {
    const f = el('div', 'rs-file');
    const hd = el('div', 'rs-hd');
    hd.append(el('h5', null, nameOf(r)), el('span', 'rs-who', r.state_ar || ''));
    f.appendChild(hd);
    f.appendChild(el('p', null, [r.student_no, classLabel(r)].concat(lines).filter(Boolean).join(' · ')));
    if (label) {
      const b = btn(label, 'rs-btn soft', fn);
      b.disabled = !fn;
      f.appendChild(b);
    }
    return f;
  }

  // قواعدُ اليوم كما رجعت — بحقولها العربيّة (_ar) من القاعدة، والأصليّةُ للمقارنة وحدَها
  function renderRules() {
    const p = $('dayRules');
    const d = ui.rules;
    p.hidden = !d && !ui.rulesErr;
    if (ui.rulesErr) { p.textContent = 'تعذّر جلب قواعد اليوم: ' + ui.rulesErr; return; }
    if (!d) return;
    p.textContent = '';
    p.append('الاصطفاف ' + (d.assembly_ar || '—') + ' · المهلة ' + (d.grace_ar || '٠') + ' دقيقة · ', el('b', null, 'حدُّ التأخّر ' + (d.late_cutoff_ar || '—')),
      ' — بعده يُسجَّل غائبًا' + (d.late_cutoff_note ? ' · ' + d.late_cutoff_note : ''));
    // خللُ توقيتات اليوم كما تكشفه القاعدة (v2_day_plan · issues) — يُعرض ولا يُصلَح هنا
    for (const i of ui.issues || []) p.appendChild(el('div', 'rs-state-open', i.text));
  }

  function renderArrivals() {
    renderRules();
    const q = $('qArr').value;
    const go = open();
    const wait = ui.rows.filter((r) => (r.state === 'absent' || r.state === 'unrecorded') && matches(r, q));
    $('waitTitle').textContent = 'لم يصل بعد (' + wait.length + ')';
    const wb = $('waitList');
    wb.textContent = '';
    if (!wait.length) wb.appendChild(el('p', 'rs-empty', q ? 'لا أحدَ بهذا البحث.' : 'لا أحدَ ينتظر وصوله.'));
    for (const r of wait.slice(0, 60)) wb.appendChild(stuRow(r, [r.assembly_ar], 'وصل الآن', go ? () => arrivalForm(r) : null));
    const late = ui.rows.filter((r) => (r.has_permit || r.state === 'late') && matches(r, q));
    $('lateTitle').textContent = 'سُجّل وصولُهم متأخّرين (' + late.length + ')';
    const lb = $('lateList');
    lb.textContent = '';
    if (!late.length) lb.appendChild(el('p', 'rs-empty', 'لم يُسجَّل وصولٌ متأخّر.'));
    for (const r of late) {
      const t = r.arrived_at ? 'وصل ' + r.arrived_at.slice(0, 5) + (r.minutes_late != null ? ' — متأخّرًا ' + r.minutes_late + ' دقيقة' : '') : '';
      lb.appendChild(stuRow(r, [t, r.permit_decision ? (DECISION_AR[r.permit_decision] || r.permit_decision) : ''], 'عدّل', go ? () => arrivalForm(r) : null));
    }
    arabize($('arrView'));
  }

  function arrivalForm(r) {
    V.form({
      title: 'تسجيلُ وصولٍ متأخّر', what: nameOf(r) + ' — ' + classLabel(r),
      fields: [
        { key: 'at', type: 'time', label: 'وقتُ الوصول', value: r.arrived_at ? r.arrived_at.slice(0, 5) : nowHM() },
        { key: 'dec', type: 'pick', label: 'القرار — ض٠٥', items: DECISIONS, value: r.permit_decision || 'enter_class' },
        { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 },
      ],
      ok: 'سجّل الوصول',
      onOk: async (v) => {
        // الحالُ من القاعدة قبل الحفظ (v2_arrival_check) — ولا تُحسب في الشاشة
        if (v.at) {
          const { data: c, error: ce } = await M.rpc('v2_arrival_check', { p_school: M.state.school, p_at: v.at }, 'التحقّق من الوصول');
          if (ce) return ce;
          if (c && c.can_record_arrival === false) { setTimeout(() => notLateForm(r, v.at, c), 0); return null; }
        }
        const { error } = await M.rpc('v2_record_arrival', { p_student: r.student_id, p_date: M.state.date, p_arrived: v.at || null, p_decision: v.dec || null, p_note: v.note || null }, 'تسجيل الوصول');
        if (error) return error;
        V.flash('ok', 'سُجّل وصولُ ' + nameOf(r) + ' — ' + (DECISION_AR[v.dec] || v.dec));
        await refresh();
        return null;
      },
    });
  }

  // لا يُسجَّل وصولًا متأخّرًا: يُعرض why كما رجع، وبدلُه — إن كان غائبًا — تسجيلُ الغياب بالاصطفاف (not_arrived) لمن يملكه
  function notLateForm(r, at, c) {
    const absent = c.state === 'absent';
    const mayAbsent = absent && can('record_assembly');
    V.form({
      title: 'لا يُسجَّل وصولًا متأخّرًا', what: nameOf(r) + ' · وصل ' + (c.at_ar || at) + ' · ' + (c.why || c.state_ar || ''),
      fields: [],
      ok: mayAbsent ? 'سجّله غائبًا' : 'حسنًا',
      onOk: async () => {
        if (!mayAbsent) {
          if (absent) V.flash('bad', (c.why || '') + ' · ' + M.lacks('رصد الاصطفاف'));
          return null;
        }
        const { error } = await M.rpc('v2_record_assembly', { p_student: r.student_id, p_date: M.state.date, p_state: 'not_arrived' }, 'تسجيل الغياب');
        if (error) return error;
        V.flash('ok', 'سُجّل ' + nameOf(r) + ' غائبًا — ' + (c.why || ''));
        await refresh();
        return null;
      },
    });
  }

  // ③ الانصراف
  function renderDismissals() {
    const q = $('qDis').value;
    const go = isStudy();
    const box = $('disList');
    box.textContent = '';
    if (!q.trim()) box.appendChild(el('p', 'rs-empty', 'ابحث عن الطالب الذي بقي بعد نهاية الدوام.'));
    else {
      const found = ui.rows.filter((r) => matches(r, q));
      if (!found.length) box.appendChild(el('p', 'rs-empty', 'لا أحدَ بهذا البحث.'));
      for (const r of found.slice(0, 20)) box.appendChild(stuRow(r, [], 'سجّل تأخّرَ انصرافه', go ? () => dismissalForm(r) : null));
    }
    $('disDayErr').textContent = ui.disErr;
    $('disDayErr').hidden = !ui.disErr;
    $('disDayTitle').textContent = 'انصرافاتُ اليوم' + (ui.disErr ? '' : ' (' + ui.dis.length + ')');
    const day = $('disDay');
    day.textContent = '';
    if (!ui.disErr && !ui.dis.length) day.appendChild(el('p', 'rs-empty', 'لم يُرصد تأخّرُ انصرافٍ في هذا اليوم.'));
    for (const d of ui.dis) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, d.student_name), el('span', 'rs-who' + (d.threshold === 'action_30' ? ' rs-state-open' : ''), d.threshold_ar || ''));
      f.appendChild(hd);
      f.appendChild(el('p', null, [d.class_ar, 'خرج ' + (d.left_at || '').slice(0, 5) + ' — بعد نهاية الدوام بـ' + d.minutes_after + ' دقيقة', d.reason_ar].filter(Boolean).join(' · ')));
      if (d.action_taken) f.appendChild(el('p', null, d.action_taken));
      f.appendChild(el('p', 'rs-meta', 'رصده: ' + (d.recorded_role || '—') + ' · ' + (d.guardian_notified ? 'أُبلغ وليُّ الأمر' : 'لم يُبلَّغ وليُّ الأمر')));
      day.appendChild(f);
    }
    arabize($('disView'));
  }

  function dismissalForm(r) {
    V.form({
      title: 'تأخّرٌ عن الانصراف', what: nameOf(r) + ' — ' + classLabel(r),
      fields: [
        { key: 'at', type: 'time', label: 'وقتُ خروجه من المدرسة', value: nowHM() },
        { key: 'why', type: 'textarea', label: 'السبب (اختياريّ)', rows: 2 },
      ],
      ok: 'سجّل',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_record_dismissal', { p_student: r.student_id, p_date: M.state.date, p_left: v.at || null, p_reason: v.why || null }, 'رصد تأخر الانصراف');
        if (error) return error;
        const x = (data && data[0]) || {};
        V.flash('ok', 'رُصد تأخّرُ انصراف ' + nameOf(r) + (x.minutes_after != null ? ' — ' + x.minutes_after + ' دقيقة' : '') + (x.action_taken ? ' · ' + x.action_taken : ''));
        $('qDis').value = '';
        await refresh();
        return null;
      },
    });
  }

  $('qAsm').addEventListener('input', renderAssembly);
  $('qArr').addEventListener('input', renderArrivals);
  $('qDis').addEventListener('input', renderDismissals);

  M.start({
    screen: 'wusul',
    onChange: (why) => { if (why === 'school') ui.cls = null; return refresh(); },
  });
})();
