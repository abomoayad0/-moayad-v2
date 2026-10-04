// مؤيّد · رصد المخالفات السلوكية — الفصل ثم الطالب ثم المخالفة، ثم المهامّ المولَّدة.
// الدرجة والخطوة والإجراء والمهامّ كلها من القاعدة:
// v2_day_summary · v2_day_classes · v2_day_list · v2_conduct_list · v2_record_behavior
// ومهامّ الطالب وإغلاقها بإثبات في tasks.js
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, el, toast, errText, showLoadErr } = M;

  const ui = { classes: [], rows: [], problems: [], cls: null, stu: null, degree: 'all', tasks: [], prob: null };

  // رموز القاعدة بأسمائها — للعرض فقط
  const SCOPE_AR = { primary: 'ابتدائي', intermediate_secondary: 'متوسط وثانوي', all: 'الجميع' };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  function step(n) {
    $('pickClass').hidden = n !== 1;
    $('pickStudent').hidden = n !== 2;
    $('pickProblem').hidden = n !== 3;
    $('result').hidden = n !== 4;
    for (let i = 1; i <= 4; i++) $('st' + i).className = i === n ? 'on' : (i < n ? 'done' : '');
    window.scrollTo(0, 0);
  }

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
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, null);
    ui.classes = cls.data || [];
    ui.rows = list.data || [];
    ui.cls = null;
    ui.stu = null;
    renderClasses();
    step(1);
  }

  // ---------- ١ الفصل ----------
  function renderClasses() {
    const box = $('classes');
    box.textContent = '';
    if (ui.classes.length === 0) box.appendChild(el('div', 'empty', 'لا فصول فيها طلاب مقيّدون.'));
    for (const c of ui.classes) {
      const b = el('button', 'cls done');
      b.type = 'button';
      b.append(el('b', null, c.label_ar), el('small', null, c.enrolled + ' طالباً'));
      b.addEventListener('click', () => openClass(c));
      box.appendChild(b);
    }
  }

  function openClass(c) {
    ui.cls = c;
    $('clsTitle').textContent = c.label_ar;
    $('qStu').value = '';
    renderStudents();
    step(2);
  }

  // ---------- ٢ الطالب ----------
  function renderStudents() {
    const c = ui.cls;
    const q = $('qStu').value.trim();
    const box = $('students');
    box.textContent = '';
    const list = ui.rows.filter((r) => r.grade === c.grade && r.section === c.section &&
      (!q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q)));
    if (list.length === 0) box.appendChild(el('div', 'empty', 'لا أحد بهذا البحث.'));
    for (const r of list) {
      const b = el('button', 'pick');
      b.type = 'button';
      b.append(el('b', null, r.display_name || r.full_name), el('small', null, r.student_no));
      b.addEventListener('click', () => openStudent(r));
      box.appendChild(b);
    }
  }

  // المخالفات تُصفّى بمرحلة الطالب في القاعدة — v2_conduct_list(p_student)
  async function openStudent(r) {
    ui.stu = r;
    ui.problems = [];
    ui.degree = 'all';
    $('stuTitle').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('qProb').value = '';
    renderDegrees();
    $('problems').textContent = '';
    $('problems').appendChild(el('div', 'empty', 'جارٍ جلب المخالفات المنطبقة على الطالب…'));
    step(3);
    const { data, error } = await M.rpc('v2_conduct_list',
      { p_student: r.student_id, p_mode: 'onsite', p_target: 'general' }, 'قائمة المخالفات');
    if (ui.stu !== r) return;
    if (error) {
      $('problems').textContent = '';
      $('problems').appendChild(el('div', 'notice err', 'تعذّر جلب المخالفات: ' + errText(error)));
      return;
    }
    ui.problems = data || [];
    renderDegrees();
    renderProblems();
  }

  // ---------- ٣ المخالفة ----------
  function renderDegrees() {
    const box = $('degrees');
    box.textContent = '';
    const degs = [...new Set(ui.problems.map((p) => p.degree_no))].sort((a, b) => a - b);
    const label = (d) => (ui.problems.find((p) => p.degree_no === d) || {}).degree_ar || ('الدرجة ' + d);
    for (const d of ['all', ...degs]) {
      const b = el('button', null, d === 'all' ? 'كل الدرجات' : label(d));
      b.type = 'button';
      b.setAttribute('aria-pressed', String(ui.degree === d));
      b.addEventListener('click', () => { ui.degree = d; renderDegrees(); renderProblems(); });
      box.appendChild(b);
    }
  }

  function renderProblems() {
    const q = $('qProb').value.trim();
    const box = $('problems');
    box.textContent = '';
    const list = ui.problems.filter((p) => (ui.degree === 'all' || p.degree_no === ui.degree) && (!q || p.text_ar.includes(q)));
    if (list.length === 0) box.appendChild(el('div', 'empty', 'لا مخالفة بهذا البحث.'));
    for (const p of list) {
      const b = el('button', 'pick prob deg' + p.degree_no);
      b.type = 'button';
      b.append(el('b', null, p.text_ar),
        el('small', null, (p.degree_ar || 'الدرجة ' + p.degree_no) + ' · ' + (SCOPE_AR[p.stage_scope] || p.stage_scope) + ' · ' + (p.source_page || '')));
      // ما لا ينطبق يُعرض بسببه من القاعدة ولا يُرصد
      if (p.applies === false) {
        b.disabled = true;
        b.appendChild(el('small', 'why', p.why || 'لا تنطبق على الطالب'));
      } else {
        b.addEventListener('click', () => record(p));
      }
      box.appendChild(b);
    }
  }

  async function record(p) {
    const r = ui.stu;
    $('recWho').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('recProb').textContent = (p.degree_ar || 'الدرجة ' + p.degree_no) + ': ' + p.text_ar;
    for (const id of ['recPlace', 'recPeriod', 'recNote']) $(id).value = '';
    for (const id of ['recInjury', 'recDamage', 'recSeizure', 'recLegal']) $(id).checked = false;
    $('recLegalBox').hidden = true;
    if (await ask($('recDlg')) !== 'ok') return;

    const period = $('recPeriod').value ? Number($('recPeriod').value) : null;
    const { data, error } = await M.rpc('v2_record_behavior', {
      p_student: r.student_id, p_problem: p.id,
      p_place: $('recPlace').value.trim() || null, p_note: $('recNote').value.trim() || null,
      p_period: period, p_victim: null,
      p_injury: $('recInjury').checked, p_damage: $('recDamage').checked,
      p_seizure: $('recSeizure').checked, p_seizure_legal: $('recSeizure').checked && $('recLegal').checked,
    });
    if (error) { toast('لم تُرصد المخالفة:\n' + errText(error)); return; }
    ui.prob = p;
    showTasks('رُصدت المخالفة', (p.degree_ar || 'الدرجة ' + p.degree_no) + ': ' + p.text_ar);
    toast('رُصدت المخالفة — ولّدت ' + (((data && data.tasks) || []).length) + ' مهمّة.', true);
  }

  // مهامّ الطالب كلها من القاعدة — وإغلاقها بإثبات
  function showTasks(title, sub) {
    const r = ui.stu;
    $('resTitle').textContent = title;
    $('resWho').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('resProb').textContent = sub || '';
    $('resProb').hidden = !sub;
    step(4);
    window.MoayadTasks.render($('tasks'), r.student_id);
  }

  $('recSeizure').addEventListener('change', () => {
    $('recLegalBox').hidden = !$('recSeizure').checked;
    if (!$('recSeizure').checked) $('recLegal').checked = false;
  });

  // ---------- التنقّل ----------
  $('backClass').addEventListener('click', () => step(1));
  $('backStudent').addEventListener('click', () => { renderStudents(); step(2); });
  $('againStudent').addEventListener('click', () => { renderStudents(); step(2); });
  $('againClass').addEventListener('click', () => step(1));
  $('stuTasks').addEventListener('click', () => showTasks('مهامّ الطالب', ''));
  $('qStu').addEventListener('input', renderStudents);
  $('qProb').addEventListener('input', renderProblems);

  M.start({ screen: 'suluk', onChange: () => refresh() });
})();
