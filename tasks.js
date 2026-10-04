// مؤيّد — مهامّ الطالب وإغلاقها بإثبات.
// نوع الإثبات ومتطلّباته من القاعدة (needs_*)، ولا يُغلق شيء بزرّ وحده:
// v2_student_tasks · v2_student_absence_tasks · v2_task_done · v2_absence_task_done
// v2_task_skip · v2_absence_task_skip
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText } = M;

  const STATUS_AR = { open: 'مفتوحة', done: 'أُغلقت', skipped: 'أُسقطت', auto: 'وقعت آلياً' };
  const BRIDGE = {
    behavior: { done: 'v2_task_done', skip: 'v2_task_skip' },
    absence: { done: 'v2_absence_task_done', skip: 'v2_absence_task_skip' },
  };

  // نافذة الإثبات — تُبنى مرّة وتُستعمل لكل مهمّة
  function ensureDialogs() {
    if ($('evDlg')) return;
    const d = document.createElement('dialog');
    d.id = 'evDlg';
    d.innerHTML = `
      <form method="dialog">
        <h3>إغلاق المهمّة بإثبات</h3>
        <p class="quote" id="evTask"></p>
        <p class="hint" id="evHint"></p>
        <p class="detail" id="evForm" hidden></p>
        <div id="evFields"></div>
        <div class="dlg-acts">
          <button value="cancel" type="submit" class="btn-ghost">تراجع</button>
          <button value="ok" type="submit" class="btn-accept" id="evOk">أغلق المهمّة</button>
        </div>
      </form>`;
    document.body.appendChild(d);
    const s = document.createElement('dialog');
    s.id = 'tskSkipDlg';
    s.innerHTML = `
      <form method="dialog">
        <h3>إسقاط المهمّة</h3>
        <p class="quote" id="tskSkipText"></p>
        <label for="tskSkipReason">السبب — إلزامي</label>
        <textarea id="tskSkipReason" rows="3"></textarea>
        <div class="dlg-acts">
          <button value="cancel" type="submit" class="btn-ghost">تراجع</button>
          <button value="ok" type="submit" class="btn-danger" id="tskSkipOk" disabled>أسقطها</button>
        </div>
      </form>`;
    document.body.appendChild(s);
    $('tskSkipReason').addEventListener('input', () => { $('tskSkipOk').disabled = $('tskSkipReason').value.trim() === ''; });
  }

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  function field(label, input, required) {
    const w = el('div', 'evf');
    const l = el('label', null, label + (required ? ' *' : ''));
    l.htmlFor = input.id;
    w.append(l, input);
    return w;
  }
  function inp(id, type) { const i = document.createElement(type === 'textarea' ? 'textarea' : 'input'); i.id = id; if (type !== 'textarea') i.type = type; else i.rows = 2; return i; }

  // الحقول بما تطلبه القاعدة لهذه المهمّة — والقاعدة هي التي تحكم بالنقص
  function buildFields(t) {
    const box = $('evFields');
    box.textContent = '';
    if (t.needs_date) { const i = inp('evOn', 'date'); i.value = new Date().toLocaleDateString('en-CA'); box.appendChild(field('التاريخ', i, true)); }
    if (t.needs_text) box.appendChild(field('ما تمّ', inp('evText', 'textarea'), true));
    if (t.needs_people) box.appendChild(field('من حضر أو من استلم', inp('evPeople', 'text'), true));
    if (t.needs_ref) box.appendChild(field('رقم الصادر أو البلاغ', inp('evRef', 'text'), true));
    if (t.needs_file) {
      box.appendChild(field('المرفق (رقمه أو وصفه)', inp('evFile', 'text'), true));
      const r = el('label', 'check');
      const c = inp('evRefused', 'checkbox');
      r.append(c, ' امتنع عن التسليم أو الاستلام');
      box.appendChild(r);
    }
    if (t.needs_signature) {
      const r = el('label', 'check');
      const c = inp('evSigned', 'checkbox');
      r.append(c, ' وُقّع');
      box.appendChild(r);
      box.appendChild(field('أو سبب الامتناع عن التوقيع', inp('evRefusedReason', 'text'), false));
    }
    if (!t.needs_date && !t.needs_text && !t.needs_people && !t.needs_ref && !t.needs_file && !t.needs_signature) {
      box.appendChild(field('ملاحظة (اختيارية)', inp('evText', 'textarea'), false));
    }
  }

  function readEv() {
    const ev = {};
    const v = (id) => ($(id) ? $(id).value.trim() : '');
    if (v('evOn')) ev.on = v('evOn');
    if (v('evText')) ev.text = v('evText');
    if (v('evPeople')) ev.people = v('evPeople');
    if (v('evRef')) ev.ref = v('evRef');
    if (v('evFile')) ev.file = v('evFile');
    if ($('evRefused') && $('evRefused').checked) ev.refused = true;
    if ($('evSigned') && $('evSigned').checked) ev.signed = true;
    if (v('evRefusedReason')) ev.refused_reason = v('evRefusedReason');
    return ev;
  }

  async function closeTask(kind, t, onChanged) {
    ensureDialogs();
    $('evTask').textContent = t.text_ar;
    $('evHint').textContent = (t.evidence_ar ? 'الإثبات: ' + t.evidence_ar : '') + (t.hint_ar ? ' — ' + t.hint_ar : '');
    $('evForm').hidden = !t.form_no;
    $('evForm').textContent = t.form_no ? 'النموذج رقم ' + t.form_no + (t.form_title ? ': ' + t.form_title : '') : '';
    buildFields(t);
    if (await ask($('evDlg')) !== 'ok') return;
    const { data, error } = await M.rpc(BRIDGE[kind].done, { p_task: t.task_id, p_ev: readEv() }, 'إغلاق مهمّة');
    if (error) { toast('لم تُغلق المهمّة:\n' + errText(error)); return; }
    toast('أُغلقت المهمّة' + (data && data.evidence_ar ? ' — ' + data.evidence_ar : '') + '.', true);
    await onChanged();
  }

  async function skipTask(kind, t, onChanged) {
    ensureDialogs();
    $('tskSkipText').textContent = t.text_ar;
    $('tskSkipReason').value = '';
    $('tskSkipOk').disabled = true;
    if (await ask($('tskSkipDlg')) !== 'ok') return;
    const { error } = await M.rpc(BRIDGE[kind].skip, { p_task: t.task_id, p_reason: $('tskSkipReason').value.trim() }, 'إسقاط مهمّة');
    if (error) { toast('لم تُسقَط المهمّة:\n' + errText(error)); return; }
    toast('أُسقطت المهمّة.', true);
    await onChanged();
  }

  function card(kind, t, onChanged) {
    const c = el('div', 'ev task t-' + t.status);
    const top = el('div', 'row1');
    const b = el('span', 'badge b-' + (t.status === 'open' ? 'late' : (t.status === 'done' || t.status === 'auto') ? 'present' : 'unrecorded'),
      STATUS_AR[t.status] || t.status);
    top.append(el('div', 'detail', t.text_ar), b);
    c.appendChild(top);
    const meta = kind === 'behavior'
      ? (t.problem_ar ? t.problem_ar + ' — الدرجة ' + t.degree_no + ' · ' : '') + (t.occurred_on || '')
      : 'غياب ' + t.days_n + ' أيام ' + (t.excused ? 'بعذر' : 'بلا عذر') + ' · ' + (t.triggered_on || '');
    c.appendChild(el('div', 'meta', meta));
    c.appendChild(el('div', 'meta', 'المسؤول: ' + (t.owner_role || '—') + (t.evidence_ar ? ' · الإثبات: ' + t.evidence_ar : '')));
    // الآلي يقع في القاعدة (الحسم والتعويض) فلا يُسأل عنه إثبات
    if (t.status === 'auto') {
      c.appendChild(el('div', 'meta', 'وقعت آلياً في القاعدة — لا تُغلق من هنا.'));
    } else if (t.status === 'open') {
      if (!M.state.me.can.close_task) {
        c.appendChild(el('div', 'meta', 'صفتك لا تملك إغلاق المهامّ.'));
      } else if (t.evidence_kind === 'auto') {
        c.appendChild(el('div', 'meta', 'تقع آلياً في القاعدة — لا تُغلق من هنا.'));
      } else {
        const acts = el('div', 'acts two');
        const ok = el('button', 'a-accept', 'أغلقها بإثبات');
        ok.type = 'button';
        ok.addEventListener('click', () => closeTask(kind, t, onChanged));
        const no = el('button', 'a-reject', 'إسقاط بسبب');
        no.type = 'button';
        no.addEventListener('click', () => skipTask(kind, t, onChanged));
        acts.append(ok, no);
        c.appendChild(acts);
      }
    }
    return c;
  }

  // تعرض مهامّ الطالب كلّها: السلوك ثم الغياب
  async function render(box, studentId) {
    box.textContent = '';
    box.appendChild(el('div', 'empty', 'جارٍ جلب المهامّ…'));
    const [beh, abs] = await Promise.all([
      M.rpc('v2_student_tasks', { p_student: studentId }, 'مهامّ الطالب'),
      M.rpc('v2_student_absence_tasks', { p_student: studentId }, 'مهامّ الغياب'),
    ]);
    box.textContent = '';
    const again = () => render(box, studentId);
    for (const [kind, res, title] of [['behavior', beh, 'مهامّ السلوك'], ['absence', abs, 'مهامّ الغياب']]) {
      box.appendChild(el('h3', 'grp', title + (res.error ? '' : ' (' + (res.data || []).length + ')')));
      if (res.error) { box.appendChild(el('div', 'notice err', 'تعذّر جلبها: ' + errText(res.error))); continue; }
      if (!res.data || res.data.length === 0) { box.appendChild(el('div', 'empty', 'لا مهامّ.')); continue; }
      for (const t of res.data) box.appendChild(card(kind, t, again));
    }
  }

  window.MoayadTasks = { render };
})();
