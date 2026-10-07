// مؤيّد · شاشة الوكيل — viewW في المحاكي: ستُّ بطاقات، والفعلُ الأكثرُ تكرارًا (الرصد) ضغطةٌ واحدةٌ بلا نافذة.
// كلُّ نصٍّ وعددٍ ودرجةٍ وسلّمٍ من القاعدة — والشاشةُ لا تحسب ولا تؤلّف، وما لم يُبنَ في المحرّك يُعرض معطَّلًا بسببه.
// v2_day_summary · v2_day_classes · v2_day_list · v2_periods · v2_conduct_list · v2_record_behavior · v2_record_amend
// v2_entries_pending · v2_form_open(5) · v2_student_card · v2_student_tasks · v2_student_timeline(p_student, null)
// الدرجةُ الأولى: auto[] و advice بعد الرصد · v2_advice_for · v2_census_list · v2_census_self · v2_census_assign · v2_census_sweep
// v2_contact_log (الحقلُ يتبع النتيجة) · v2_guardian_message · v2_response_check · v2_refer_committee · وبنكُ العبارات v2_bank تحت الحقول
// وإنجازُ المهامّ بإثباتها في tasks.js
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, errText, showLoadErr } = M;
  const V = window.MoayadView;

  const ui = {
    classes: [], rows: [], periods: [], problems: [], cls: null, stu: null, prob: null, period: null,
    busy: false, files: null, last: null,
  };

  // الأرقامُ عربيّةٌ في العرض — لما ترجعه القاعدةُ بأرقامٍ غربيّة (الرقم · التاريخ · اسم الفصل): تحويلُ أرقامٍ لا حساب
  const ar = (v) => String(v == null ? '' : v).replace(/[0-9]/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  function arabize(node) {
    const w = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    for (let t = w.nextNode(); t; t = w.nextNode()) t.nodeValue = ar(t.nodeValue);
  }
  const fill = (sel, items, first) => {
    sel.textContent = '';
    if (first) sel.appendChild(new Option(first, ''));
    for (const [v, t] of items) sel.appendChild(new Option(t, v));
  };
  const btn = (text, cls, fn) => {
    const b = el('button', cls, text);
    b.type = 'button';
    if (fn) b.addEventListener('click', fn);
    return b;
  };
  // فعلٌ لم يُبنَ في المحرّك: زرٌّ معطَّلٌ ومعه سببُه
  const notBuilt = (text) => {
    const w = el('span', 'rs-off-act');
    const b = btn(text, 'rs-btn soft');
    b.disabled = true;
    w.append(b, el('small', null, 'لم يُبنَ بعد'));
    return w;
  };

  // ---------- الرأس: الصفةُ من v2_me ----------
  function renderRole() {
    const me = M.state.me || {};
    $('roleLine').hidden = !me.role_ar;
    $('roleText').textContent = '';
    $('roleText').append('تعمل بصفة ', el('b', null, me.role_ar || ''));
  }

  // ---------- الجلب ----------
  async function refresh() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    renderRole();
    const args = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, list, per] = await Promise.all([
      M.rpc('v2_day_summary', args),
      M.rpc('v2_day_classes', args),
      M.rpc('v2_day_list', args),
      M.rpc('v2_periods', { p_school: M.state.school }, 'حصص المدرسة'),
    ]);
    const err = sum.error || cls.error || list.error || per.error;
    if (err) { showLoadErr('تعذّر الجلب: ' + errText(err)); return; }
    const s = sum.data && sum.data[0];
    if (s) { M.renderDates($('dates'), s.hijri, M.state.date, null); arabize($('dates')); }
    ui.classes = cls.data || [];
    // 🔴 الغائبُ لا يظهر في القائمة أصلًا — والقاعدةُ ترفضه إن وصل
    ui.rows = (list.data || []).filter((r) => r.state !== 'absent');
    ui.periods = per.data || [];
    ui.cls = null;
    renderClasses();
    resetStudent();
    // ما ليس للمعلّم: الشواهد والنموذج ٥ والتكليفُ بالحصر — بمفتاح wakeel_full (الوكيلُ والمدير)
    ui.full = !!(M.state.me && M.state.me.can && M.state.me.can.wakeel_full);
    $('evCard').hidden = !ui.full;
    if (ui.full) loadEvidence();
  }

  // ---------- ① الفصل: شريطة ----------
  function renderClasses() {
    const box = $('classes');
    box.textContent = '';
    if (!ui.classes.length) { box.appendChild(el('span', 'k', 'لا فصول فيها طلّابٌ مقيَّدون')); return; }
    for (const c of ui.classes) {
      const on = ui.cls === c;
      const s = el('span', on ? 'on' : null, ar(c.label_ar));
      s.setAttribute('role', 'button'); s.tabIndex = 0; s.setAttribute('aria-pressed', String(on));
      const pick = () => { ui.cls = c; renderClasses(); resetStudent(); $('qStu').disabled = false; renderStudents(); };
      s.addEventListener('click', pick);
      s.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(); } });
      box.appendChild(s);
    }
  }

  function resetStudent() {
    ui.stu = null; ui.problems = []; ui.files = null;
    $('qStu').value = '';
    $('qStu').disabled = !ui.cls;
    $('students').textContent = '';
    resetProblem();
    renderStudentCards();
  }
  function resetProblem() {
    fill($('prob'), [], 'اختر السلوك');
    $('prob').disabled = true;
    $('qProb').value = '';
    $('qProb').disabled = true;
    ui.prob = null; ui.period = null;
    renderPeriods();
    syncButton();
  }

  // ---------- ① الطالب: قائمةٌ ببحث ----------
  function renderStudents() {
    const box = $('students');
    box.textContent = '';
    if (!ui.cls) return;
    const q = $('qStu').value.trim();
    const list = ui.rows.filter((r) => r.grade === ui.cls.grade && r.section === ui.cls.section &&
      (!q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q)));
    if (!list.length) { box.appendChild(el('div', 'rs-empty', q ? 'لا أحدَ بهذا البحث.' : 'لا حاضرَ في هذا الفصل.')); return; }
    for (const r of list) {
      const on = ui.stu === r;
      const b = btn('', 'rs-item' + (on ? ' on' : ''), () => openStudent(r));
      b.setAttribute('role', 'option'); b.setAttribute('aria-selected', String(on));
      b.append(el('b', null, r.display_name || r.full_name), el('small', null, ar(r.student_no || '')));
      box.appendChild(b);
    }
  }
  $('qStu').addEventListener('input', renderStudents);

  async function openStudent(r) {
    resetProblem();
    ui.stu = r; ui.files = null;
    renderStudents();
    renderStudentCards();
    fill($('prob'), [], 'جارٍ جلب السلوكيّات…');
    const { data, error } = await M.rpc('v2_conduct_list', { p_student: r.student_id, p_mode: 'onsite', p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== r) return;
    if (error) { fill($('prob'), [], 'تعذّر الجلب'); flash('bad', errText(error)); return; }
    ui.problems = data || [];
    $('qProb').disabled = false;
    renderProblems();
    loadStudentCards();
  }

  // ---------- ① السلوك: قائمةٌ ببحث، وكلٌّ بدرجته وسنده كما يرجعان ----------
  function renderProblems() {
    const q = $('qProb').value.trim();
    const list = ui.problems.filter((p) => !q || (p.text || '').includes(q));
    const keep = ui.prob && list.includes(ui.prob) ? String(ui.prob.id) : '';
    fill($('prob'), list.map((p) => [String(p.id), p.text + ' — ' + p.degree_ar + (p.page_ar ? ' · ' + p.page_ar : '')]),
      list.length ? 'اختر السلوك' : 'لا سلوكَ بهذا البحث');
    $('prob').value = keep;
    $('prob').disabled = !list.length;
    if (!keep) { ui.prob = null; ui.period = null; renderPeriods(); }
    syncButton();
  }
  $('qProb').addEventListener('input', renderProblems);
  $('prob').addEventListener('change', () => {
    ui.prob = ui.problems.find((p) => String(p.id) === $('prob').value) || null;
    ui.period = null;
    renderPeriods();
    syncButton();
  });

  // ---------- ① الحصّة: شرائطُ من v2_periods — حين needs_period وحدَها ----------
  function renderPeriods() {
    const show = !!(ui.prob && ui.prob.needs_period);
    $('periodBox').hidden = !show;
    const box = $('periods');
    box.textContent = '';
    if (!show) return;
    if (!ui.periods.length) { box.appendChild(el('span', 'k', 'لا حصصَ مسجّلةٌ للمدرسة — تُضبط من لوحة التحكّم')); return; }
    for (const p of ui.periods) {
      const on = ui.period === p.no;
      const s = el('span', on ? 'on' : null, p.no_ar);
      s.title = p.label || '';
      s.setAttribute('role', 'button'); s.tabIndex = 0; s.setAttribute('aria-pressed', String(on));
      const pick = () => { ui.period = on ? null : p.no; renderPeriods(); };
      s.addEventListener('click', pick);
      s.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(); } });
      box.appendChild(s);
    }
  }

  function syncButton() { $('rec').disabled = ui.busy || !ui.stu || !ui.prob; }

  // ---------- شريطُ النتيجة ----------
  // auto: ما وقع آليًّا بالرصد كما رجع من القاعدة — {kind, text}
  function flash(kind, text, acts, auto) {
    const f = $('flash');
    f.className = 'flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (auto && auto.length) {
      const ul = el('ul', 'rs-auto');
      for (const a of auto) ul.appendChild(el('li', null, (a.kind === 'advice' ? 'النصيحةُ التربويّة: ' : '') + a.text));
      f.appendChild(ul);
    }
    if (acts && acts.length) {
      const row = el('span', 'rs-row');
      for (const a of acts) row.appendChild(a);
      f.appendChild(row);
    }
    f.hidden = false;
    arabize(f);
  }

  // ---------- ① ارصد: ضغطةٌ واحدة ----------
  $('rec').addEventListener('click', async () => {
    if (!ui.stu || !ui.prob || ui.busy) return;
    const stu = ui.stu; const p = ui.prob;
    ui.busy = true; syncButton();
    // ١ · الأثرُ فورًا بحال «يُرسل» — ولا درجةَ تُنقص قبل ردّ القاعدة
    flash('wait', 'يُرسل… ' + p.text);
    // ٢ · القاعدة
    const { data, error } = await M.rpc('v2_record_behavior', {
      p_student: stu.student_id, p_problem: p.id, p_period: p.needs_period ? ui.period : null,
    }, 'رصد مخالفة');
    ui.busy = false; syncButton();
    // ٣ · رُفض ⇒ نصُّ الرفض كما هو · نجح ⇒ headline كما يرجع
    if (error) { flash('bad', errText(error)); return; }
    ui.last = { record: data && data.record, problem: data && data.problem, student: stu };
    flash('ok', (data && data.headline) || 'رُصدت المخالفة', [
      btn('افتح الملفّ', 'rs-btn soft', () => $('files').scrollIntoView({ behavior: 'smooth', block: 'start' })),
      btn('أضِف التفاصيل', 'rs-btn soft', () => openAmend()),
    ], (data && data.auto) || []);
    ui.period = null;
    const { data: fresh } = await M.rpc('v2_conduct_list', { p_student: stu.student_id, p_mode: 'onsite', p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== stu) return;
    if (fresh) { ui.problems = fresh; ui.prob = ui.problems.find((x) => x.id === p.id) || null; }
    renderProblems(); renderPeriods();
    loadStudentCards();
  });

  // ---------- تفاصيلُ الرصدة بعد الرصد: v2_record_amend ----------
  function openAmend() {
    if (!ui.last || !ui.last.record) return;
    $('amWhat').textContent = (ui.last.student.display_name || ui.last.student.full_name) + ' — ' + (ui.last.problem || '');
    for (const id of ['amPlace', 'amNote']) $(id).value = '';
    for (const id of ['amInjury', 'amDamage', 'amSeizure', 'amLegal']) $(id).checked = false;
    $('amLegalBox').hidden = true;
    $('amendModal').hidden = false;
    $('amPlace').focus();
    placeHint();
  }
  // اقتراحُ المكان من v2_now_slot: الحصّةُ أو الفترةُ القائمةُ الآن — يُعرض ولا يُكتب إلا بضغطه
  async function placeHint() {
    const box = $('amPlaceHint');
    box.hidden = true;
    box.textContent = '';
    const { data, error } = await M.rpc('v2_now_slot', { p_school: M.state.school, p_at: null }, 'ما نحن فيه الآن');
    if (error || !data) return;
    box.appendChild(el('span', 'k', 'الآن ' + (data.at_ar || '') + ': ' + (data.label || '') + (data.starts_ar ? ' (' + data.starts_ar + ' — ' + data.ends_ar + ')' : '')));
    if (data.place_hint) {
      const s = el('span', null, 'اقتراحُ المكان: ' + data.place_hint);
      s.setAttribute('role', 'button');
      s.tabIndex = 0;
      s.addEventListener('click', () => { $('amPlace').value = data.place_hint; });
      box.appendChild(s);
    }
    box.hidden = false;
  }
  const closeAmend = () => { $('amendModal').hidden = true; };
  $('amCancel').addEventListener('click', closeAmend);
  $('amendModal').addEventListener('click', (e) => { if (e.target === $('amendModal')) closeAmend(); });
  $('amSeizure').addEventListener('change', () => {
    $('amLegalBox').hidden = !$('amSeizure').checked;
    if (!$('amSeizure').checked) $('amLegal').checked = false;
  });
  $('amOk').addEventListener('click', async () => {
    const t = (id) => { const v = $(id).value.trim(); return v === '' ? null : v; };
    const { data, error } = await M.rpc('v2_record_amend', {
      p_record: ui.last.record, p_place: t('amPlace'), p_note: t('amNote'),
      // المعلَّمُ وحدَه يُرسل، والفارغُ null فيبقى ما كان — كي لا يمحو اللوحُ علامةً سبقت
      p_injury: $('amInjury').checked || null, p_damage: $('amDamage').checked || null,
      p_seizure: $('amSeizure').checked || null, p_seizure_legal: ($('amSeizure').checked && $('amLegal').checked) || null,
    }, 'تفاصيل الرصدة');
    closeAmend();
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', 'حُفظت تفاصيلُ الرصدة' + (data && data.note ? ' — ' + data.note : ''));
    loadStudentCards();
  });

  // ---------- ② شواهدُ بانتظارك ----------
  async function loadEvidence() {
    const box = $('evidence');
    box.textContent = '';
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: M.state.school }, 'شواهد بانتظارك');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'لا شواهدَ بانتظارك.')); return; }
    for (const x of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, x.merit));
      f.appendChild(el('p', null, (x.student || '') + ' — ' + (x.what || '') + (x.evidence ? ' · الشاهد: ' + x.evidence : '')));
      const row = el('div', 'rs-row');
      row.append(notBuilt('ارفعه للّجنة'), notBuilt('ردّه'));
      f.appendChild(row);
      box.appendChild(f);
    }
    arabize(box);
  }

  // ---------- ③ ④ ⑤ ⑥ بطاقاتُ الطالب ----------
  async function loadStudentCards() {
    const stu = ui.stu;
    if (!stu) return;
    const [card, tasks, tl, f5, ct, cn] = await Promise.all([
      M.rpc('v2_student_card', { p_student: stu.student_id }, 'بطاقة الطالب'),
      M.rpc('v2_student_tasks', { p_student: stu.student_id }, 'مهامّ الطالب'),
      M.rpc('v2_student_timeline', { p_student: stu.student_id, p_as: null }, 'سجلّ الملفّ'),
      ui.full ? M.rpc('v2_form_open', { p_form: 5, p_student: stu.student_id }, 'النموذج ٥') : Promise.resolve({}),
      M.rpc('v2_contacts_of', { p_student: stu.student_id }, 'سجلّ الاتّصال'),
      M.rpc('v2_census_of', { p_student: stu.student_id }, 'حصر السلوكيّات'),
    ]);
    if (ui.stu !== stu) return;
    // v2_student_tasks بأسمائه الجديدة: task · record · text · problem · kind · kind_ar
    ui.files = { card: card.data || {}, tasks: (tasks.data || []).map((t) => Object.assign({}, t, { task_id: t.task_id || t.task, record_id: t.record_id || t.record, text_ar: t.text_ar || t.text, problem_ar: t.problem_ar || t.problem })), timeline: tl.data || {}, form5: f5, contacts: ct, census: cn, advice: new Map(), resp: new Map(), error: card.error || tasks.error || tl.error };
    renderStudentCards();
    loadAdvice(stu);
    loadResponse(stu);
  }

  // سلوكُ الملفّ بعناصره من v2_conduct_list — بنصّه كما يرجع في البطاقة
  const metaOf = (prob) => ui.problems.find((p) => p.text === prob || p.text === String(prob || '').replace(/\.\s*$/, '')) || null;

  // النصيحةُ التربويّة لآخر رصدةٍ في كلّ ملفّ: v2_advice_for(السلوك، رقمُ الرصدة) — نصُّها من القاعدة
  async function loadAdvice(stu) {
    const last = new Map();
    for (const r of (ui.files.card.behavior || [])) if (!last.has(r.problem)) last.set(r.problem, r);
    await Promise.all([...last].map(async ([prob, r]) => {
      const m = metaOf(prob);
      if (!m) return;
      const { data } = await M.rpc('v2_advice_for', { p_problem: m.id, p_occurrence: r.occurrence }, 'النصيحة التربويّة');
      if (ui.stu === stu && ui.files && data && data.text) ui.files.advice.set(prob, data.text);
    }));
    if (ui.stu === stu) renderFiles();
  }

  function renderStudentCards() {
    const show = !!ui.stu;
    $('f5Card').hidden = !show || !ui.full; $('respCard').hidden = !show; $('tlCard').hidden = !show;
    $('contactCard').hidden = !show; $('censusCard').hidden = !show;
    if (ui.full) renderForm5();
    renderFiles(); renderTimeline(); renderContacts(); renderCensus(); renderResponse();
  }

  // ③ النموذج ٥: صفوفُه كما يرجعها v2_form_open — ويُطبع من النموذج نفسه
  function renderForm5() {
    const box = $('form5');
    box.textContent = '';
    if (!ui.stu) return;
    if (!ui.files) { box.appendChild(el('p', 'rs-empty', 'جارٍ الجلب…')); return; }
    const f5 = ui.files.form5 || {};
    if (f5.error) { box.appendChild(el('div', 'notice err', errText(f5.error))); return; }
    const rows = (f5.data && f5.data.doc && f5.data.doc.rows) || [];
    if (!rows.length) box.appendChild(el('p', 'rs-empty', 'لا رصداتٍ في السجلّ.'));
    else {
      const wrap = el('div', 'rs-tablewrap');
      const t = el('table', 'rs-table');
      const hr = el('tr');
      for (const h of ['المشكلة', 'درجتُها', 'تاريخُها', 'المحسوم', 'الإجراءات']) hr.appendChild(el('th', null, h));
      t.appendChild(hr);
      for (const r of rows) {
        const tr = el('tr');
        for (const v of [r.problem, r.degree, (r.on_h || r.on_g || '') + ' هـ', r.deducted, r.actions]) tr.appendChild(el('td', null, v == null ? '—' : String(v)));
        t.appendChild(tr);
      }
      wrap.appendChild(t);
      box.appendChild(wrap);
    }
    const a = el('a', 'rs-btn soft', 'افتح النموذج ٥ للطباعة');
    a.href = 'form.html?form=5&student=' + encodeURIComponent(ui.stu.student_id);
    a.target = '_blank'; a.rel = 'noopener';
    box.appendChild(a);
    arabize(box);
  }

  // ④ ملفّاتُ الطالب: لكلّ سلوكٍ بطاقتُه — آخرُ رصدةٍ فيه حالُه، والسلّمُ من steps و step كما رجعا
  function renderFiles() {
    const box = $('files');
    box.textContent = '';
    if (!ui.stu) return;
    if (!ui.files) { box.appendChild(el('div', 'rs-card', 'جارٍ جلب ملفّات الطالب…')); return; }
    if (ui.files.error) { box.appendChild(el('div', 'notice err', 'تعذّر جلب الملفّات: ' + errText(ui.files.error))); return; }
    const recs = ui.files.card.behavior || [];
    const head = el('div', 'rs-card');
    head.appendChild(el('h3', null, 'ملفّاتُ ' + (ui.stu.display_name || ui.stu.full_name) + ' السلوكيّة'));
    if (!recs.length) { head.appendChild(el('p', 'rs-empty', 'لا ملفّاتٍ — ارصد لترى')); box.appendChild(head); return; }
    const byProb = new Map();
    for (const r of recs) if (!byProb.has(r.problem)) byProb.set(r.problem, { last: r, all: recs.filter((x) => x.problem === r.problem) });
    head.appendChild(el('p', 'rs-meta', ar(byProb.size) + ' ملفًّا'));
    box.appendChild(head);
    for (const [prob, f] of byProb) box.appendChild(fileCard(prob, f));
    arabize(box);
  }

  function fileCard(prob, f) {
    const r = f.last;
    const c = el('div', 'rs-card');
    const hd = el('div', 'rs-hd');
    hd.append(el('h3', null, prob), el('span', 'rs-occ', 'الرصدةُ ' + r.occurrence));
    c.appendChild(hd);
    const meta = metaOf(prob);
    c.appendChild(el('p', 'rs-meta', [meta && meta.degree_ar, meta && meta.page_ar, 'آخرُ رصدة ' + (r.on_h || r.on)].filter(Boolean).join(' · ')));
    const steps = meta && meta.steps ? Number(meta.steps) : null;
    if (steps && r.step) {
      const lad = el('div', 'rs-pick rs-ladder');
      lad.appendChild(el('span', 'k', 'السلّم:'));
      for (let i = 1; i <= steps; i++) {
        const cls = i < r.step ? 'done' : (i === Number(r.step) ? 'on' : 'soon');
        lad.appendChild(el('span', cls, i + (i < r.step ? ' ✓' : i === Number(r.step) ? ' ●' : '')));
      }
      c.appendChild(lad);
    }
    const adv = ui.files.advice && ui.files.advice.get(prob);
    if (adv) { const a = el('div', 'rs-advice'); a.append(el('b', null, 'النصيحةُ التربويّة: '), document.createTextNode(adv)); c.appendChild(a); }
    const ts = ui.files.tasks.filter((t) => String(t.problem_ar).replace(/\.\s*$/, '') === String(prob).replace(/\.\s*$/, ''));
    if (ts.length) {
      c.appendChild(el('div', 'rs-label', 'ما على الإجراء:'));
      const ul = el('ul', 'rs-acts');
      for (const t of ts) {
        const done = t.status !== 'open';
        const li = el('li');
        li.append(el('i', 'rs-tick' + (done ? ' ok' : ''), done ? '✓' : '○'), el('span', null, t.text_ar), el('span', 'rs-who', t.kind_ar || t.owner_ar || t.owner_role_ar || t.owner_role || ''));
        ul.appendChild(li);
      }
      c.appendChild(ul);
      const open = ts.filter((t) => t.status === 'open').length;
      const tbox = el('div');
      const showTasks = () => { if (b) b.hidden = true; window.MoayadTasks.render(tbox, ui.stu.student_id); tbox.scrollIntoView({ behavior: 'smooth', block: 'start' }); };
      const b = open ? btn('أنجز المهامّ (' + open + ')', 'rs-btn soft', showTasks) : null;
      // أفعالُ الوكيل: زرٌّ لكلّ مهمّةٍ مفتوحةٍ في tasks بنوعها، ولا زرَّ بلا مهمّة
      const acts = el('div', 'rs-row');
      const has = (kind) => ts.find((t) => t.kind === kind && t.status === 'open');
      const tn = has('notify_guardian');
      if (tn) acts.appendChild(btn('إثباتُ الاتّصال', 'rs-btn soft', () => contactForm(tn.task_id)));
      const tf = has('follow_up');
      if (tf) acts.appendChild(btn('أحصرُ بنفسي', 'rs-btn soft', () => selfCensus(tf.task_id)));
      if (tf && ui.full) acts.appendChild(btn('أكلّف به أحدًا', 'rs-btn soft', () => assignCensus(tf.task_id)));
      // خطابُ الدعوة يُرسل آليًّا بالرصد · والإحالةُ للّجنة بقياس الاستجابة أوّلًا
      if (has('summon_guardian')) acts.appendChild(btn('خطابُ الدعوة', 'rs-btn soft', showTasks));
      const tc = has('committee');
      if (tc) acts.appendChild(btn('الإحالةُ للّجنة', 'rs-btn soft', () => referForm(tc)));
      if (b) c.appendChild(b);
      if (acts.childNodes.length) c.appendChild(acts);
      c.appendChild(tbox);
    }
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, 'رصداتُه (' + f.all.length + ')'));
    const body = el('div', 'rs-dtb');
    for (const x of f.all) body.appendChild(el('div', null, 'الرصدةُ ' + x.occurrence + ' · ' + (x.on_h || x.on) + (x.place ? ' · ' + x.place : '') + (x.note ? ' — ' + x.note : '')));
    det.appendChild(body);
    c.appendChild(det);
    return c;
  }

  // ⑥ سجلُّ الملفّ — مطويٌّ، ولا يُفتح افتراضيًّا
  function renderTimeline() {
    const box = $('timeline');
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const evs = (ui.files.timeline && ui.files.timeline.events) || [];
    $('tlSum').textContent = 'سجلُّ الملفّ (' + ar(evs.length) + ')';
    for (const e of evs) {
      const d = el('div');
      d.append(el('b', null, e.title || ''), document.createTextNode(' · ' + (e.on || '') + (e.body ? ' — ' + e.body : '')));
      box.appendChild(d);
    }
    if (!evs.length) box.appendChild(el('div', null, 'لا أحداثَ بعد.'));
    arabize(box);
  }

  // ---------- الاتّصالُ بوليّ الأمر ----------
  // الوسائلُ والنتائجُ كما يقبلها v2_contact_log — والقاعدةُ ترفض غيرها
  const CHANNELS = ['هاتف', 'رسالة', 'حضور', 'بوّابة'];
  const OUTCOMES = ['ردّ وعلم', 'ردّ ورفض', 'لم يردّ', 'الرقم مغلق', 'الرقم خطأ'];
  function renderContacts() {
    const box = $('contacts');
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const r = ui.files.contacts || {};
    if (r.error) box.appendChild(el('div', 'notice err', errText(r.error)));
    const list = r.data || [];
    if (!list.length && !r.error) box.appendChild(el('p', 'rs-empty', 'لم يُثبت اتّصالٌ بعد.'));
    if (list.length) {
      const ul = el('ul', 'rs-acts');
      for (const x of list) {
        const li = el('li');
        const body = el('span');
        body.style.flex = '1';
        body.appendChild(el('b', null, 'المحاولةُ ' + (x.attempt_ar || x.attempt) + ' · ' + x.channel + ' — ' + x.outcome));
        body.appendChild(el('div', 'rs-meta', [x.summary, x.guardian_say ? 'قال وليُّ الأمر: ' + x.guardian_say : null, x.guardian, x.by ? 'أثبتها ' + x.by : null].filter(Boolean).join(' · ')));
        // ردّ وليُّ الأمر (علم أو رفض) ⇒ أُشعر — كما تُقفل به القاعدةُ المهمّة
        const got = x.outcome === 'ردّ وعلم' || x.outcome === 'ردّ ورفض';
        li.append(el('i', 'rs-tick' + (got ? ' ok' : ''), got ? '✓' : '○'), body, el('small', 'rs-who', [x.on, x.at ? String(x.at).slice(0, 5) : null].filter(Boolean).join(' ')));
        ul.appendChild(li);
      }
      box.appendChild(ul);
    }
    // ولا إثباتَ بلا مهمّة «إشعار وليّ الأمر» مفتوحة
    if (openTasks('notify_guardian').length) box.appendChild(btn('أثبت اتّصالًا', 'rs-btn', () => contactForm()));
    arabize(box);
  }

  // مهامُّ الطالب المفتوحةُ من نوعٍ بعينه — ليُقرن بها الإثباتُ فتُقفل بالقاعدة
  const openTasks = (kind) => ((ui.files && ui.files.tasks) || []).filter((t) => t.kind === kind && t.status === 'open')
    .map((t) => [t.task_id, (t.problem_ar ? t.problem_ar + ' — ' : '') + (t.text_ar || t.kind_ar), t.step_ar ? 'الإجراء ' + t.step_ar : '']);
  const taskField = (kind, pre) => {
    const items = openTasks(kind);
    return items.length ? [{ key: 'task', type: 'choose', label: 'عن مهمّة (' + (kind === 'notify_guardian' ? 'إشعارُ وليّ الأمر' : 'حصرُ السلوكيّات') + ')', items, value: items.some((x) => x[0] === pre) ? pre : items[0][0], hint: 'تُقفل المهمّةُ بالقاعدة متى تمّ ما يقفلها' }] : [];
  };

  // الحقلُ يتبع النتيجة كما يحرسها v2_contact_log: ردّ ⇒ ما دار · ورفض ⇒ وقولُه · لم يردّ ⇒ الساعة · الرقم خطأ ⇒ الصحيح
  const answered = (v) => v.outcome === 'ردّ وعلم' || v.outcome === 'ردّ ورفض';
  const taskById = (id) => ((ui.files && ui.files.tasks) || []).find((t) => t.task_id === id) || null;

  function contactForm(pre) {
    const stu = ui.stu;
    const tf = taskField('notify_guardian', pre);
    pre = pre || (tf[0] && tf[0].value);
    const prob = (id) => { const t = taskById(id); const m = t && metaOf(t.problem_ar); return m ? m.id : null; };
    // الرسالةُ حين تُختار «رسالة»: نصُّها جاهزٌ من v2_guardian_message لرصدة المهمّة، وزرُّ الإرسال
    const msg = el('div');
    let channel = null;
    const loadMsg = async (taskId) => {
      msg.textContent = '';
      if (channel !== 'رسالة') return;
      const t = taskById(taskId);
      if (!t || !t.record_id) { msg.appendChild(el('p', 'rs-meta', 'اختر مهمّةَ الإشعار لتظهر رسالتُها.')); return; }
      msg.appendChild(el('p', 'rs-meta', 'جارٍ تجهيزُ الرسالة…'));
      const { data, error } = await M.rpc('v2_guardian_message', { p_record: t.record_id }, 'رسالة وليّ الأمر');
      msg.textContent = '';
      if (error) { msg.appendChild(el('div', 'flash bad', errText(error))); return; }
      const d = data || {};
      msg.appendChild(el('div', 'rs-label', 'الرسالة' + (d.guardian ? ' إلى ' + d.guardian : '') + (d.phone ? ' · ' + d.phone : '')));
      msg.appendChild(el('div', 'rs-msg', d.body || ''));
      const row = el('div', 'rs-row');
      if (d.whatsapp) {
        const a = el('a', 'rs-btn', 'أرسلها بواتساب');
        a.href = d.whatsapp; a.target = '_blank'; a.rel = 'noopener';
        row.appendChild(a);
      } else row.appendChild(el('span', 'rs-meta', 'لا رقمَ لوليّ الأمر'));
      row.appendChild(btn('انسخ النصّ', 'rs-btn ghost', async () => {
        try { await navigator.clipboard.writeText(d.body || ''); V.flash('ok', 'نُسخ نصُّ الرسالة'); } catch (e) { V.flash('bad', 'تعذّر النسخ'); }
      }));
      msg.appendChild(row);
      msg.appendChild(el('p', 'rs-meta', 'ثمّ أثبت النتيجةَ أدناه.'));
    };
    if (tf[0]) tf[0].onChange = (id) => loadMsg(id);
    V.form({
      title: 'إثباتُ الاتّصال بوليّ الأمر', what: stu.display_name || stu.full_name,
      fields: [...tf,
        { key: 'channel', type: 'pick', label: 'الوسيلة', items: CHANNELS.map((x) => [x, x]), onChange: (x, api) => { channel = x; loadMsg(api.values().task || pre); } },
        { key: 'msg', type: 'node', node: msg, show: (v) => v.channel === 'رسالة' },
        { key: 'outcome', type: 'pick', label: 'النتيجة', items: OUTCOMES.map((x) => [x, x]) },
        { key: 'summary', type: 'textarea', label: 'ما دار', show: answered, bank: { key: 'callWhat', problem: prob(pre) } },
        { key: 'say', type: 'textarea', label: 'ما قاله وليُّ الأمر', rows: 2, hint: 'فرفضُه حجّةٌ تُقيَّد', show: (v) => v.outcome === 'ردّ ورفض' },
        { key: 'at', type: 'time', label: 'ساعةُ المحاولة', hint: 'فمن لم يردّ يُقيَّد وقتُ طلبه', show: (v) => v.outcome === 'لم يردّ' },
        { key: 'right', label: 'الرقمُ الصحيح', hint: 'أو اكتب «لا يُعرف»', show: (v) => v.outcome === 'الرقم خطأ' },
      ],
      ok: 'أثبته',
      onOk: async (v) => {
        // يُرسل حقلُ النتيجة وحدَه — والقاعدةُ تحكم بالنقص
        const { data, error } = await M.rpc('v2_contact_log', {
          p_student: stu.student_id, p_task: v.task || null, p_channel: v.channel, p_outcome: v.outcome,
          p_summary: answered(v) ? v.summary : null, p_guardian_say: v.outcome === 'ردّ ورفض' ? v.say : null,
          p_at: v.outcome === 'لم يردّ' ? v.at : null, p_right_number: v.outcome === 'الرقم خطأ' ? v.right : null,
        }, 'إثبات الاتصال');
        if (error) return error;
        // النصُّ من القاعدة، وهو يتبع closed
        V.flash('ok', ((data && data.note) || 'أُثبت الاتّصال') + ' · المحاولةُ ' + ((data && (data.attempt_ar || data.attempt)) || ''));
        loadStudentCards();
        return null;
      },
    });
  }

  // ---------- هل تعدّل؟ قياسُ الاستجابة والإحالةُ إلى اللجنة ----------
  // لكلّ ملفٍّ بلغ مهمّةَ «الإحالة للّجنة» قياسُه من v2_response_check — حكمُه ومستندُه كما يرجعان
  const committeeTasks = () => ((ui.files && ui.files.tasks) || []).filter((t) => t.kind === 'committee');
  async function loadResponse(stu) {
    await Promise.all(committeeTasks().map(async (t) => {
      const r = await M.rpc('v2_response_check', { p_record: t.record_id }, 'قياس الاستجابة');
      if (ui.stu === stu && ui.files) ui.files.resp.set(t.task_id, r);
    }));
    if (ui.stu === stu) renderResponse();
  }

  function respInfo(r) {
    const box = el('div');
    if (r.state_ar) box.appendChild(el('p', r.state === 'failed' ? 'rs-state-open' : 'rs-state-done', r.state_ar));
    if (r.why) box.appendChild(el('div', 'rs-note', r.why));
    if (r.pre_ar != null || r.post_ar != null) {
      const lg = el('div', 'rs-lgd');
      lg.append(el('i', 'k', 'قبل الخطّة:'), el('i', null, r.pre_ar || '—'), el('i', 'k', 'بعدها:'), el('i', null, r.post_ar || '—'));
      if (r.dates) lg.append(el('i', 'k', 'تواريخُه:'), el('i', null, r.dates));
      if (r.by) lg.append(el('i', 'k', 'المستند:'), el('i', null, r.by));
      box.appendChild(lg);
    }
    if (r.rule) box.appendChild(el('p', 'rs-meta', r.rule));
    return box;
  }

  function renderResponse() {
    const box = $('resp');
    if (!box) return;
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const ts = committeeTasks();
    if (!ts.length) { box.appendChild(el('p', 'rs-empty', 'لم يبلغ ملفٌّ الإجراءَ الرابع.')); return; }
    for (const t of ts) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, (t.problem_ar || '') + (t.step_ar ? ' — الإجراء ' + t.step_ar : '')));
      const res = ui.files.resp.get(t.task_id);
      if (!res) f.appendChild(el('p', 'rs-meta', 'جارٍ القياس…'));
      else if (res.error) f.appendChild(el('div', 'notice err', errText(res.error)));
      else {
        f.appendChild(respInfo(res.data || {}));
        if (t.status === 'open' && res.data && res.data.can_refer) f.appendChild(btn('أحِل الملفَّ إلى اللجنة', 'rs-btn', () => referForm(t)));
      }
      box.appendChild(f);
    }
    arabize(box);
  }

  // الإحالة: القياسُ أوّلًا — فإن لم تُفتح عُرض سببُه كما رجع، وإلا فسببُ الإحالة والمطلوبُ من اللجنة
  async function referForm(t) {
    const { data, error } = await M.rpc('v2_response_check', { p_record: t.record_id }, 'قياس الاستجابة');
    if (error) { V.flash('bad', errText(error)); return; }
    const r = data || {};
    const m = metaOf(t.problem_ar);
    const head = { key: 'resp', type: 'node', node: respInfo(r) };
    if (!r.can_refer) {
      V.form({ title: 'الإحالةُ إلى لجنة التوجيه', what: t.problem_ar || '', fields: [head], ok: false, cancel: 'فهمت' });
      return;
    }
    V.form({
      title: 'الإحالةُ إلى لجنة التوجيه', what: t.problem_ar || '',
      fields: [head,
        { key: 'why', type: 'textarea', label: 'سببُ الإحالة', bank: { key: 'referWhy', problem: m ? m.id : null } },
        { key: 'ask', type: 'textarea', label: 'المطلوبُ من اللجنة', bank: { key: 'referAsk', problem: m ? m.id : null } },
      ],
      ok: 'أحِل الملفّ',
      onOk: async (v) => {
        const { data: d, error: e } = await M.rpc('v2_refer_committee', { p_record: t.record_id, p_task: t.task_id, p_why: v.why, p_ask: v.ask }, 'الإحالة إلى اللجنة');
        if (e) return e;
        setTimeout(() => fileSheet(d || {}), 0);
        loadStudentCards();
        return null;
      },
    });
  }

  // ملفُّ الإحالة كاملًا كما رجع من v2_refer_committee
  function fileSheet(d) {
    const f = d.file || {};
    const box = el('div');
    const lg = el('div', 'rs-lgd');
    for (const [k, v] of [['الطالب', f.student], ['السلوك', f.problem], ['الرصدات', f.occurrences_ar], ['المحسوم', f.deducted_ar], ['حصرُ السلوكيّات', f.census], ['دراسةُ الحالة', f.case]]) {
      lg.append(el('i', 'k', k + ':'), el('i', null, v == null ? '—' : String(v)));
    }
    box.appendChild(lg);
    if (f.response) box.appendChild(respInfo(f.response));
    V.flash('ok', d.note || 'أُحيل الملفّ');
    V.form({ title: 'ملفُّ الإحالة', what: d.note || '', fields: [{ key: 'file', type: 'node', node: box }], ok: false, cancel: 'تمّ' });
  }

  // ---------- حصرُ السلوكيّات ----------
  // كما يرجع v2_census_of: «حصرُك» أو «حصرُ المكلَّف (فلان)» · وneg[] وpos[] بأيقوناتها · وsummary
  const chips = (list) => {
    const b = el('div', 'rs-pick ico');
    for (const x of list || []) { const s = el('span', 'k'); s.append(el('b', null, x.icon || '•'), document.createTextNode(x.text)); b.appendChild(s); }
    return b;
  };
  function renderCensus() {
    const box = $('census');
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const r = ui.files.census || {};
    if (r.error) box.appendChild(el('div', 'notice err', errText(r.error)));
    const list = r.data || [];
    if (!list.length && !r.error) box.appendChild(el('p', 'rs-empty', 'لم تُحصر سلوكيّاتُه بعد.'));
    for (const c of list) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, (c.who || '') + ' — ' + (c.state || '')));
      if (!c.by_self) {
        const p = el('p', c.late ? 'rs-state-open' : null, ['كلّفه ' + (c.by || '—'), 'في ' + (c.assigned_at || '—'), 'يُسلَّم ' + (c.due || '—'), c.late ? 'انقضت مدّتُه' : null].filter(Boolean).join(' · '));
        f.appendChild(p);
      }
      if (c.returned_why) f.appendChild(el('p', null, 'أُعيد: ' + c.returned_why));
      if (c.summary) f.appendChild(el('p', 'rs-meta', c.summary));
      if ((c.neg || []).length) { f.appendChild(el('div', 'rs-label', 'السلبيّة')); f.appendChild(chips(c.neg)); }
      if ((c.pos || []).length) { f.appendChild(el('div', 'rs-label', 'الإيجابيّة')); f.appendChild(chips(c.pos)); }
      if (c.causes || c.suggestion) {
        const lg = el('div', 'rs-lgd');
        if (c.causes) lg.append(el('i', 'k', 'المسبّبات:'), el('i', null, c.causes));
        if (c.suggestion) lg.append(el('i', 'k', 'المقترح:'), el('i', null, c.suggestion));
        f.appendChild(lg);
      }
      if (ui.full && c.state === 'مكتمل' && !c.by_self) {
        const row = el('div', 'rs-row');
        row.append(btn('اقبله', 'rs-btn', () => reviewCensus(c, true, null)), btn('أعِده بسبب', 'rs-btn ghost', () => returnCensus(c)));
        f.appendChild(row);
      }
      box.appendChild(f);
    }
    const row = el('div', 'rs-row');
    row.appendChild(btn('أحصرُ بنفسي', 'rs-btn', () => selfCensus()));
    if (ui.full) row.appendChild(btn('أكلّف به أحدًا', 'rs-btn soft', () => assignCensus()));
    if (ui.full) row.appendChild(btn('أعِد ما انقضت مدّتُه', 'rs-btn ghost', sweepCensus));
    box.appendChild(row);
    arabize(box);
  }

  // قوائمُ الحصر لمدرسة الشاشة — مرّةً لكلّ مدرسة
  async function censusLists() {
    if (ui.lists && ui.lists.school === M.state.school) return ui.lists;
    const { data, error } = await M.rpc('v2_census_list', { p_school: M.state.school }, 'قوائم الحصر');
    if (error) { V.flash('bad', errText(error)); return null; }
    ui.lists = { school: M.state.school, negative: (data && data.negative) || [], positive: (data && data.positive) || [] };
    return ui.lists;
  }

  async function selfCensus(pre) {
    const stu = ui.stu;
    const L = await censusLists();
    if (!L) return;
    const tf = taskField('follow_up', pre);
    const t = taskById(pre || (tf[0] && tf[0].value));
    const m = t && metaOf(t.problem_ar);
    V.form({
      title: 'حصرُ السلوكيّات — أحصرُ بنفسي', what: stu.display_name || stu.full_name,
      fields: [...tf,
        { key: 'neg', type: 'icons', label: 'السلوكيّاتُ السلبيّة', items: L.negative },
        { key: 'pos', type: 'icons', label: 'السلوكيّاتُ الإيجابيّة', items: L.positive },
        { key: 'causes', type: 'textarea', label: 'مسبّباتُ السلوك', bank: { key: 'cause', problem: m ? m.id : null } },
        { key: 'limit', type: 'textarea', label: 'مقترحُ الحدّ منه (اختياريّ)', rows: 2, bank: { key: 'limit', problem: m ? m.id : null } },
      ],
      ok: 'احفظ الحصر',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_census_self', { p_student: stu.student_id, p_task: v.task || null, p_neg: v.neg, p_pos: v.pos, p_causes: v.causes, p_limit: v.limit }, 'حصر السلوكيّات');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'حُفظ الحصر');
        loadStudentCards();
        return null;
      },
    });
  }

  async function sweepCensus() {
    const { data, error } = await M.rpc('v2_census_sweep', { p_school: M.state.school }, 'إعادة ما انقضت مدّته');
    if (error) { V.flash('bad', errText(error)); return; }
    V.flash('ok', (data && data.note) || 'تمّ');
    loadStudentCards();
  }

  async function assignCensus(pre) {
    const stu = ui.stu;
    if (!ui.staff) {
      const { data, error } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
      if (error) { V.flash('bad', errText(error)); return; }
      ui.staff = data || [];
    }
    V.form({
      title: 'حصرُ السلوكيّات — أكلّف به أحدًا', what: stu.display_name || stu.full_name,
      fields: [...taskField('follow_up', pre),
        { key: 'who', type: 'choose', label: 'المكلَّف', items: ui.staff.map((p) => [p.person_id, p.name_ar, p.post_ar || p.roles_ar || '']) },
        { key: 'days', type: 'number', label: 'المدّةُ بالأيّام', value: 5, hint: 'من يومٍ إلى ثلاثين' },
      ],
      ok: 'كلّفه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_census_assign', { p_student: stu.student_id, p_task: v.task || null, p_person: v.who, p_days: v.days }, 'التكليف بالحصر');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'كُلّف بالحصر');
        loadStudentCards();
        return null;
      },
    });
  }

  async function reviewCensus(c, accept, why) {
    V.flash('wait', accept ? 'يُقبل الحصر…' : 'يُعاد الحصر…');
    const { data, error } = await M.rpc('v2_census_review', { p_census: c.census, p_accept: accept, p_why: why }, 'النظر في الحصر');
    if (error) { V.flash('bad', errText(error)); return error; }
    V.flash('ok', (data && data.note) || 'تمّ');
    loadStudentCards();
    return null;
  }

  function returnCensus(c) {
    V.form({
      title: 'إعادةُ الحصر لصاحبه', what: c.who || '',
      fields: [{ key: 'why', type: 'textarea', label: 'السبب' }],
      ok: 'أعِده',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_census_review', { p_census: c.census, p_accept: false, p_why: v.why }, 'النظر في الحصر');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'أُعيد');
        loadStudentCards();
        return null;
      },
    });
  }

  M.start({ screen: 'wakeel', onChange: () => refresh() });
})();
