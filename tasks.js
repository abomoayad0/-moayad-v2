// مؤيّد — مهامّ الطالب وإغلاقها بإثبات.
// نوع الإثبات ومتطلّباته من القاعدة (needs_*)، ولا يُغلق شيء بزرّ وحده:
// v2_student_tasks · v2_student_absence_tasks · v2_task_done · v2_absence_task_done
// v2_task_skip · v2_absence_task_skip
// ومهامُّ السلوك من بابِ الإثبات العامّ: v2_task_card ⇒ v2_task_evidence (حقولُه ونموذجُه وتوقيعُه من البطاقة)
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText } = M;

  const STATUS_AR = { open: 'مفتوحة', done: 'أُغلقت', skipped: 'أُسقطت', auto: 'وقعت آلياً' };
  const BRIDGE = {
    behavior: { done: 'v2_task_done', skip: 'v2_task_skip', delegate: 'v2_task_delegate' },
    absence: { done: 'v2_absence_task_done', skip: 'v2_absence_task_skip', delegate: 'v2_absence_task_delegate' },
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
        <button type="button" class="btn-ghost wide formlink" id="evFormBtn" hidden>افتح النموذج</button>
        <p class="hint" id="evFormNote" hidden></p>
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
          <button value="ok" type="submit" class="btn-danger" id="tskSkipOk">أسقطها</button>
        </div>
      </form>`;
    document.body.appendChild(s);
    // النموذج في نافذة داخل الشاشة — يُملأ ويُعتمد ثم تُغلق فيرجع الإثبات كما كان
    const f = document.createElement('dialog');
    f.id = 'formDlg';
    f.className = 'formdlg';
    f.innerHTML = `
      <div class="formdlg-bar">
        <b id="formDlgTitle">النموذج</b>
        <button type="button" class="hbtn" id="formDlgClose">أغلق النموذج</button>
      </div>
      <iframe id="formFrame" title="النموذج"></iframe>`;
    document.body.appendChild(f);
    $('formDlgClose').addEventListener('click', () => f.close());
    f.addEventListener('close', () => { $('formFrame').src = 'about:blank'; });
    $('evFormBtn').addEventListener('click', () => {
      const url = $('evFormBtn').dataset.src;
      if (!url) return;
      $('formFrame').src = url + '&embed=1';
      f.showModal();
    });
    // النموذج يُبلغ إذا حُفظ أو اعتُمد أو وُقّع، فتُحدَّث المهامّ بعد الإثبات
    window.addEventListener('message', (e) => {
      if (e.origin === location.origin && e.data && e.data.moayad === 'form-changed') formChanged = true;
    });
    const g = document.createElement('dialog');
    g.id = 'dlgDelegate';
    g.innerHTML = `
      <form method="dialog">
        <h3>تحويل المهمّة</h3>
        <p class="quote" id="dlgText"></p>
        <label for="dlgPerson">إلى</label>
        <select id="dlgPerson"></select>
        <p class="hint" id="dlgRoles"></p>
        <label for="dlgNote">سبب التحويل — إلزامي</label>
        <textarea id="dlgNote" rows="3"></textarea>
        <div class="dlg-acts">
          <button value="cancel" type="submit" class="btn-ghost">تراجع</button>
          <button value="ok" type="submit" class="btn-accept" id="dlgOk">حوّلها</button>
        </div>
      </form>`;
    document.body.appendChild(g);
    // لا يُعطَّل «حوّلها» بحساب الشاشة: يُضغط، والجسرُ يردّ بنصّه إن نقص شيء
    $('dlgPerson').addEventListener('change', () => {
      const o = $('dlgPerson').selectedOptions[0];
      $('dlgRoles').textContent = o && o.dataset.roles ? 'تكاليفه: ' + o.dataset.roles : '';
    });
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
    // أسماء الحقول من القاعدة (lbl_*) لكل مهمّة
    if (t.needs_date) { const i = inp('evOn', 'date'); i.value = new Date().toLocaleDateString('en-CA'); box.appendChild(field(t.lbl_date || 'التاريخ', i, true)); }
    if (t.needs_text) box.appendChild(field(t.lbl_text || 'ما تمّ', inp('evText', 'textarea'), true));
    if (t.needs_people) box.appendChild(field(t.lbl_people || 'من حضر أو من استلم', inp('evPeople', 'text'), true));
    if (t.needs_ref) box.appendChild(field(t.lbl_ref || 'رقم الصادر أو البلاغ', inp('evRef', 'text'), true));
    if (t.needs_file) {
      box.appendChild(field(t.lbl_file || 'المرفق (رقمه أو وصفه)', inp('evFile', 'text'), true));
      const r = el('label', 'check');
      const c = inp('evRefused', 'checkbox');
      r.append(c, ' امتنع عن التسليم أو الاستلام');
      box.appendChild(r);
    }
    if (t.needs_signature) {
      const r = el('label', 'check');
      const c = inp('evSigned', 'checkbox');
      r.append(c, ' ' + (t.lbl_sign || 'وُقّع'));
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

  let formChanged = false;

  // النماذج المبنية على رصد سلوكي تحتاج record_id في p_ref (٥–١٠)
  const NEEDS_REF = [5, 6, 7, 8, 9, 10];

  function setFormLink(t, studentId) {
    const btn = $('evFormBtn');
    const note = $('evFormNote');
    // التعبئة بمفتاح fill_form في can
    btn.hidden = !t.form_no || !M.state.me.can.fill_form;
    note.hidden = true;
    if (t.form_no && !M.state.me.can.fill_form) {
      note.textContent = M.lacks('تعبئة النماذج الرسمية');
      note.hidden = false;
    }
    if (btn.hidden) return;
    const ref = t.record_id || null;
    if (NEEDS_REF.includes(t.form_no) && !ref) {
      delete btn.dataset.src;
      btn.disabled = true;
      btn.classList.add('off');
      note.textContent = 'لا يُفتح النموذج بعد: يلزم أن يُرجع v2_student_tasks رقم الرصد (record_id) لهذه المهمّة.';
      note.hidden = false;
      return;
    }
    btn.classList.remove('off');
    btn.disabled = false;
    $('formDlgTitle').textContent = 'النموذج رقم ' + t.form_no + (t.form_title ? ': ' + t.form_title : '');
    btn.dataset.src = 'form.html?form=' + t.form_no + '&student=' + encodeURIComponent(studentId) + (ref ? '&ref=' + encodeURIComponent(ref) : '') +
      (t.task_id ? '&task=' + encodeURIComponent(t.task_id) : '');
  }

  // ---------- بابُ الإثبات العامّ: يرسم من v2_task_card ويُقفل بـ v2_task_evidence (تكليفُ الشاشات ② — الجزءُ الثالث) ----------
  // لا حسابَ هنا: الحقولُ وعناوينُها والنموذجُ والتوقيعُ والنفيُ المعروضُ والمانعُ كلُّها من البطاقة — والجسرُ وحدَه يُقفل.
  // opts.doors[kind](task) ⇒ زرٌّ ينقل المهمّةَ إلى بابها الخاصّ (الاتّصال · الخطّة · الإحالة · الحصر · نقل الفصل)
  // opts.note ⇒ رسالةُ الجسر بعد النجاح، تُعرض في مكانها أعلى البطاقة المعادة قراءتُها
  const SPECIAL = ['notify_guardian', 'plan', 'committee', 'follow_up', 'move_class'];
  async function evidenceDoor(taskId, studentId, onChanged, opts) {
    const V = window.MoayadView;
    opts = opts || {};
    const { data: c, error } = await M.rpc('v2_task_card', { p_task: taskId }, 'بطاقة المهمّة');
    if (error) { V.flash('bad', errText(error)); return; }
    const t = c.task || {};
    const ev = c.evidence || {};
    const need = ev.needs || {};
    const lb = ev.labels || {};
    const fl = c.filled || {};
    const again = (note) => setTimeout(() => evidenceDoor(taskId, studentId, onChanged, Object.assign({}, opts, { note })), 0);
    const head = el('div');
    if (opts.note) head.appendChild(el('div', 'rs-done-note', opts.note));
    head.appendChild(el('p', 'rs-meta', [t.problem_ar, t.degree_ar, t.step_ar ? 'الإجراء ' + t.step_ar : null, t.occurrence_ar ? 'الرصدة ' + t.occurrence_ar : null].filter(Boolean).join(' · ')));
    // المصدر ظاهرًا: نصُّ الدليل أم اجتهادُ المدرسة (origin كما يرجع)
    if (t.origin) head.appendChild(el('span', 'rs-tag' + (t.origin !== 'الدليل' ? ' own' : ''), t.origin));
    if (ev.label_ar) head.appendChild(el('p', null, ev.label_ar + (ev.hint_ar ? ' — ' + ev.hint_ar : '')));
    if (c.door && c.door !== 'بابُ الإثبات') head.appendChild(el('div', 'rs-door', c.door));
    const only = (extraNodes, ok, onOk) => V.form({ title: t.text_ar || '', fields: [{ key: 'h', type: 'node', node: head }].concat(extraNodes || []), ok: ok || false, onOk, cancel: 'إغلاق' });
    // ① بابٌ خاصّ ⇒ لا حقول · زرٌّ ينقله إلى بابه
    const go = opts.doors && opts.doors[t.kind];
    if (SPECIAL.includes(t.kind) && t.status === 'open') {
      if (go) only([], 'انتقل إلى بابه', () => { setTimeout(() => go(t), 0); return null; });
      else only();
      return;
    }
    // ② أُقفلت ⇒ من أقفلها وكيف، ولا حقول
    if (c.settled_ar) { head.appendChild(el('div', 'rs-settled', c.settled_ar)); only(); return; }
    const anyNeed = Object.keys(need).some((k) => need[k]);
    if (!anyNeed && !c.proposal) { only(); return; } // يقع آليًّا — لا يُثبَت باليد
    const fields = [{ key: 'h', type: 'node', node: head }];
    // ④ النفيُ المعروض: بطاقةٌ مستقلّة · حقلٌ مملوءٌ لا مفروض · ولا يُرسل من تلقاء نفسه ولا يُؤشَّر مسبقًا
    const pr = c.proposal;
    if (pr) {
      const nc = el('div', 'rs-neg');
      nc.appendChild(el('h5', null, pr.word_ar || ''));
      const ta = el('textarea');
      ta.rows = 3;
      ta.id = 'negText';
      ta.value = pr.text_ar || '';
      ta.setAttribute('aria-label', pr.word_ar || '');
      nc.appendChild(ta);
      if (pr.how_ar) nc.appendChild(el('p', 'rs-meta', pr.how_ar));
      if (pr.ask_ar) nc.appendChild(el('p', 'rs-ask', pr.ask_ar));
      const nerr = el('div', 'flash bad');
      nerr.hidden = true;
      const nb = V.btn('أُقرُّ النفي', 'rs-btn');
      nb.addEventListener('click', () => V.send(nb, async () => {
        nerr.hidden = true;
        const { error: e } = await M.rpc('v2_task_skip', { p_task: taskId, p_reason: ta.value.trim() || null }, 'إقرار النفي');
        if (e) { nerr.textContent = errText(e); nerr.hidden = false; return; }
        onChanged();
        again(null); // تُعاد قراءةُ البطاقة: settled_ar يقول من نفاه ومتى
      }));
      const r = el('div', 'rs-row');
      r.appendChild(nb);
      nc.append(nerr, r);
      fields.push({ key: 'neg', type: 'node', node: nc });
    }
    // ⑤ موجبٌ ظاهر ⇒ تنبيهٌ معلوماتيّ · ولا نفي
    if (c.grounds_ar) fields.push({ key: 'grounds', type: 'node', node: el('div', 'rs-info', c.grounds_ar) });
    // ⑥ حقلٌ لكلّ needs بعنوانه
    if (need.date) fields.push({ key: 'on', type: 'date', label: lb.date || '', value: fl.ev_on });
    if (need.text) fields.push({ key: 'text', type: 'textarea', label: lb.text || '', value: fl.ev_text });
    if (need.file) fields.push({ key: 'file', label: lb.file || '', value: fl.ev_file });
    if (need.ref) fields.push({ key: 'ref', label: lb.ref || '', value: fl.ev_ref });
    if (need.people) fields.push({ key: 'people', label: lb.people || '', value: fl.ev_people });
    // ⑦ النموذج: بطاقتُه كما ترجع — و«أثبت» لا يُفعَّل قبل form.ready (نصُّ التكليف)
    const f = c.form;
    const formWait = !!(need.form && f && !f.ready);
    if (need.form && f) {
      const fc = el('div', 'rs-file');
      fc.append(el('h5', null, 'النموذج ' + f.form_no + (f.title_ar ? ': ' + f.title_ar : '')));
      if (f.source) fc.appendChild(el('p', 'rs-meta', f.source));
      if (f.why_ar) fc.appendChild(el('p', null, f.why_ar));
      fc.appendChild(el('p', f.ready ? 'rs-state-done' : 'rs-state-open', f.ready ? 'اعتُمد النموذج' : (f.entry ? 'لم يُعتمد بعد' : 'لم يُفتح بعد')));
      if (!f.ready) {
        fc.appendChild(V.btn('افتح النموذج', 'rs-btn', () => {
          ensureDialogs();
          const src = 'form.html?form=' + f.form_no + '&student=' + encodeURIComponent(studentId) + (t.record ? '&ref=' + encodeURIComponent(t.record) : '') + '&task=' + encodeURIComponent(taskId);
          $('formDlgTitle').textContent = 'النموذج ' + f.form_no + (f.title_ar ? ': ' + f.title_ar : '');
          $('formFrame').src = src + '&embed=1';
          // بعد إغلاق النموذج تُقرأ البطاقةُ من جديد — فإن اعتُمد تفعّل «أثبت»
          $('formDlg').addEventListener('close', () => { evidenceDoor(taskId, studentId, onChanged, opts); onChanged(); }, { once: true });
          $('formDlg').showModal();
        }));
      }
      fields.push({ key: 'form', type: 'node', node: fc });
    }
    // ⑧ التوقيع: «وقّع» و«امتنع» متساويان ظاهران بحدٍّ لا ممتلئ — والامتناعُ بسببٍ مكتوبٍ يُتمّ الخطوة
    const rf = need.signature ? c.refusal : null;
    if (rf) fields.push({ key: 'refuse', type: 'textarea', label: 'سببُ الامتناع — إن امتنع', rows: 2 });
    // ③ المانعُ الآن: شريطٌ معلوماتيٌّ فوق الأفعال مباشرةً — والزرُّ يبقى، فالضغطُ يأتي بنصّ الجسر
    if (c.blocked_ar) fields.push({ key: 'blocked', type: 'node', node: el('div', 'rs-info', c.blocked_ar) });
    const send = async (v, signed, refuse) => {
      const { data, error: e } = await M.rpc('v2_task_evidence', {
        p_task: taskId, p_on: v.on || null, p_text: v.text || null, p_file: v.file || null, p_ref: v.ref || null,
        p_people: v.people || null, p_signed: signed, p_refuse: refuse,
      }, 'إثبات تنفيذ المهمّة');
      if (e) return e;
      if (!data || data.ok !== true) return 'لم يُقفل الجسرُ المهمّة';
      onChanged();
      again(data.note || ''); // رسالةُ الجسر في مكانها · والبطاقةُ تُعاد قراءتُها
      return null;
    };
    V.form({
      title: t.text_ar || '', what: c.signer_ar ? 'التوقيع: ' + c.signer_ar : '',
      fields,
      ok: rf ? (lb.sign || '') : 'أثبت',
      okDisabled: formWait,
      pair: !!rf,
      pairNote: rf ? (rf.note_ar || '') : '',
      onOk: (v) => send(v, need.signature ? true : null, null),
      extra: rf ? [{ text: rf.label_ar || '', cls: 'rs-btn', onClick: (v) => send(v, false, v.refuse) }] : [],
    });
  }

  async function closeTask(kind, t, onChanged, studentId) {
    ensureDialogs();
    setFormLink(t, studentId);
    $('evTask').textContent = t.text_ar;
    $('evHint').textContent = (t.evidence_ar ? 'الإثبات: ' + t.evidence_ar : '') + (t.hint_ar ? ' — ' + t.hint_ar : '');
    $('evForm').hidden = !t.form_no;
    $('evForm').textContent = t.form_no ? 'النموذج رقم ' + t.form_no + (t.form_title ? ': ' + t.form_title : '') : '';
    if (window.MoayadView) window.MoayadView.arabize($('evForm'));
    buildFields(t);
    formChanged = false;
    if (await ask($('evDlg')) !== 'ok') { if (formChanged) await onChanged(); return; }
    const { data, error } = await M.rpc(BRIDGE[kind].done, { p_task: t.task_id, p_ev: readEv() }, 'إغلاق مهمّة');
    if (error) { toast('لم تُغلق المهمّة:\n' + errText(error)); return; }
    toast('أُغلقت المهمّة' + (data && data.evidence_ar ? ' — ' + data.evidence_ar : '') + '.', true);
    await onChanged();
  }

  async function skipTask(kind, t, onChanged) {
    ensureDialogs();
    $('tskSkipText').textContent = t.text_ar;
    $('tskSkipReason').value = '';
    if (await ask($('tskSkipDlg')) !== 'ok') return;
    const { error } = await M.rpc(BRIDGE[kind].skip, { p_task: t.task_id, p_reason: $('tskSkipReason').value.trim() }, 'إسقاط مهمّة');
    if (error) { toast('لم تُسقَط المهمّة:\n' + errText(error)); return; }
    toast('أُسقطت المهمّة.', true);
    await onChanged();
  }

  // من يُحوَّل إليهم — من القاعدة لمدرسة الشاشة
  let staffCache = null;
  async function delegateTask(kind, t, onChanged) {
    ensureDialogs();
    $('dlgText').textContent = t.text_ar;
    $('dlgNote').value = '';
    $('dlgRoles').textContent = '';
    const sel = $('dlgPerson');
    sel.innerHTML = '';
    if (!staffCache || staffCache.school !== M.state.school) {
      const { data, error } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
      if (error) { toast('تعذّر جلب المنسوبين:\n' + errText(error)); return; }
      staffCache = { school: M.state.school, list: data || [] };
    }
    const ph = document.createElement('option');
    ph.value = '';
    ph.textContent = 'اختر المنسوب';
    sel.appendChild(ph);
    for (const p of staffCache.list) {
      const o = document.createElement('option');
      o.value = p.person_id;
      o.textContent = p.name_ar + (p.post_ar ? ' — ' + p.post_ar : '');
      o.dataset.roles = p.roles_ar || '';
      if (p.person_id === t.owner_person) o.textContent += ' (المُسندة إليه الآن)';
      sel.appendChild(o);
    }
    if (await ask($('dlgDelegate')) !== 'ok') return;
    const { data, error } = await M.rpc(BRIDGE[kind].delegate,
      { p_task: t.task_id, p_person: sel.value || null, p_note: $('dlgNote').value.trim() || null }, 'تحويل مهمّة');
    if (error) { toast('لم تُحوَّل المهمّة:\n' + errText(error)); return; }
    toast('حُوّلت المهمّة' + (data && data.to ? ' إلى ' + data.to : '') + '.', true);
    await onChanged();
  }

  function card(kind, t, onChanged, studentId) {
    const c = el('div', 'ev task t-' + t.status);
    const top = el('div', 'row1');
    const b = el('span', 'badge b-' + (t.status === 'open' ? 'late' : (t.status === 'done' || t.status === 'auto') ? 'present' : 'unrecorded'),
      STATUS_AR[t.status] || t.status);
    top.append(el('div', 'detail', t.text_ar), b);
    c.appendChild(top);
    const meta = kind === 'behavior'
      ? (t.kind_ar ? t.kind_ar + ' · ' : '') + (t.problem_ar ? t.problem_ar + (t.degree_ar || t.degree_no ? ' — ' + (t.degree_ar || 'الدرجة ' + t.degree_no) : '') + ' · ' : '') + (t.occurred_on || '')
      : 'غياب ' + t.days_n + ' أيام ' + (t.excused ? 'بعذر' : 'بلا عذر') + ' · ' + (t.triggered_on || '');
    c.appendChild(el('div', 'meta', meta));
    // المُسندة إلى شخص بعينه تُعرض باسمه وسبب تحويلها
    if (t.owner_person) {
      c.appendChild(el('div', 'meta assigned', 'مُسندة إلى ' + (t.owner_ar || '—') + (t.delegate_note ? ' — بسبب: ' + t.delegate_note : '')));
    } else {
      c.appendChild(el('div', 'meta', 'المسؤول: ' + (t.owner_role_ar || t.owner_role || '—')));
    }
    if (t.evidence_ar) c.appendChild(el('div', 'meta', 'الإثبات: ' + t.evidence_ar));
    // الآلي يقع في القاعدة (الحسم والتعويض) فلا يُسأل عنه إثبات
    if (t.status === 'auto') {
      c.appendChild(el('div', 'meta', 'وقعت آلياً في القاعدة — لا تُغلق من هنا.'));
    } else if (t.status === 'open') {
      if (!M.state.me.can.close_task) {
        c.appendChild(el('div', 'meta nocan', M.lacks('إغلاق المهامّ')));
      } else if (t.evidence_kind === 'auto') {
        c.appendChild(el('div', 'meta', 'تقع آلياً في القاعدة — لا تُغلق من هنا.'));
      } else if (kind === 'behavior' && t.door_ar && t.door_ar !== 'بابُ الإثبات') {
        // ليس من باب الإثبات: اسمُ بابه كما يرجع — ومتابعةُ الموجّه حالٌ تُعرض ولا تُطالَب
        c.classList.toggle('t-grey', t.evidence_kind === 'services_review');
        c.appendChild(el('div', 'meta', t.door_ar));
      } else if (kind === 'behavior') {
        const acts = el('div', 'acts two');
        const ok = el('button', 'a-accept', 'أثبت');
        ok.type = 'button';
        ok.addEventListener('click', () => evidenceDoor(t.task_id, studentId, onChanged));
        const no = el('button', 'a-reject', 'إسقاط بسبب');
        no.type = 'button';
        no.addEventListener('click', () => skipTask(kind, t, onChanged));
        acts.append(ok, no);
        c.appendChild(acts);
      } else {
        const acts = el('div', 'acts two');
        const ok = el('button', 'a-accept', 'أغلقها بإثبات');
        ok.type = 'button';
        ok.addEventListener('click', () => closeTask(kind, t, onChanged, studentId));
        const no = el('button', 'a-reject', 'إسقاط بسبب');
        no.type = 'button';
        no.addEventListener('click', () => skipTask(kind, t, onChanged));
        acts.append(ok, no);
        c.appendChild(acts);
      }
      // التحويل بمفتاحه في can — والقاعدة تحرسه
      if (M.state.me.can.delegate_task && t.evidence_kind !== 'auto') {
        const dg = el('button', 'btn-ghost wide', t.owner_person ? 'إعادة التحويل' : 'حوّلها إلى منسوب');
        dg.type = 'button';
        dg.addEventListener('click', () => delegateTask(kind, t, onChanged));
        c.appendChild(dg);
      } else if (!M.state.me.can.delegate_task && t.evidence_kind !== 'auto') {
        c.appendChild(el('div', 'meta nocan', M.lacks('تحويل المهامّ')));
      }
    }
    return c;
  }

  // تعرض مهامّ الطالب كلّها: السلوك ثم الغياب
  // v2_student_tasks يرجع jsonb بأسمائه (task · record · text · problem …) ومعها needs_* · lbl_* · ev_* · form_no · form_title كما هي:
  // تُطابَق الأسماءُ الأولى على أسماء البطاقة، والنموذجُ برقمه من القاعدة — وما لا نموذجَ له يرجع فارغًا فلا رابطَ له
  const norm = (t) => Object.assign({}, t, {
    task_id: t.task_id || t.task, record_id: t.record_id || t.record, text_ar: t.text_ar || t.text,
    problem_ar: t.problem_ar || t.problem, owner_role: t.owner_role || t.owner,
  });

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
      for (const t of res.data) box.appendChild(card(kind, kind === 'behavior' ? norm(t) : t, again, studentId));
    }
    // في الشاشات التي تحمل views.js تُعرض الأرقامُ عربيّةً كسائرها
    if (window.MoayadView) window.MoayadView.arabize(box);
  }

  window.MoayadTasks = { render, evidenceDoor };
})();
