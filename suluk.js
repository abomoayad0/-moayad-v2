// مؤيّد · رصد المخالفات السلوكية — الفصل ثم الطالب ثم المخالفة، ثم المهامّ المولَّدة.
// الدرجة والخطوة والإجراء والمهامّ كلها من القاعدة:
// v2_day_summary · v2_day_classes · v2_day_list · v2_conduct_list · v2_record_behavior
// v2_task_done · v2_task_skip
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, el, toast, errText, showLoadErr } = M;

  const ui = { classes: [], rows: [], problems: null, cls: null, stu: null, degree: 'all', tasks: [], prob: null };

  // رموز القاعدة بأسمائها — للعرض فقط
  const SCOPE_AR = { primary: 'ابتدائي', intermediate_secondary: 'متوسط وثانوي', all: 'الجميع' };
  const TASK_AR = { open: 'مفتوحة', done: 'نُفّذت', skipped: 'أُسقطت' };

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
    const [sum, cls, list, probs] = await Promise.all([
      sb.rpc('v2_day_summary', args),
      sb.rpc('v2_day_classes', args),
      sb.rpc('v2_day_list', args),
      ui.problems ? Promise.resolve({ data: ui.problems })
        : sb.rpc('v2_conduct_list', { p_stage: null, p_mode: 'onsite', p_target: 'general' }),
    ]);
    const err = sum.error || cls.error || list.error || probs.error;
    if (err) { showLoadErr('تعذّر الجلب: ' + errText(err)); return; }
    const s = sum.data && sum.data[0];
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, null);
    ui.classes = cls.data || [];
    ui.rows = list.data || [];
    ui.problems = probs.data || [];
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

  function openStudent(r) {
    ui.stu = r;
    $('stuTitle').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('qProb').value = '';
    renderDegrees();
    renderProblems();
    step(3);
  }

  // ---------- ٣ المخالفة ----------
  function renderDegrees() {
    const box = $('degrees');
    box.textContent = '';
    const degs = [...new Set(ui.problems.map((p) => p.degree_no))].sort((a, b) => a - b);
    for (const d of ['all', ...degs]) {
      const b = el('button', null, d === 'all' ? 'كل الدرجات' : 'الدرجة ' + d);
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
        el('small', null, 'الدرجة ' + p.degree_no + ' · ' + (SCOPE_AR[p.stage_scope] || p.stage_scope) + ' · ' + (p.source_page || '')));
      b.addEventListener('click', () => record(p));
      box.appendChild(b);
    }
  }

  async function record(p) {
    const r = ui.stu;
    $('recWho').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('recProb').textContent = 'الدرجة ' + p.degree_no + ': ' + p.text_ar;
    for (const id of ['recPlace', 'recPeriod', 'recNote']) $(id).value = '';
    for (const id of ['recInjury', 'recDamage', 'recSeizure', 'recLegal']) $(id).checked = false;
    $('recLegalBox').hidden = true;
    if (await ask($('recDlg')) !== 'ok') return;

    const period = $('recPeriod').value ? Number($('recPeriod').value) : null;
    const { data, error } = await sb.rpc('v2_record_behavior', {
      p_student: r.student_id, p_problem: p.id,
      p_place: $('recPlace').value.trim() || null, p_note: $('recNote').value.trim() || null,
      p_period: period, p_victim: null,
      p_injury: $('recInjury').checked, p_damage: $('recDamage').checked,
      p_seizure: $('recSeizure').checked, p_seizure_legal: $('recSeizure').checked && $('recLegal').checked,
    });
    if (error) { toast('لم تُرصد المخالفة:\n' + errText(error)); return; }
    ui.prob = p;
    ui.tasks = (data && data.tasks) || [];
    $('resWho').textContent = (r.display_name || r.full_name) + ' — ' + ui.cls.label_ar;
    $('resProb').textContent = 'الدرجة ' + p.degree_no + ': ' + p.text_ar;
    renderTasks();
    toast('رُصدت المخالفة.', true);
    step(4);
  }

  $('recSeizure').addEventListener('change', () => {
    $('recLegalBox').hidden = !$('recSeizure').checked;
    if (!$('recSeizure').checked) $('recLegal').checked = false;
  });

  // ---------- ٤ المهامّ ----------
  function renderTasks() {
    const box = $('tasks');
    box.textContent = '';
    if (ui.tasks.length === 0) box.appendChild(el('div', 'empty', 'لم تُولَّد مهامّ.'));
    for (const t of ui.tasks) {
      const c = el('div', 'ev task t-' + t.status);
      const top = el('div', 'row1');
      top.append(el('div', 'detail', t.text), el('span', 'badge b-' + (t.status === 'open' ? 'late' : t.status === 'done' ? 'present' : 'unrecorded'), TASK_AR[t.status] || t.status));
      c.appendChild(top);
      c.appendChild(el('div', 'meta', 'المسؤول: ' + (t.owner || '—')));
      if (t.status === 'open') {
        const acts = el('div', 'acts two');
        const ok = el('button', 'a-accept', 'نُفّذت');
        ok.type = 'button';
        ok.addEventListener('click', () => taskDone(t));
        const no = el('button', 'a-reject', 'إسقاط بسبب');
        no.type = 'button';
        no.addEventListener('click', () => taskSkip(t));
        acts.append(ok, no);
        c.appendChild(acts);
      }
      box.appendChild(c);
    }
  }

  async function taskDone(t) {
    const { error } = await sb.rpc('v2_task_done', { p_task: t.id, p_note: null });
    if (error) { toast('لم تُسجَّل المهمّة:\n' + errText(error)); return; }
    t.status = 'done'; // ما أكّدته القاعدة بلا خطأ
    renderTasks();
  }

  $('skipReason').addEventListener('input', () => { $('skipOk').disabled = $('skipReason').value.trim() === ''; });

  async function taskSkip(t) {
    $('skipTask').textContent = t.text;
    $('skipReason').value = '';
    $('skipOk').disabled = true;
    if (await ask($('skipDlg')) !== 'ok') return;
    const { error } = await sb.rpc('v2_task_skip', { p_task: t.id, p_reason: $('skipReason').value.trim() });
    if (error) { toast('لم تُسقَط المهمّة:\n' + errText(error)); return; }
    t.status = 'skipped'; // ما أكّدته القاعدة بلا خطأ
    renderTasks();
  }

  // ---------- التنقّل ----------
  $('backClass').addEventListener('click', () => step(1));
  $('backStudent').addEventListener('click', () => { renderStudents(); step(2); });
  $('againStudent').addEventListener('click', () => { renderStudents(); step(2); });
  $('againClass').addEventListener('click', () => step(1));
  $('qStu').addEventListener('input', renderStudents);
  $('qProb').addEventListener('input', renderProblems);

  M.start({ screen: 'suluk', onChange: () => refresh() });
})();
