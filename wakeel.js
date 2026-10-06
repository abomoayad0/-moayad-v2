// مؤيّد · شاشة الوكيل — viewW في المحاكي: ستُّ بطاقات، والفعلُ الأكثرُ تكرارًا (الرصد) ضغطةٌ واحدةٌ بلا نافذة.
// كلُّ نصٍّ وعددٍ ودرجةٍ وسلّمٍ من القاعدة — والشاشةُ لا تحسب ولا تؤلّف، وما لم يُبنَ في المحرّك يُعرض معطَّلًا بسببه.
// v2_day_summary · v2_day_classes · v2_day_list · v2_periods · v2_conduct_list · v2_record_behavior · v2_record_amend
// v2_entries_pending · v2_form_open(5) · v2_student_card · v2_student_tasks · v2_student_timeline(p_student, null)
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
  function flash(kind, text, acts) {
    const f = $('flash');
    f.className = 'flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (acts && acts.length) {
      const row = el('span', 'rs-row');
      for (const a of acts) row.appendChild(a);
      f.appendChild(row);
    }
    f.hidden = false;
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
    ]);
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
    // v2_student_tasks بأسمائه الجديدة: task · text · problem · kind · kind_ar
    ui.files = { card: card.data || {}, tasks: (tasks.data || []).map((t) => Object.assign({}, t, { task_id: t.task_id || t.task, text_ar: t.text_ar || t.text, problem_ar: t.problem_ar || t.problem })), timeline: tl.data || {}, form5: f5, contacts: ct, census: cn, error: card.error || tasks.error || tl.error };
    renderStudentCards();
  }

  function renderStudentCards() {
    const show = !!ui.stu;
    $('f5Card').hidden = !show || !ui.full; $('respCard').hidden = !show; $('tlCard').hidden = !show;
    $('contactCard').hidden = !show; $('censusCard').hidden = !show;
    if (ui.full) renderForm5();
    renderFiles(); renderTimeline(); renderContacts(); renderCensus();
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
    const meta = ui.problems.find((p) => p.text === prob || p.text === String(prob).replace(/\.\s*$/, ''));
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
      if (tf && ui.full) acts.appendChild(btn('التكليفُ بالحصر', 'rs-btn soft', () => assignCensus(tf.task_id)));
      // خطابُ الدعوة (نموذج ١٠) والإحالةُ للّجنة (نموذج ١٢): يُنجزان من لوح المهمّة — إثباتُها ونموذجُها من القاعدة
      if (has('summon_guardian')) acts.appendChild(btn('خطابُ الدعوة', 'rs-btn soft', showTasks));
      if (has('committee')) acts.appendChild(btn('الإحالةُ للّجنة', 'rs-btn soft', showTasks));
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
        li.append(el('i', 'rs-tick' + (x.outcome === 'ردّ وعلم' ? ' ok' : ''), x.outcome === 'ردّ وعلم' ? '✓' : '○'), body, el('small', 'rs-who', [x.on, x.at ? String(x.at).slice(0, 5) : null].filter(Boolean).join(' ')));
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

  function contactForm(pre) {
    const stu = ui.stu;
    V.form({
      title: 'إثباتُ الاتّصال بوليّ الأمر', what: stu.display_name || stu.full_name,
      fields: [...taskField('notify_guardian', pre),
        { key: 'channel', type: 'pick', label: 'الوسيلة', items: CHANNELS.map((x) => [x, x]) },
        { key: 'outcome', type: 'pick', label: 'النتيجة', items: OUTCOMES.map((x) => [x, x]) },
        { key: 'summary', type: 'textarea', label: 'ما دار' },
        { key: 'say', type: 'textarea', label: 'ما قاله وليُّ الأمر (اختياري)', rows: 2 },
        { key: 'at', type: 'time', label: 'الساعة (اختياري)' },
      ],
      ok: 'أثبته',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_contact_log', {
          p_student: stu.student_id, p_task: v.task || null, p_channel: v.channel, p_outcome: v.outcome,
          p_summary: v.summary, p_guardian_say: v.say, p_at: v.at,
        }, 'إثبات الاتصال');
        if (error) return error;
        // النصُّ من القاعدة، وهو يتبع closed
        V.flash('ok', ((data && data.note) || 'أُثبت الاتّصال') + ' · المحاولةُ ' + ((data && data.attempt) || ''));
        loadStudentCards();
        return null;
      },
    });
  }

  // ---------- حصرُ السلوكيّات ----------
  function renderCensus() {
    const box = $('census');
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const r = ui.files.census || {};
    if (r.error) box.appendChild(el('div', 'notice err', errText(r.error)));
    const list = r.data || [];
    if (!list.length && !r.error) box.appendChild(el('p', 'rs-empty', 'لم يُكلَّف أحدٌ بحصر سلوكيّاته.'));
    for (const c of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (c.to || '') + ' — ' + (c.state || '')),
        el('p', null, ['كلّفه ' + (c.by || '—'), 'في ' + (c.assigned_at || '—'), 'يُسلَّم ' + (c.due || '—')].join(' · ')));
      if (c.returned_why) f.appendChild(el('p', null, 'أُعيد: ' + c.returned_why));
      if (c.filed_at) {
        const lg = el('div', 'rs-lgd');
        lg.append(el('i', 'k', 'الإيجابيّ:'), el('i', null, c.positives || '—'), el('i', 'k', 'السلبيّ:'), el('i', null, c.negatives || '—'),
          el('i', 'k', 'المسبّبات:'), el('i', null, c.causes || '—'));
        if (c.suggestion) lg.append(el('i', 'k', 'المقترح:'), el('i', null, c.suggestion));
        f.appendChild(lg);
      }
      if (ui.full && c.state === 'مكتمل') {
        const row = el('div', 'rs-row');
        row.append(btn('اقبله', 'rs-btn', () => reviewCensus(c, true, null)), btn('أعِده بسبب', 'rs-btn ghost', () => returnCensus(c)));
        f.appendChild(row);
      }
      box.appendChild(f);
    }
    // ولا تكليفَ بلا مهمّة «حصر السلوكيّات» مفتوحة
    if (ui.full && openTasks('follow_up').length) box.appendChild(btn('كلّف بالحصر', 'rs-btn', () => assignCensus()));
    arabize(box);
  }

  async function assignCensus(pre) {
    const stu = ui.stu;
    if (!ui.staff) {
      const { data, error } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
      if (error) { V.flash('bad', errText(error)); return; }
      ui.staff = data || [];
    }
    V.form({
      title: 'التكليفُ بحصر السلوكيّات', what: stu.display_name || stu.full_name,
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
      title: 'إعادةُ الحصر لصاحبه', what: c.to || '',
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
