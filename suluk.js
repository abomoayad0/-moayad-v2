// مؤيّد · رصد المخالفات — على مواصفة المحاكي (viewW · record): بطاقةٌ واحدةٌ مفتوحة، وضغطةٌ واحدةٌ ترصد ولا نافذة.
// الفصلُ ثمّ الطالب ثمّ السلوك، والحصّةُ حين يطلبها السلوك (needs_period) وحدَها.
// كلُّ نصٍّ وعددٍ ودرجةٍ وسلّمٍ من القاعدة — والشاشةُ لا تحسب ولا تؤلّف:
// v2_day_summary · v2_day_classes · v2_day_list · v2_conduct_list · v2_record_behavior
// v2_student_card · v2_student_tasks · v2_student_timeline — وإنجازُ المهامّ بإثباتها في tasks.js
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;

  // الحصصُ كما رسمتها المواصفة (① — ⑦) — ولا جسرَ يرجع حصصَ المدرسة لكلّ من يرصد بعد
  const PERIODS = [1, 2, 3, 4, 5, 6, 7];

  const ui = { classes: [], rows: [], problems: [], cls: null, stu: null, prob: null, period: null, busy: false, files: null };

  // الأرقامُ عربيّةٌ في العرض كلِّه — تحويلُ أرقامٍ لا حساب
  const ar = (v) => String(v == null ? '' : v).replace(/[0-9]/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  // شريطُ التاريخ مشتركٌ بين الشاشات (common.js) — فتُعرَّب أرقامُه هنا ولا يُمسّ هناك
  function arabize(node) {
    const w = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    for (let t = w.nextNode(); t; t = w.nextNode()) t.nodeValue = ar(t.nodeValue);
  }
  const fill = (sel, items, first) => {
    sel.textContent = '';
    if (first) sel.appendChild(new Option(first, ''));
    for (const [v, t] of items) sel.appendChild(new Option(t, v));
  };

  // ---------- الجلب ----------
  async function refresh() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    const args = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, list] = await Promise.all([
      M.rpc('v2_day_summary', args),
      M.rpc('v2_day_classes', args),
      M.rpc('v2_day_list', args),
    ]);
    const err = sum.error || cls.error || list.error;
    if (err) { showLoadErr('تعذّر الجلب: ' + errText(err)); return; }
    const s = sum.data && sum.data[0];
    if (s) { M.renderDates($('dates'), s.hijri, M.state.date, null); arabize($('dates')); }
    ui.classes = cls.data || [];
    // 🔴 الغائبُ لا يظهر في القائمة أصلًا — والقاعدةُ ترفضه إن وصل
    ui.rows = (list.data || []).filter((r) => r.state !== 'absent');
    fill($('cls'), ui.classes.map((c) => [c.grade + '|' + c.section, ar(c.label_ar)]), 'اختر الفصل');
    resetStudent();
    renderFiles();
  }

  function resetStudent() {
    ui.cls = null; ui.stu = null; ui.problems = []; ui.prob = null; ui.period = null; ui.files = null;
    fill($('stu'), [], 'اختر الطالب');
    $('stu').disabled = true;
    resetProblem();
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

  // ---------- الفصل ثمّ الطالب ----------
  $('cls').addEventListener('change', () => {
    resetStudent();
    const v = $('cls').value;
    if (!v) { renderFiles(); return; }
    ui.cls = ui.classes.find((c) => c.grade + '|' + c.section === v) || null;
    const list = ui.rows.filter((r) => ui.cls && r.grade === ui.cls.grade && r.section === ui.cls.section);
    fill($('stu'), list.map((r) => [r.student_id, (r.display_name || r.full_name) + (r.student_no ? ' · ' + ar(r.student_no) : '')]),
      list.length ? 'اختر الطالب' : 'لا حاضرَ في هذا الفصل');
    $('stu').disabled = !list.length;
    renderFiles();
  });

  $('stu').addEventListener('change', async () => {
    resetProblem();
    ui.stu = ui.rows.find((r) => r.student_id === $('stu').value) || null;
    ui.files = null;
    renderFiles();
    if (!ui.stu) return;
    const stu = ui.stu;
    fill($('prob'), [], 'جارٍ جلب السلوكيّات…');
    const { data, error } = await M.rpc('v2_conduct_list', { p_student: stu.student_id, p_mode: 'onsite', p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== stu) return;
    if (error) { fill($('prob'), [], 'تعذّر الجلب'); flash('bad', errText(error)); return; }
    ui.problems = data || [];
    $('qProb').disabled = false;
    renderProblems();
    loadFiles();
  });

  // ---------- السلوك: قائمةٌ ببحث، وكلٌّ بدرجته وسنده ----------
  function probLabel(p) {
    return p.text + ' — ' + ar(p.degree_ar) + (p.source ? ' · ' + ar(p.source) : '');
  }
  function renderProblems() {
    const q = $('qProb').value.trim();
    const list = ui.problems.filter((p) => !q || (p.text || '').includes(q));
    const keep = ui.prob && list.includes(ui.prob) ? String(ui.prob.id) : '';
    fill($('prob'), list.map((p) => [String(p.id), probLabel(p)]), list.length ? 'اختر السلوك' : 'لا سلوكَ بهذا البحث');
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

  // ---------- الحصّة: شرائطُ تُلمس — حين needs_period وحدَها ----------
  function renderPeriods() {
    const show = !!(ui.prob && ui.prob.needs_period);
    $('periodBox').hidden = !show;
    const box = $('periods');
    box.textContent = '';
    if (!show) return;
    for (const n of PERIODS) {
      const s = el('span', ui.period === n ? 'on' : null, ar(n));
      s.setAttribute('role', 'button');
      s.tabIndex = 0;
      s.setAttribute('aria-pressed', String(ui.period === n));
      const pick = () => { ui.period = ui.period === n ? null : n; renderPeriods(); };
      s.addEventListener('click', pick);
      s.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); pick(); } });
      box.appendChild(s);
    }
  }

  function syncButton() { $('rec').disabled = ui.busy || !ui.stu || !ui.prob; }

  // ---------- الشريط: يظهر فورًا ثمّ يُبدَّل بما ترجعه القاعدة ----------
  function flash(kind, text, withOpen) {
    const f = $('flash');
    f.className = 'rs-flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (withOpen) {
      const b = el('button', 'rs-btn soft', 'افتح الملفّ');
      b.type = 'button';
      b.addEventListener('click', () => { const t = $('files'); if (t) t.scrollIntoView({ behavior: 'smooth', block: 'start' }); });
      f.appendChild(b);
    }
    f.hidden = false;
  }

  // ---------- ارصد: ضغطةٌ واحدة ----------
  $('rec').addEventListener('click', async () => {
    if (!ui.stu || !ui.prob || ui.busy) return;
    const stu = ui.stu; const p = ui.prob;
    ui.busy = true; syncButton();
    // ١ · الأثرُ فورًا — حالُ «يُرسل»، ولا درجةَ تُنقص قبل ردّ القاعدة
    flash('wait', 'يُرسل… ' + p.text);
    // ٢ · القاعدة
    const { data, error } = await M.rpc('v2_record_behavior', {
      p_student: stu.student_id, p_problem: p.id, p_period: p.needs_period ? ui.period : null,
    }, 'رصد مخالفة');
    ui.busy = false; syncButton();
    // ٣ · رُفض ⇒ نصُّ الرفض كما هو · نجح ⇒ ما رجع من القاعدة كما هو
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', ar((data && data.headline) || 'رُصدت المخالفة'), true);
    ui.period = null;
    // القائمةُ والملفّاتُ تُقرأ من القاعدة بعد الرصد
    const { data: fresh } = await M.rpc('v2_conduct_list', { p_student: stu.student_id, p_mode: 'onsite', p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== stu) return;
    if (fresh) { ui.problems = fresh; ui.prob = ui.problems.find((x) => x.id === p.id) || null; }
    renderProblems(); renderPeriods();
    loadFiles();
  });

  // ---------- ٢ · ملفّاتُ الطالب ----------
  async function loadFiles() {
    const stu = ui.stu;
    if (!stu) return;
    const [card, tasks, tl] = await Promise.all([
      M.rpc('v2_student_card', { p_student: stu.student_id }, 'بطاقة الطالب'),
      M.rpc('v2_student_tasks', { p_student: stu.student_id }, 'مهامّ الطالب'),
      M.rpc('v2_student_timeline', { p_student: stu.student_id, p_as: null }, 'السجلّ الزمنيّ'),
    ]);
    if (ui.stu !== stu) return;
    ui.files = { card: card.data || {}, tasks: tasks.data || [], timeline: tl.data || {}, error: card.error || tasks.error || tl.error };
    renderFiles();
  }

  function renderFiles() {
    const box = $('files');
    box.textContent = '';
    if (!ui.stu) return;
    if (!ui.files) { box.appendChild(el('div', 'rs-card', 'جارٍ جلب ملفّات الطالب…')); return; }
    if (ui.files.error) { box.appendChild(el('div', 'notice err', 'تعذّر جلب الملفّات: ' + errText(ui.files.error))); return; }
    const recs = ui.files.card.behavior || [];
    if (!recs.length) {
      const c = el('div', 'rs-card');
      c.appendChild(el('p', 'rs-empty', 'لا ملفّاتٍ لهذا الطالب — ارصد لترى'));
      box.appendChild(c);
      return;
    }
    // لكلّ سلوكٍ ملفُّه: آخرُ رصدةٍ فيه هي حالُه — كما رجعت من القاعدة (مرتّبةً بالأحدث)
    const byProb = new Map();
    for (const r of recs) if (!byProb.has(r.problem)) byProb.set(r.problem, { last: r, n: recs.filter((x) => x.problem === r.problem).length });
    for (const [prob, f] of byProb) box.appendChild(fileCard(prob, f));
    // السجلُّ الزمنيُّ للطالب — مطويٌّ، ولا يُفتح افتراضيًّا
    const evs = ui.files.timeline.events || [];
    const c = el('div', 'rs-card');
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, 'السجلُّ الزمنيّ (' + ar(evs.length) + ')'));
    const body = el('div', 'rs-dtb');
    for (const e of evs) body.appendChild(el('div', null, ar(e.on || '') + ' · ' + (e.title || '') + (e.body ? ' — ' + e.body : '')));
    if (!evs.length) body.appendChild(el('div', null, 'لا أحداثَ بعد.'));
    det.appendChild(body);
    c.appendChild(det);
    box.appendChild(c);
  }

  function fileCard(prob, f) {
    const r = f.last;
    const c = el('div', 'rs-card');
    const hd = el('div', 'rs-hd');
    hd.append(el('h3', null, prob), el('span', 'rs-occ', 'الرصدةُ ' + ar(r.occurrence)));
    c.appendChild(hd);
    // الدرجةُ والسندُ من قائمة السلوكيّات — والسلّمُ: عددُ خطواته (steps) وخطوتُه الحاليّة (step) من القاعدة
    const meta = ui.problems.find((p) => p.text === prob);
    c.appendChild(el('p', 'rs-meta', [meta ? ar(meta.degree_ar) : '', meta && meta.source ? ar(meta.source) : '',
      'آخرُ رصدة ' + ar(r.on_h || r.on)].filter(Boolean).join(' · ')));
    const steps = meta && meta.steps ? Number(meta.steps) : null;
    if (steps && r.step) {
      const lad = el('div', 'rs-pick rs-ladder');
      lad.appendChild(el('span', 'k', 'السلّم:'));
      for (let i = 1; i <= steps; i++) {
        const cls = i < r.step ? 'done' : (i === Number(r.step) ? 'on' : 'soon');
        lad.appendChild(el('span', cls, ar(i) + (i < r.step ? ' ✓' : i === Number(r.step) ? ' ●' : '')));
      }
      c.appendChild(lad);
    }
    // ما على الإجراء الحاليّ — مهامُّ هذا السلوك كما رجعت
    const ts = ui.files.tasks.filter((t) => t.problem_ar === prob);
    if (ts.length) {
      c.appendChild(el('div', 'rs-label', 'ما على الإجراء:'));
      const ul = el('ul', 'rs-acts');
      for (const t of ts) {
        const li = el('li');
        const done = t.status !== 'open';
        li.append(el('i', 'rs-tick' + (done ? ' ok' : ''), done ? '✓' : '○'), el('span', null, t.text_ar), el('span', 'rs-who', t.owner_ar || t.owner_role || ''));
        ul.appendChild(li);
      }
      c.appendChild(ul);
      const open = ts.filter((t) => t.status === 'open').length;
      if (open) {
        const b = el('button', 'rs-btn soft', 'أنجز المهامّ (' + ar(open) + ')');
        b.type = 'button';
        const tbox = el('div');
        b.addEventListener('click', () => { b.hidden = true; window.MoayadTasks.render(tbox, ui.stu.student_id); });
        c.append(b, tbox);
      }
    }
    // رصداتُ هذا السلوك بتواريخها — مطويّة، ولا تُفتح افتراضيًّا
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, 'رصداتُه (' + ar(f.n) + ')'));
    const body = el('div', 'rs-dtb');
    for (const x of (ui.files.card.behavior || []).filter((y) => y.problem === prob)) {
      body.appendChild(el('div', null, 'الرصدةُ ' + ar(x.occurrence) + ' · ' + ar(x.on_h || x.on) + (x.place ? ' · ' + x.place : '')));
    }
    det.appendChild(body);
    c.appendChild(det);
    return c;
  }

  M.start({ screen: 'suluk', onChange: () => refresh() });
})();
