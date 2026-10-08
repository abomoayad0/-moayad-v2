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
    loadMode();
    renderClasses();
    resetStudent();
    // ما ليس للمعلّم: الشواهد والنموذج ٥ والتكليفُ بالحصر — بمفتاح wakeel_full (الوكيلُ والمدير)
    ui.full = !!(M.state.me && M.state.me.can && M.state.me.can.wakeel_full);
    $('evCard').hidden = !ui.full;
    if (ui.full) loadEvidence();
    loadOpen();
  }

  // ---------- صدرُ الشاشة: v2_open_records ----------
  // summary_ar سطرٌ بارز · والصفوفُ بترتيبها كما ترجع (الأقدمُ أوّلًا) · ولا أحمرَ ولا مدّة · و note_ar تحت القائمة كما هو
  // ومن ينتظر لجنةً بلون support.1 ومعه why_ar — فلا يُحسب إهمالًا
  let openSeq = 0;
  async function loadOpen() {
    const card = $('openCard');
    if (!ui.full || !M.state.school) { card.hidden = true; return; }
    const seq = ++openSeq;
    const { data, error } = await M.rpc('v2_open_records', { p_school: M.state.school }, 'الرصدات المفتوحة');
    if (seq !== openSeq) return;
    card.hidden = false;
    const d = data || {};
    $('openSum').textContent = error ? '' : (d.summary_ar || '');
    $('openNote').textContent = error ? '' : (d.note_ar || '');
    const box = $('openList');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = d.rows || [];
    if (!rows.length) return; // summary_ar يقول ذلك بجملته
    const w = el('div', 'rs-tablewrap');
    const tb = el('table', 'rs-table rs-open');
    const hr = el('tr');
    for (const h of ['الطالب', 'المخالفة', 'الرصدة', 'منذ', 'المفتوح', 'أقدمُ بندٍ مفتوح', 'الحال', '']) hr.appendChild(el('th', null, h));
    const th = el('thead'); th.appendChild(hr); tb.appendChild(th);
    const body = el('tbody');
    for (const r of rows) {
      const tr = el('tr', r.waits_committee ? 'wait' : null);
      const td = (...n) => { const c = el('td'); c.append(...n); tr.appendChild(c); return c; };
      const who = el('b', null, r.student_ar || '');
      const c1 = td(who);
      if (r.is_test) c1.appendChild(el('span', 'rs-tag', 'تجريبيّة'));
      td(document.createTextNode([r.problem_ar, r.degree_ar, r.step_ar ? 'الإجراء ' + r.step_ar : null].filter(Boolean).join(' · ')));
      td(document.createTextNode([r.occurrence_ar, r.on_date].filter(Boolean).join(' · ')));
      td(document.createTextNode(r.age_ar || ''));
      td(document.createTextNode(r.open_ar || ''));
      td(document.createTextNode((r.oldest_item_ar || '') + (r.oldest_owner_ar ? ' — عند ' + r.oldest_owner_ar : '')));
      const st = td(el('span', 'rs-state ' + (r.waits_committee ? 'wait' : 'open'), r.state_ar || ''));
      if (r.why_ar) st.appendChild(el('div', 'rs-why', r.why_ar));
      const acts = el('div', 'rs-row');
      acts.append(btn('افتح ملفَّه', 'rs-btn', () => openFromRow(r)),
        btn('ألغِ الرصدة', 'rs-btn irrev', () => voidForm(r)));
      td(acts);
      body.appendChild(tr);
    }
    tb.appendChild(body);
    w.appendChild(tb);
    box.appendChild(w);
    arabize(box);
  }

  // من صفّ القائمة إلى ملفّ الطالب: فصلُه من قائمة اليوم إن كان فيها، وإلا فبرقمه واسمه كما رجعا
  function openFromRow(r, prob) {
    const row = (ui.rows || []).find((x) => x.student_id === r.student) || { student_id: r.student, display_name: r.student_ar, full_name: r.student_ar };
    const c = ui.classes.find((x) => x.grade === row.grade && x.section === row.section);
    if (c) { ui.cls = c; renderClasses(); $('qStu').disabled = false; }
    openStudent(row).then(() => {
      if (c) renderStudents();
      const go = () => { const t = prob && [...document.querySelectorAll('#files .rs-card h3')].find((h) => h.textContent.replace(/\.\s*$/, '') === String(prob).replace(/\.\s*$/, '')); (t ? t.closest('.rs-card') : $('files')).scrollIntoView({ behavior: 'smooth', block: 'start' }); };
      setTimeout(go, 600);
    });
  }

  // ---------- بابُ الإلغاء: v2_record_void ----------
  // السببُ · ثمّ كلمةُ الحارس «أُلغي» بيد المستعمل (لا تُملأ ولا تُقترح) · ثمّ ما يقع بالإلغاء · والزرُّ بحدٍّ تحذيريّ في آخر الشريط
  // ولا يُخفى بحساب الشاشة: يُضغط، والجسرُ يقول من يملكه ومتى
  function voidForm(r) {
    V.form({
      title: 'إلغاءُ الرصدة',
      what: [r.student_ar, r.problem_ar, r.occurrence_ar ? 'الرصدة ' + r.occurrence_ar : null, r.on_date].filter(Boolean).join(' · '),
      fields: [
        { key: 'reason', type: 'textarea', label: 'سببُ الإلغاء *', rows: 3, hint: 'يبقى السببُ في الملفّ باسمك — ولا يُحذف الصفُّ الأصليّ' },
        { key: 'confirm', label: 'اكتب «أُلغي» لتأكيده *' },
        { key: 'what', type: 'node', node: el('div', 'rs-info', 'وبالإلغاء: تُردُّ الدرجاتُ المحسومة · وتُسحب النماذجُ الخارجة · ويُعلَم وليُّ الأمر بالسحب') },
      ],
      ok: 'أُلغي الرصدة',
      okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_record_void', { p_record: r.record, p_reason: v.reason, p_confirm: v.confirm }, 'إلغاء رصدة');
        if (error) {
          // «أَلغِ أوّلًا: …» ⇒ النصُّ كما هو، ومعه زرٌّ ينقله إلى ملفّ تلك الرصدات
          if (/أَلغِ أوّلًا/.test(String(error.message || ''))) {
            return { text: errText(error), acts: [btn('انتقل إلى تلك الرصدات', 'rs-btn', () => { $('flash').hidden = true; document.querySelector('.rs-modal:not([hidden])') && (document.querySelector('.rs-modal:not([hidden])').hidden = true); openFromRow(r, r.problem_ar); })] };
          }
          return error;
        }
        if (!data || data.ok !== true) return 'لم يُلغِ الجسرُ الرصدة';
        // note_ar كاملًا: ما رُدّ وما سُحب ومن أُعلم — وأنّ ما كسبه الطالبُ من تعويضٍ لا يُستردّ
        flash('ok', data.note_ar || '');
        loadOpen();
        if (ui.stu) loadStudentCards();
        return null;
      },
    });
  }

  // نمطُ التعليم في رأس الشاشة كما يرجع من v2_problems (mode_ar · note_ar) — والسلّمُ الآخرُ لا يُعرض
  async function loadMode() {
    const box = $('modeLine');
    const { data, error } = await M.rpc('v2_problems', { p_school: M.state.school, p_degree: null }, 'نمط التعليم');
    box.hidden = false;
    box.className = error ? 'notice err' : 'rs-note';
    box.textContent = error ? errText(error) : ((data && (data.note_ar || data.mode_ar)) || '');
    if (!box.textContent) box.hidden = true;
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
      V.tap(s, pick);
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
    const { data, error } = await M.rpc('v2_conduct_list', { p_student: r.student_id, p_mode: null, p_target: 'general' }, 'قائمة المخالفات');
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
  // على iPhone يقع change ثانيةً حين تُغلق عجلةُ الاختيار بلمس شريطة الحصّة — فلا تُمحى الحصّةُ إلا إن تغيّر السلوكُ فعلًا
  $('prob').addEventListener('change', () => {
    const np = ui.problems.find((p) => String(p.id) === $('prob').value) || null;
    if (np === ui.prob) return;
    ui.prob = np;
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
    // تُبنى مرّةً وتُعلَّم في موضعها — والحصّةُ تُحفظ لحظةَ اللمس
    const mark = () => { for (const c of box.children) { const on = Number(c.dataset.no) === ui.period; c.classList.toggle('on', on); c.setAttribute('aria-pressed', String(on)); } };
    for (const p of ui.periods) {
      const s = el('span', null, p.no_ar);
      s.title = p.label || '';
      s.dataset.no = p.no;
      s.setAttribute('role', 'button'); s.tabIndex = 0;
      V.tap(s, () => { ui.period = ui.period === p.no ? null : p.no; mark(); });
      box.appendChild(s);
    }
    mark();
  }

  // «ارصد» لا يُعطَّل بحساب الشاشة: يُضغط، والجسرُ يردّ بنصّه إن نقص الطالبُ أو السلوكُ أو الحصّة
  function syncButton() { /* لا شيء — الإرسالُ وحدَه يُشغله (busyOn) */ }

  // ---------- شريطُ النتيجة ----------
  // auto: ما وقع آليًّا بالرصد كما رجع من القاعدة — {kind, text}
  function flash(kind, text, acts, auto) {
    const f = $('flash');
    f.className = 'flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (auto && auto.length) {
      const ul = el('ul', 'rs-auto');
      // وما لم يخرج («لم يخرج…») يُعرض أحمرَ بسببه — فالمهمّةُ باقيةٌ مفتوحة
      for (const a of auto) ul.appendChild(el('li', /^لم يخرج/.test(String(a.text || '')) ? 'bad' : null, (a.kind === 'advice' ? 'النصيحةُ التربويّة: ' : '') + a.text));
      f.appendChild(ul);
    }
    if (acts && acts.length) {
      const row = el('span', 'rs-row');
      for (const a of acts) row.appendChild(a);
      f.appendChild(row);
    }
    f.hidden = false;
    arabize(f);
    V.seen(f);
  }

  // ---------- ① ارصد: ضغطةٌ واحدة ----------
  $('rec').addEventListener('click', async () => {
    if (ui.busy) return;
    const stu = ui.stu; const p = ui.prob;
    ui.busy = true; V.busyOn($('rec'));
    // ١ · الأثرُ فورًا بحال «يُرسل» — ولا درجةَ تُنقص قبل ردّ القاعدة
    if (p) flash('wait', 'يُرسل… ' + p.text);
    // ٢ · القاعدة — وإن نقص شيءٌ فنصُّها يقول ما هو
    const { data, error } = await M.rpc('v2_record_behavior', {
      p_student: stu ? stu.student_id : null, p_problem: p ? p.id : null, p_period: p && p.needs_period ? ui.period : null,
    }, 'رصد مخالفة');
    ui.busy = false; V.busyOff($('rec'));
    // ٣ · رُفض ⇒ نصُّ الرفض كما هو · نجح ⇒ headline كما يرجع
    if (error) { flash('bad', errText(error)); return; }
    ui.last = { record: data && data.record, problem: data && data.problem, student: stu };
    flash('ok', (data && data.headline) || 'رُصدت المخالفة', [
      btn('افتح الملفّ', 'rs-btn soft', () => $('files').scrollIntoView({ behavior: 'smooth', block: 'start' })),
      btn('أضِف التفاصيل', 'rs-btn soft', () => openAmend()),
    ], (data && data.auto) || []);
    ui.period = null;
    // بعد كلّ رصدة: تُعاد قراءةُ البطاقة والمهامّ من القاعدة — فرقمُ الرصدة والإجراءُ كما صارا فيها
    loadStudentCards();
    loadOpen();
    const { data: fresh } = await M.rpc('v2_conduct_list', { p_student: stu.student_id, p_mode: null, p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== stu) return;
    if (fresh) { ui.problems = fresh; ui.prob = ui.problems.find((x) => x.id === p.id) || null; }
    renderProblems(); renderPeriods();
    renderFiles();
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
    // آخرُ نداءٍ هو الحاكم — فلا يغطّي ردٌّ قديمٌ وصل متأخّرًا ما بعده
    const seq = ui.seq = (ui.seq || 0) + 1;
    const [card, tasks, tl, f5, ct, cn, pl] = await Promise.all([
      M.rpc('v2_student_card', { p_student: stu.student_id }, 'بطاقة الطالب'),
      M.rpc('v2_student_tasks', { p_student: stu.student_id }, 'مهامّ الطالب'),
      M.rpc('v2_student_timeline', { p_student: stu.student_id, p_as: null }, 'سجلّ الملفّ'),
      ui.full ? M.rpc('v2_form_open', { p_form: 5, p_student: stu.student_id }, 'النموذج ٥') : Promise.resolve({}),
      M.rpc('v2_contacts_of', { p_student: stu.student_id }, 'سجلّ الاتّصال'),
      M.rpc('v2_census_of', { p_student: stu.student_id }, 'حصر السلوكيّات'),
      M.rpc('v2_plan_of', { p_student: stu.student_id }, 'خطّة تعديل السلوك'),
    ]);
    if (ui.stu !== stu || seq !== ui.seq) return;
    // v2_student_tasks بأسمائه الجديدة: task · record · text · problem · kind · kind_ar
    ui.files = { card: card.data || {}, tasks: (tasks.data || []).map((t) => Object.assign({}, t, { task_id: t.task_id || t.task, record_id: t.record_id || t.record, text_ar: t.text_ar || t.text, problem_ar: t.problem_ar || t.problem })), timeline: tl.data || {}, form5: f5, contacts: ct, census: cn, plans: pl, advice: new Map(), resp: new Map(), error: card.error || tasks.error || tl.error };
    renderStudentCards();
    loadAdvice(stu);
    loadResponse(stu);
    loadOpen();
  }

  // سلوكُ الملفّ بعناصره من v2_conduct_list — بنصّه كما يرجع في البطاقة
  const metaOf = (prob) => ui.problems.find((p) => p.text === prob || p.text === String(prob || '').replace(/\.\s*$/, '')) || null;

  // النصيحةُ التربويّة لآخر رصدةٍ في كلّ ملفّ: v2_advice_for(السلوك، رقمُ الرصدة) — نصُّها من القاعدة
  async function loadAdvice(stu) {
    const last = new Map();
    for (const r of (ui.files.card.behavior || [])) if (!last.has(r.problem) || Number(r.occurrence) > Number(last.get(r.problem).occurrence)) last.set(r.problem, r);
    await Promise.all([...last].map(async ([prob, r]) => {
      const m = metaOf(prob);
      if (!m) return;
      const { data } = await M.rpc('v2_advice_for', { p_problem: m.id, p_occurrence: r.occurrence, p_school: M.state.school }, 'النصيحة التربويّة');
      if (ui.stu === stu && ui.files && data && data.text) ui.files.advice.set(prob, data.text);
    }));
    if (ui.stu === stu) renderFiles();
  }

  function renderStudentCards() {
    const show = !!ui.stu;
    $('f5Card').hidden = !show || !ui.full; $('respCard').hidden = !show; $('tlCard').hidden = !show;
    $('contactCard').hidden = !show; $('censusCard').hidden = !show; $('planCard').hidden = !show;
    if (ui.full) renderForm5();
    renderFiles(); renderTimeline(); renderContacts(); renderCensus(); renderPlans(); renderResponse();
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
    // آخرُ رصدةٍ في كلّ ملفّ أعلاها رقمًا كما رجع — فالبطاقةُ ترتّب بالتاريخ وحده، ورصداتُ اليوم الواحد تتساوى فيه
    const byProb = new Map();
    for (const r of recs) {
      const f = byProb.get(r.problem);
      if (!f) byProb.set(r.problem, { last: r, all: [r] });
      else { f.all.push(r); if (Number(r.occurrence) > Number(f.last.occurrence)) f.last = r; }
    }
    for (const f of byProb.values()) f.all.sort((a, b) => Number(b.occurrence) - Number(a.occurrence));
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
      // كالمحاكي: لكلّ مهمّةٍ سطرُها، وفعلُها زرٌّ صغيرٌ فيه — وما تمّ ينتقل إلى «ما تمّ» بعلامته
      const tbox = el('div');
      const showTasks = () => { window.MoayadTasks.render(tbox, ui.stu.student_id); tbox.scrollIntoView({ behavior: 'smooth', block: 'start' }); };
      const open = ts.filter((t) => t.status === 'open');
      const done = ts.filter((t) => t.status !== 'open');
      const tip = el('div', 'rs-tip', '—');
      const ib = (label, desc, fn) => { const b = btn(label, 'rs-ib', fn); b.title = desc; b.addEventListener('pointerenter', () => { tip.textContent = desc; }); return b; };
      const row = (t, isDone, acts, line) => {
        const li = el('li');
        const body = el('span');
        body.style.flex = '1';
        body.appendChild(document.createTextNode(t.text_ar));
        if (line) body.appendChild(el('span', 'rs-done-line', line));
        // المصدرُ ظاهرًا إن لم يكن نصَّ الدليل (كـ«اجتهاد مدرسي» لبند ما بعد نهاية السلّم)
        if (t.origin && t.origin !== 'الدليل') body.appendChild(el('span', 'rs-tag own', t.origin));
        li.append(el('i', 'rs-tick' + (isDone ? ' ok' : ''), isDone ? '✓' : '○'), body);
        if (acts.length) { const w = el('span', 'rs-ibs'); w.append(...acts); li.appendChild(w); }
        li.appendChild(el('span', 'rs-who', (t.kind_ar || t.owner_ar || t.owner_role_ar || t.owner_role || '') + (isDone ? ' · تمّ' : '')));
        return li;
      };
      // أفعالُ المهمّة المفتوحة بنوعها — ولا فعلَ بلا مهمّة
      const openActs = (t) => {
        if (t.kind === 'notify_guardian') return [ib('📞 اتّصل', 'الاتّصالُ بوليّ الأمر وإثباتُه — والحقلُ يتبع النتيجة', () => contactForm(t.task_id))];
        if (t.kind === 'follow_up') {
          const a = [ib('📋 احصر', 'تحصر سلوكيّاتِ الطالب بنفسك: السلبيّةَ والإيجابيّةَ ومسبّباتِها', () => selfCensus(t.task_id))];
          if (ui.full) a.push(ib('👤 كلّف', 'تكلّف منسوبًا بالحصر بمدّةٍ تحدّدها، ثمّ ينظر فيه الوكيل', () => assignCensus(t.task_id)));
          return a;
        }
        if (t.kind === 'plan') return [ib('📝 الخطّة', 'خطّةُ تعديل السلوك (نموذج ٣): تُكتب، ثمّ رأيُ معلّم الفصل، ثمّ تُعتمد', () => planForm(t, null))];
        if (t.kind === 'committee') return [ib('⚖️ أحِل', 'لا تُفتح إلا بعد اعتماد الخطّة وبرصدةٍ بعدها', () => referForm(t))];
        // وما سواها: بابُ الإثبات العامّ إن كان بابَها (door_ar كما يرجع)
        if (t.kind === 'move_class') return [ib('🔀 انقل', 'نقلُ الفصل — لا يقع إلّا بقرار لجنة التوجيه الطلابيّ', () => moveForm(t))];
        if (t.door_ar === 'بابُ الإثبات') return [ib('🧾 أثبت', t.evidence_ar || t.door_ar, () => window.MoayadTasks.evidenceDoor(t.task_id, ui.stu.student_id, () => loadStudentCards(), { doors: DOORS }))];
        return [];
      };
      // ما تمّ: الاتّصالُ والحصرُ يبقيان «مرّةً أخرى» ومعهما سطرُ ما وقع
      const contacts = (ui.files.contacts && ui.files.contacts.data) || [];
      const census = (ui.files.census && ui.files.census.data) || [];
      const doneActs = (t) => {
        if (t.kind === 'notify_guardian') {
          const last = contacts[0];
          return [[ib('📞 تواصل مرّةً أخرى', 'إضافةُ اتّصالٍ آخر — والتواصلُ ثانيةً لا ضرر فيه', () => contactForm(t.task_id))],
            last ? 'أُثبت ' + contacts.length + ' · آخرُها ' + [last.on, last.at ? String(last.at).slice(0, 5) : null].filter(Boolean).join(' ') : null];
        }
        if (t.kind === 'follow_up') {
          const filed = census.filter((c) => c.filed_at);
          const last = filed[0];
          return [[ib('📋 احصر مرّةً أخرى', 'حصرٌ آخرُ للسلوكيّات', () => selfCensus(t.task_id))],
            last ? 'حُصر ' + filed.length + ' · آخرُه ' + String(last.filed_at).slice(0, 16).replace('T', ' ') : null];
        }
        // نُقل ⇒ له أن يعود بقرار اللجنة نفسِها (ev_ref رقمُ النقل كما أثبته v2_move_class)
        if (t.kind === 'move_class' && t.status === 'done' && t.ev_ref) return [[ib('↩︎ أعِده إلى فصله', 'الإعادةُ بقرار لجنةٍ معتمدٍ بعد تاريخ النقل', () => returnForm(t))], t.ev_text || null];
        return [[], t.ev_text || null];
      };
      c.appendChild(el('div', 'rs-label', 'ما على الإجراء:'));
      const ul = el('ul', 'rs-acts');
      if (!open.length) ul.appendChild(el('li', 'rs-meta', 'لا شيءَ مفتوح.'));
      for (const t of open) {
        // متابعةُ الموجّه حالٌ تُعرض ولا تُطالَب: رماديّةٌ بلا زرّ، ومعها بابُها كما يرجع
        if (t.evidence_kind === 'services_review') { const li = row(t, false, [], t.door_ar || null); li.classList.add('grey'); ul.appendChild(li); continue; }
        ul.appendChild(row(t, false, openActs(t), null));
      }
      c.appendChild(ul);
      c.appendChild(tip);
      if (done.length) {
        c.appendChild(el('div', 'rs-label', 'ما تمّ:'));
        const ul2 = el('ul', 'rs-acts');
        for (const t of done) { const [acts, line] = doneActs(t); ul2.appendChild(row(t, true, acts, line)); }
        c.appendChild(ul2);
      }
      if (open.length) c.appendChild(btn('أنجز المهامّ بإثباتها (' + open.length + ')', 'rs-btn soft', showTasks));
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
      // حدثُ الرصد نفسُه ⇒ بابُ إلغائه (والجسرُ يقول من يملكه)
      if (ui.full && e.kind === 'behavior_record' && e.record_id) {
        const b = btn('ألغِ هذي الرصدة', 'rs-btn irrev', () => voidForm({ record: e.record_id, student: ui.stu.student_id, student_ar: ui.stu.display_name || ui.stu.full_name, problem_ar: e.title, on_date: e.on }));
        const r = el('div', 'rs-row'); r.appendChild(b); d.appendChild(r);
      }
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
    // لا حارسَ في الواجهة: الإثباتُ مفتوحٌ، والمهمّةُ تُختار إن كانت — والقاعدةُ تحكم برسالتها
    box.appendChild(btn(list.length ? 'تواصل مرّةً أخرى' : 'أثبت اتّصالًا', 'rs-btn', () => contactForm()));
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
    // الرسالةُ لحظةَ اختيار «رسالة»: v2_guardian_message لرصدة المهمّة — أو آخرِ رصدةٍ للطالب إن لم تُختر مهمّة —
    // ويظهر body كما يرجع، وزرٌّ يفتح whatsapp كما يرجع (لا يُبنى الرابطُ هنا)
    const msg = el('div');
    let channel = null;
    const loadMsg = async (taskId) => {
      msg.textContent = '';
      if (channel !== 'رسالة') return;
      const t = taskById(taskId) || taskById(pre);
      const rec = (t && t.record_id) || ((((ui.files && ui.files.tasks) || []).find((x) => x.record_id)) || {}).record_id;
      if (!rec) { msg.appendChild(el('p', 'rs-meta', 'لا رصدةَ للطالب تُبنى عليها الرسالة.')); return; }
      msg.appendChild(el('p', 'rs-meta', 'جارٍ تجهيزُ الرسالة…'));
      const { data, error } = await M.rpc('v2_guardian_message', { p_record: rec }, 'رسالة وليّ الأمر');
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
    // الرصدةُ المحالُ بها، وآخرُ الرصدات، ومجموعُها — فتعرف اللجنةُ ما وقع بعد الإحالة
    for (const [k, v] of [['الطالب', f.student], ['السلوك', f.problem], ['أُحيل بالرصدة', f.occurrences_ar], ['آخرُ الرصدات', f.latest_ar], ['مجموعُها', f.total_ar], ['المحسوم', f.deducted_ar], ['حصرُ السلوكيّات', f.census], ['دراسةُ الحالة', f.case]]) {
      lg.append(el('i', 'k', k + ':'), el('i', null, v == null ? '—' : String(v)));
    }
    box.appendChild(lg);
    if (f.response) box.appendChild(respInfo(f.response));
    V.flash('ok', d.note || 'أُحيل الملفّ');
    V.form({ title: 'ملفُّ الإحالة', what: d.note || '', fields: [{ key: 'file', type: 'node', node: box }], ok: false, cancel: 'تمّ' });
  }

  // ---------- خطّةُ تعديل السلوك (نموذج ٣) ----------
  // كما يرجع v2_plan_of: الحالُ والمحتوى والآراءُ، و needs_teacher و can_final — والاعتمادُ بكتابة «أعتمد»
  const lines = (v) => (Array.isArray(v) ? v : String(v || '').split('\n')).filter((x) => String(x).trim() !== '');
  function renderPlans() {
    const box = $('plans');
    box.textContent = '';
    if (!ui.stu || !ui.files) return;
    const r = ui.files.plans || {};
    if (r.error) box.appendChild(el('div', 'notice err', errText(r.error)));
    const list = r.data || [];
    if (!list.length && !r.error) box.appendChild(el('p', 'rs-empty', 'لم تُكتب له خطّة.'));
    for (const p of list) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, (p.target || '—') + ' — ' + (p.state_ar || p.status || '')));
      f.appendChild(el('p', null, ['كتبها ' + (p.by || '—'), p.starts ? 'من ' + p.starts : null, p.ends ? 'إلى ' + p.ends : null, p.final_at ? 'اعتمدها ' + (p.final_by || '—') + ' في ' + String(p.final_at).slice(0, 10) : null].filter(Boolean).join(' · ')));
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['السلوك', p.desc], ['مظاهرُه', p.manifest], ['ما يسبقه', p.ante], ['ما يليه', p.conseq], ['ما يحقّقه منه', p.gain], ['ما سبق من إجراء', p.prior]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, v));
      f.appendChild(lg);
      const st = lines(p.steps_list || p.steps);
      if (st.length) { f.appendChild(el('div', 'rs-label', 'إجراءاتُ التعديل')); const ul = el('ul', 'rs-acts'); for (const x of st) ul.appendChild(el('li', null, '• ' + x)); f.appendChild(ul); }
      const op = el('div', 'rs-lgd');
      op.append(el('i', 'k', 'رأيُ معلّم الفصل:'), el('i', p.needs_teacher ? 'rs-state-open' : null, p.teacher || 'لم يُبدِه بعد'),
        el('i', 'k', 'رأيُ وليّ الأمر:'), el('i', null, p.guardian || 'لم يُبدِه بعد'),
        el('i', 'k', 'رأيُ الوكيل:'), el('i', null, p.deputy || '—'));
      f.appendChild(op);
      if (p.status === 'draft') {
        const row = el('div', 'rs-row');
        row.append(btn('عدّلها', 'rs-btn soft', () => planForm(null, p)),
          btn('رأيُ معلّم الفصل', 'rs-btn soft', () => opinionForm(p, 'teacher', 'رأيُ معلّم الفصل', p.teacher)),
          btn('رأيُ الوكيل', 'rs-btn soft', () => opinionForm(p, 'deputy', 'رأيُ الوكيل', p.deputy)));
        if (p.can_final) row.appendChild(btn('اعتمدها', 'rs-btn', () => finalForm(p)));
        f.appendChild(row);
        if (!p.can_final && p.needs_teacher) f.appendChild(el('p', 'rs-meta', 'لا تُعتمد حتى يُبدي معلّمُ الفصل رأيَه.'));
      }
      box.appendChild(f);
    }
    if (!list.some((p) => p.status === 'draft')) {
      const t = ((ui.files && ui.files.tasks) || []).find((x) => x.kind === 'plan' && x.status === 'open');
      box.appendChild(btn('اكتب خطّة', 'rs-btn', () => planForm(t || null, null)));
    }
    arabize(box);
  }

  // أبوابُ المهامّ الخاصّة — يُنقل إليها من بابِ الإثبات العامّ (opts.doors)
  const DOORS = {
    notify_guardian: (ct) => contactForm(ct.id),
    follow_up: (ct) => selfCensus(ct.id),
    plan: (ct) => planForm(taskById(ct.id), null),
    committee: (ct) => referForm(taskById(ct.id)),
    move_class: (ct) => moveForm(taskById(ct.id)),
  };

  // ---------- نقلُ الفصل: v2_move_class_targets ثمّ v2_move_class ----------
  // blocks[] كما هي · privacy_ar بنصّه · والوجهةُ من targets وحدَها · وكلمةُ الحارس confirm_word بيد المستعمل
  // ولا يُعرض سببُ النقل لمعلّمي الفصل الجديد (show_reason_to_new_class = false) — والسببُ هنا يُكتب للسجلّ لا لهم
  async function moveForm(t) {
    if (!t) return;
    const { data: b, error } = await M.rpc('v2_move_class_targets', { p_record: t.record_id }, 'فصول النقل');
    if (error) { flash('bad', errText(error)); return; }
    const head = el('div');
    head.appendChild(el('p', 'rs-meta', [b.problem_ar, b.degree_ar, b.grade_ar, b.from_section ? 'فصلُه الآن ' + b.from_section : null].filter(Boolean).join(' · ')));
    if (b.decision) head.appendChild(el('div', 'rs-settled', ['قرارُ اللجنة' + (b.decision.held_on ? ' في ' + b.decision.held_on : ''), b.decision.decision_ar, b.decision.recommend_ar].filter(Boolean).join(' — ')));
    for (const x of b.blocks || []) head.appendChild(el('div', 'rs-info', x));
    if (b.warning_ar) head.appendChild(el('div', 'rs-info', b.warning_ar));
    for (const x of b.excluded || []) head.appendChild(el('p', 'rs-meta', (x.label_ar || x.section) + ' — ' + (x.why || '')));
    if (b.privacy_ar) head.appendChild(el('div', 'rs-note', b.privacy_ar));
    const items = (b.targets || []).map((x) => [x.section, (x.label_ar || x.section) + (x.note_ar ? ' · ' + x.note_ar : '')]);
    const fields = [{ key: 'h', type: 'node', node: head }];
    if (items.length) fields.push({ key: 'to', type: 'pick', label: 'إلى فصل', items });
    fields.push({ key: 'reason', type: 'textarea', label: 'سببُ النقل — يُقيَّد في سجلّ الطالب', rows: 2 });
    fields.push({ key: 'confirm', label: 'اكتب «' + (b.confirm_word || '') + '» لتُقرّه' });
    V.form({
      title: t.text_ar || '', what: (ui.stu && (ui.stu.display_name || ui.stu.full_name)) || '',
      fields,
      ok: b.confirm_word || 'تأكيد',
      okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error: e } = await M.rpc('v2_move_class', { p_record: t.record_id, p_task: t.task_id, p_to_section: v.to || null, p_reason: v.reason, p_confirm: v.confirm }, 'نقل الفصل');
        if (e) return e;
        if (!data || data.ok !== true) return 'لم ينقل الجسرُ الطالب';
        flash('ok', [data.headline, data.privacy_ar, data.warning_ar, data.return_ar].filter(Boolean).join(' · '));
        loadStudentCards();
        return null;
      },
    });
  }

  function returnForm(t) {
    V.form({
      title: 'إعادةُ الطالب إلى فصله', what: t.ev_text || '',
      fields: [
        { key: 'reason', type: 'textarea', label: 'سببُ الإعادة — يُقيَّد كما قُيّد النقل', rows: 2 },
        { key: 'confirm', label: 'اكتب «أُعيد» لتُقرّه' },
      ],
      ok: 'أُعيد',
      okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_move_class_return', { p_move: t.ev_ref, p_reason: v.reason, p_confirm: v.confirm }, 'إعادة الطالب إلى فصله');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُعِده الجسر';
        flash('ok', [data.headline, data.note_ar].filter(Boolean).join(' · '));
        loadStudentCards();
        return null;
      },
    });
  }

  // كتابةُ الخطّة أو تعديلُ مسودّتها — وتحت حقولها بنكُ العبارات (plDesc · plAnte · plPost · plGain)
  function planForm(t, p) {
    const stu = ui.stu;
    const draft = p || (((ui.files && ui.files.plans && ui.files.plans.data) || []).find((x) => x.status === 'draft')) || null;
    const m = t && metaOf(t.problem_ar);
    const pr = m ? m.id : null;
    // حارسُ تغيير الخطّة: الخطّةُ المعتمدةُ السابقةُ إلى جوار الحقول (v2_plan_of) — ليرى الوكيلُ ما يُغيّره ولا يُجبَر على التذكّر
    const finals = ((ui.files && ui.files.plans && ui.files.plans.data) || []).filter((x) => x.status === 'final' && x.final_at);
    const prev = finals.sort((a, b) => String(b.final_at).localeCompare(String(a.final_at)))[0] || null;
    const prevBox = el('div');
    if (prev) {
      const f = el('div', 'rs-file rs-prev');
      f.appendChild(el('h5', null, 'الخطّةُ المعتمدةُ السابقة — ' + String(prev.final_at).slice(0, 10)));
      if (prev.target) f.appendChild(el('p', null, 'السلوكُ المستهدف: ' + prev.target));
      const st = lines(prev.steps_list || prev.steps);
      if (st.length) { const ul = el('ul', 'rs-acts'); for (const x of st) ul.appendChild(el('li', null, '• ' + x)); f.appendChild(ul); }
      prevBox.appendChild(f);
    }
    V.form({
      title: draft ? 'خطّةُ تعديل السلوك — مسودّة' : 'خطّةُ تعديل السلوك', what: (stu.display_name || stu.full_name) + (t && t.problem_ar ? ' — ' + t.problem_ar : ''),
      fields: [
        { key: 'prev', type: 'node', node: prevBox },
        { key: 'desc', type: 'textarea', label: 'وصفُ السلوك المراد تعديلُه', rows: 2, value: draft ? draft.desc : null, bank: { key: 'plDesc', problem: pr } },
        { key: 'manifest', type: 'textarea', label: 'مظاهرُه عند الطالب (اختياريّ)', rows: 2, value: draft ? draft.manifest : null },
        { key: 'ante', type: 'textarea', label: 'ما يسبقه — مثيراتُه (اختياريّ)', rows: 2, value: draft ? draft.ante : null, bank: { key: 'plAnte', problem: pr } },
        { key: 'conseq', type: 'textarea', label: 'ما يليه (اختياريّ)', rows: 2, value: draft ? draft.conseq : null, bank: { key: 'plPost', problem: pr } },
        { key: 'gain', type: 'textarea', label: 'ما يحقّقه الطالبُ منه (اختياريّ)', rows: 2, value: draft ? draft.gain : null, bank: { key: 'plGain', problem: pr } },
        { key: 'prior', type: 'textarea', label: 'ما سبق من إجراء (اختياريّ)', rows: 2, value: draft ? draft.prior : null },
        { key: 'target', type: 'textarea', label: 'السلوكُ البديلُ المستهدف', rows: 2, value: draft ? draft.target : null },
        { key: 'steps', type: 'textarea', label: 'إجراءاتُ التعديل — سطرٌ لكلّ إجراء', rows: 4, value: draft ? lines(draft.steps_list || draft.steps).join('\n') : null },
        { key: 'starts', type: 'date', label: 'تبدأ', value: draft ? draft.starts : null },
        { key: 'ends', type: 'date', label: 'تنتهي (اختياريّ)', value: draft ? draft.ends : null },
      ],
      ok: draft ? 'احفظ التعديل' : 'احفظها مسودّة',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_plan_write', {
          p_student: stu.student_id, p_record: t ? t.record_id : null, p_task: t ? t.task_id : null, p_plan: draft ? draft.plan : null,
          p_desc: v.desc, p_manifest: v.manifest, p_ante: v.ante, p_conseq: v.conseq, p_gain: v.gain, p_prior: v.prior,
          p_target: v.target, p_steps: v.steps, p_starts: v.starts, p_ends: v.ends,
        }, 'كتابة الخطّة');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'حُفظت الخطّة');
        loadStudentCards();
        return null;
      },
    });
  }

  function opinionForm(p, who, label, cur) {
    V.form({
      title: label, what: p.target || '',
      fields: [{ key: 'text', type: 'textarea', label: label, rows: 3, value: cur }],
      ok: 'احفظ الرأي',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_plan_opinion', { p_plan: p.plan, p_who: who, p_text: v.text }, 'رأيٌ في الخطّة');
        if (error) return error;
        V.flash('ok', 'حُفظ ' + label);
        loadStudentCards();
        return null;
      },
    });
  }

  function finalForm(p) {
    V.form({
      title: 'اعتمادُ الخطّة', what: 'باعتماد الخطّة يبدأ قياسُ استجابة الطالب، وعليه تُبنى إحالتُه للّجنة',
      fields: [{ key: 'confirm', label: 'اكتب: أعتمد' }],
      ok: 'اعتمدها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_plan_final', { p_plan: p.plan, p_confirm: v.confirm }, 'اعتماد الخطّة');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'اعتُمدت الخطّة');
        loadStudentCards();
        return null;
      },
    });
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
    row.appendChild(btn(list.some((c) => c.filed_at) ? 'احصر مرّةً أخرى' : 'أحصرُ بنفسي', 'rs-btn', () => selfCensus()));
    if (ui.full) row.appendChild(btn('أكلّف به أحدًا', 'rs-btn soft', () => assignCensus()));
    if (ui.full) row.appendChild(btn('أعِد ما انقضت مدّتُه', 'rs-btn ghost', sweepCensus));
    box.appendChild(row);
    arabize(box);
  }

  // قوائمُ الحصر لمدرسة الشاشة — مرّةً لكلّ مدرسة
  async function censusLists() {
    if (ui.lists && ui.lists.school === M.state.school) return ui.lists;
    const { data, error } = await M.rpc('v2_census_list', { p_school: M.state.school, p_all: false }, 'قوائم الحصر');
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
      // وزرّان لا واحد: يُحفظ الحصرُ بنفسك، أو يُكلَّف به غيرُك
      extra: [{ text: 'كلّف به أحدًا', cls: 'rs-btn soft', onClick: (v) => { setTimeout(() => assignCensus(v.task || pre), 0); return null; } }],
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
