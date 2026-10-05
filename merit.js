// مؤيّد · التعويض والسلوك المتميّز — بنكُ الفرص · إقرارُ المشاركات · فرصي.
// v2_merits · v2_opps_list · v2_opp_open · v2_opp_close · v2_opp_card · v2_opp_plan · v2_opps_open_for
// v2_entries_pending · v2_entry_verdict · v2_entry_delegate · v2_entry_grade · v2_entry_file
// لا حسابَ في الشاشة: القاعدةُ تقسم المنحَ (تعويض · اكتساب · مهدور) وترجعه. والمرفقُ يُرفع إلى المخزن ثم يُمرَّر مسارُه.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'merit';

  const BUCKET = 'v2-attachments';
  const VERDICTS = ['نفّذ', 'نفّذ جزئيًّا', 'لم ينفّذ', 'لم يحضر'];
  const STATE_CLS = { 'مفتوحة': 'st-held', 'مُغلقة': 'st-minuted', 'مُعتمدة': 'st-approved' };

  const ui = { me: null, school: null, tab: 'bank', opps: [], oppId: null, card: null, merits: null, staff: null, pending: [] };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }
  function btn(cls, text, fn) {
    const b = el('button', cls, text);
    b.type = 'button';
    b.addEventListener('click', fn);
    return b;
  }
  async function reason(title, what, label) {
    $('reasonTitle').textContent = title;
    $('reasonWhat').textContent = what || '';
    $('reasonLabel').textContent = label || 'السبب — إلزامي';
    $('reasonText').value = '';
    $('reasonOk').disabled = true;
    if (await ask($('reasonDlg')) !== 'ok') return null;
    return $('reasonText').value.trim();
  }
  async function staff() {
    if (ui.staff) return ui.staff;
    const { data, error } = await M.rpc('v2_staff_list', { p_school: ui.school }, 'قائمة المنسوبين');
    if (error) { toast('تعذّر جلب المنسوبين:\n' + errText(error)); return null; }
    ui.staff = data || [];
    return ui.staff;
  }

  // الشاهد: رابطٌ موقَّتٌ من المخزن — والقراءةُ تحرسها سياسةُ المخزن
  async function openEvidence(path) {
    const { data, error } = await M.sb.storage.from(BUCKET).createSignedUrl(path, 300);
    if (error) { toast('تعذّر فتح المرفق:\n' + errText(error)); return; }
    window.open(data.signedUrl, '_blank', 'noopener');
  }
  function evidenceLine(box, desc, path) {
    const line = el('div', 'meta', 'الشاهد: ' + (desc || '—'));
    if (path) {
      const a = btn('linkbtn', 'افتح المرفق', () => openEvidence(path));
      line.appendChild(a);
    }
    box.appendChild(line);
  }

  // ---------- ١ · بنكُ الفرص ----------
  async function loadBank() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_opps_list', { p_school: ui.school, p_state: null, p_days: 180 }, 'بنك الفرص');
    ui.opps = error ? [] : (data || []);
    ui.bankErr = error ? errText(error) : '';
    if (ui.oppId) await loadCard(); else render();
  }

  function renderBank(box) {
    if (ui.oppId && ui.card) { renderCard(box); return; }
    box.appendChild(btn('btn-main', 'افتح فرصة', openOpp));
    if (ui.bankErr) box.appendChild(el('div', 'notice err', ui.bankErr));
    if (!ui.opps.length) { box.appendChild(el('div', 'empty', 'لا فرص في المدة.')); return; }
    for (const o of ui.opps) {
      const r = el('div', 'ev meeting ' + (STATE_CLS[o.state] || ''));
      const top = el('div', 'row1');
      top.append(el('div', 'name', o.title || o.merit || ''), el('span', 'badge mstatus', o.state || ''));
      r.appendChild(top);
      r.appendChild(el('div', 'meta', [o.group, o.kind, o.when].filter(Boolean).join(' · ')));
      r.appendChild(el('div', 'meta', (o.points_note || '') + (o.source ? ' · ' + o.source : '')));
      r.appendChild(el('div', 'meta', 'المسجّلون ' + o.joined + (o.capacity ? ' من ' + o.capacity : '') +
        ' · رفعوا نماذجهم ' + o.filed + ' · أُقرّ ' + o.verdicted + ' · قُدّر ' + o.graded));
      if (o.close_why) r.appendChild(el('div', 'meta', 'سببُ الإغلاق: ' + o.close_why));
      if (o.held_by) r.appendChild(el('div', 'meta', 'يقيمها: ' + o.held_by));
      r.appendChild(btn('btn-ghost wide', 'مخطّطُ الفرصة', () => { ui.oppId = o.opp; loadCard(); }));
      box.appendChild(r);
    }
  }

  async function openOpp() {
    if (!ui.merits) {
      const { data, error } = await M.rpc('v2_merits', undefined, 'ممارسات السلوك المتميّز');
      if (error) { toast('تعذّر جلب الممارسات:\n' + errText(error)); return; }
      ui.merits = data || [];
    }
    const sel = $('oMerit');
    sel.textContent = '';
    for (const m of ui.merits) {
      const o = document.createElement('option');
      o.value = m.id;
      o.textContent = (m.group ? m.group + ' — ' : '') + m.text;
      sel.appendChild(o);
    }
    const info = () => {
      const m = ui.merits.find((x) => String(x.id) === sel.value);
      $('oMeritInfo').textContent = m ? (m.points_note || '') + (m.source ? ' · ' + m.source : '') : '';
    };
    sel.onchange = info;
    info();
    const held = $('oHeld');
    held.textContent = '';
    for (const p of (await staff()) || []) {
      const o = document.createElement('option');
      o.value = p.person_id;
      o.textContent = p.name_ar + (p.post_ar ? ' — ' + p.post_ar : '');
      held.appendChild(o);
    }
    for (const id of ['oTitle', 'oWhen', 'oCap']) $(id).value = '';
    $('oOk').disabled = true;
    if (await ask($('openDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_opp_open', {
      p_school: ui.school, p_merit: Number(sel.value), p_kind: $('oKind').value, p_title: $('oTitle').value.trim() || null,
      p_when: $('oWhen').value.trim(), p_capacity: $('oCap').value ? Number($('oCap').value) : null, p_held_by: held.value || null,
    }, 'فتح فرصة');
    if (error) { toast('لم تُفتح الفرصة:\n' + errText(error)); return; }
    toast('فُتحت الفرصة: ' + ((data && data.merit) || ''), true);
    ui.oppId = data && data.opp;
    await loadBank();
  }

  async function loadCard() {
    const { data, error } = await M.rpc('v2_opp_card', { p_opp: ui.oppId }, 'مخطّط الفرصة');
    if (error) { toast('تعذّر فتح المخطّط:\n' + errText(error)); ui.oppId = null; ui.card = null; render(); return; }
    ui.card = data;
    render();
  }

  function renderCard(box) {
    const c = ui.card;
    const o = c.opp || {};
    const m = c.merit || {};
    box.appendChild(btn('btn-ghost wide', '← بنكُ الفرص', () => { ui.oppId = null; ui.card = null; loadBank(); }));
    const head = el('div', 'ev meeting ' + (STATE_CLS[o.state] || ''));
    const top = el('div', 'row1');
    top.append(el('div', 'name', o.title_ar || m.text || ''), el('span', 'badge mstatus', o.state || ''));
    head.appendChild(top);
    head.appendChild(el('div', 'meta', [m.group, o.kind, o.when_ar].filter(Boolean).join(' · ')));
    head.appendChild(el('div', 'meta', (m.points_note || '') + (m.source ? ' · ' + m.source : '')));
    head.appendChild(el('div', 'meta', 'يقيمها: ' + (c.held_by || '—') + (o.capacity ? ' · السعة ' + o.capacity : ' · بلا حدّ')));
    if (o.close_why) head.appendChild(el('div', 'meta', 'سببُ الإغلاق: ' + o.close_why));
    if (o.plan_note) head.appendChild(el('div', 'detail', 'اعتُمد المخطّط: ' + o.plan_note));
    box.appendChild(head);
    if (o.state === 'مفتوحة') box.appendChild(btn('btn-ghost wide', 'أغلقها — انتهى الوقت', closeOpp));

    box.appendChild(el('h3', 'grp', 'المشاركون'));
    const members = c.members || [];
    if (!members.length) box.appendChild(el('div', 'empty', 'لم يسجّل أحد.'));
    for (const x of members) {
      const r = el('div', 'ev');
      const t = el('div', 'row1');
      t.append(el('div', 'name', x.name || ''), el('span', 'badge', x.graded ? 'قُدّر ' + x.points : x.verdict || (x.filed ? 'رُفع نموذجُه' : 'لم يرفع نموذجه')));
      r.appendChild(t);
      if (x.what) r.appendChild(el('div', 'detail', 'ماذا فعل: ' + x.what));
      if (x.filed) evidenceLine(r, x.evidence, x.evidence_file);
      if (x.verdict) r.appendChild(el('div', 'meta', 'الحكم: ' + x.verdict + (x.note ? ' — ' + x.note : '') + (x.by ? ' · ' + x.by : '')));
      if (x.delegated) r.appendChild(el('div', 'meta', 'أُحيل الإقرار: ' + x.delegated));
      if (x.verdict && !x.graded) r.appendChild(btn('btn-accept wide', 'قدّر درجته', () => grade(x, m)));
      // رفعُ الشاهد نيابةً يلزمه معرّفُ الطالب في المخطّط لبناء مسار المخزن
      if (!x.filed && o.state !== 'مفتوحة' && x.student_id) r.appendChild(btn('btn-ghost wide', 'ارفع نموذجه نيابةً', () => fileFor(x.entry, x.student_id, x.name)));
      box.appendChild(r);
    }
    if (o.state !== 'مفتوحة' && !o.plan_note) box.appendChild(btn('btn-main', 'اعتمد المخطّط', plan));
  }

  async function closeOpp() {
    const r = await reason('إغلاق الفرصة', (ui.card.merit || {}).text, 'سببُ الإغلاق — إلزامي');
    if (r == null) return;
    const { error } = await M.rpc('v2_opp_close', { p_opp: ui.oppId, p_why: r }, 'إغلاق فرصة');
    if (error) { toast('لم تُغلق:\n' + errText(error)); return; }
    toast('أُغلقت الفرصة.', true);
    loadCard();
  }

  async function grade(x, m) {
    $('gradeWhat').textContent = x.name + ' — ' + (m.text || '');
    $('gradeInfo').textContent = (m.points_note || '') + (m.source ? ' · ' + m.source : '');
    $('gradePts').value = '';
    $('gradeNote').value = '';
    if (await ask($('gradeDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_entry_grade', {
      p_entry: x.entry, p_points: $('gradePts').value === '' ? null : Number($('gradePts').value), p_note: $('gradeNote').value.trim() || null,
    }, 'تقدير الدرجة');
    if (error) { toast('لم تُقدَّر:\n' + errText(error)); return; }
    // القسمةُ كما رجعت من القاعدة
    const d = data || {};
    const s = d['الدرجة'] || {};
    toast('منح ' + d['منح'] + ' · تعويض ' + d['تعويض'] + ' · اكتساب ' + d['اكتساب'] + ' · مهدور ' + d['مهدور'] +
      '\nالإيجابيّ ' + s.positive + ' من 80 · المتميّز ' + s.merit + ' من 20 · المجموع ' + s.total + ' من 100', true);
    loadCard();
  }

  async function plan() {
    const r = await reason('اعتماد مخطّط الفرصة', (ui.card.merit || {}).text, 'توصيةُ اللجنة — إلزاميّة');
    if (r == null) return;
    const { error } = await M.rpc('v2_opp_plan', { p_opp: ui.oppId, p_note: r }, 'اعتماد المخطّط');
    if (error) { toast('لم يُعتمد:\n' + errText(error)); return; }
    toast('اعتُمد المخطّط.', true);
    loadCard();
  }

  // نموذجُ المشاركة: يُرفع الملفُّ إلى مساره المفروض ثم يُمرَّر المسار
  async function fileFor(entry, student, label) {
    $('fileWhatFor').textContent = label || '';
    $('fWhat').value = '';
    $('fDesc').value = '';
    $('fFile').value = '';
    $('fOk').disabled = true;
    if (await ask($('fileDlg')) !== 'ok') return;
    const f = $('fFile').files[0];
    const safe = f.name.replace(/[^\w.-]+/g, '_');
    const path = 'merit/' + ui.school + '/' + student + '/' + entry + '/' + Date.now() + '-' + safe;
    const up = await M.sb.storage.from(BUCKET).upload(path, f, { upsert: false });
    if (up.error) {
      M.logError({ message: up.error.message, fn: 'storage.upload', action: 'رفع الشاهد', params: { path } });
      toast('لم يُرفع الملف:\n' + errText(up.error));
      return;
    }
    const { data, error } = await M.rpc('v2_entry_file', {
      p_entry: entry, p_what: $('fWhat').value.trim(), p_evidence_path: path, p_evidence_desc: $('fDesc').value.trim(),
    }, 'نموذج المشاركة');
    if (error) { toast('لم يُرفع النموذج:\n' + errText(error)); return; }
    toast('رُفع النموذج' + (data && data.by ? ' — ' + data.by : '') + '.', true);
    if (ui.oppId) loadCard(); else loadPending();
  }

  // ---------- ٢ · إقرارُ المشاركات ----------
  async function loadPending() {
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: ui.school }, 'ما ينتظر الإقرار');
    ui.pending = error ? [] : (data || []);
    ui.pendingErr = error ? errText(error) : '';
    render();
  }

  function renderVerdict(box) {
    if (ui.pendingErr) box.appendChild(el('div', 'notice err', ui.pendingErr));
    if (!ui.pending.length) { box.appendChild(el('div', 'empty', 'لا مشاركات تنتظر إقرارك.')); return; }
    for (const x of ui.pending) {
      const r = el('div', 'ev');
      const t = el('div', 'row1');
      t.append(el('div', 'name', x.student || ''), el('span', 'badge', x.delegated_to_me ? 'أُحيلت إليك' : 'تنتظر إقرارك'));
      r.appendChild(t);
      r.appendChild(el('div', 'meta', (x.merit || '') + (x.when ? ' · ' + x.when : '')));
      if (x.delegate_note) r.appendChild(el('div', 'meta', 'سببُ الإحالة: ' + x.delegate_note));
      // ما كتبه الطالبُ ومرفقُه قبل أزرار الحكم
      r.appendChild(el('div', 'detail', 'ماذا فعل: ' + (x.what || '—')));
      evidenceLine(r, x.evidence, x.evidence_path);
      const acts = el('div', 'acts two');
      for (const v of VERDICTS) acts.appendChild(btn('', v, () => verdict(x, v)));
      r.appendChild(acts);
      r.appendChild(btn('btn-ghost wide', 'أحِل الإقرار إلى من حضر', () => delegate(x)));
      box.appendChild(r);
    }
  }

  async function verdict(x, v) {
    const note = await reason('الحكم: ' + v, x.student + ' — ' + (x.merit || ''), 'ملاحظتك — إلزاميّة');
    if (note == null) return;
    const { error } = await M.rpc('v2_entry_verdict', { p_entry: x.entry, p_verdict: v, p_note: note, p_file: null }, 'إقرار مشاركة');
    if (error) { toast('لم يُسجَّل الحكم:\n' + errText(error)); return; }
    toast('سُجّل الحكم: ' + v, true);
    loadPending();
  }

  async function delegate(x) {
    $('delegWhat').textContent = x.student + ' — ' + (x.merit || '');
    const sel = $('delegTo');
    sel.textContent = '';
    for (const p of (await staff()) || []) {
      const o = document.createElement('option');
      o.value = p.person_id;
      o.textContent = p.name_ar;
      sel.appendChild(o);
    }
    $('delegNote').value = '';
    $('delegOk').disabled = true;
    if (await ask($('delegDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_entry_delegate', { p_entry: x.entry, p_person: sel.value, p_note: $('delegNote').value.trim() }, 'إحالة الإقرار');
    if (error) { toast('لم تُحَل:\n' + errText(error)); return; }
    toast('أُحيل الإقرار.', true);
    loadPending();
  }

  // ---------- ٣ · فرصي — للطالب ووليّه ----------
  function renderMine(box) {
    box.appendChild(el('div', 'notice nostudy', 'مغلقةٌ حتى تُفتح حساباتُ الطلاب — «فرصي» يستعملها الطالبُ أو وليُّ أمره من حسابه.'));
  }

  // ---------- العرض ----------
  function render() {
    for (const t of ['bank', 'verdict', 'mine']) {
      const box = $('t_' + t);
      box.hidden = ui.tab !== t;
      box.textContent = '';
    }
    for (const b of document.querySelectorAll('#tabs button')) b.setAttribute('aria-pressed', String(b.dataset.tab === ui.tab));
    if (ui.tab === 'bank') renderBank($('t_bank'));
    if (ui.tab === 'verdict') renderVerdict($('t_verdict'));
    if (ui.tab === 'mine') renderMine($('t_mine'));
  }

  // ---------- الأحداث ----------
  for (const b of document.querySelectorAll('#tabs button')) {
    b.addEventListener('click', () => {
      ui.tab = b.dataset.tab;
      if (ui.tab === 'bank') loadBank(); else if (ui.tab === 'verdict') loadPending(); else render();
    });
  }
  $('reasonText').addEventListener('input', () => { $('reasonOk').disabled = $('reasonText').value.trim() === ''; });
  $('oWhen').addEventListener('input', () => { $('oOk').disabled = $('oWhen').value.trim() === ''; });
  $('delegNote').addEventListener('input', () => { $('delegOk').disabled = $('delegNote').value.trim() === ''; });
  const fReady = () => { $('fOk').disabled = !$('fWhat').value.trim() || !$('fDesc').value.trim() || !$('fFile').files.length; };
  for (const id of ['fWhat', 'fDesc']) $(id).addEventListener('input', fReady);
  $('fFile').addEventListener('change', fReady);
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  // ---------- الدخول ----------
  async function enter() {
    let me;
    try { await M.defaultRole(); me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    ui.me = me;
    M.state.me = me;
    M.renderHeader(me, async (r) => { const m = await M.actAs(r); if (m) location.reload(); });
    M.renderNav(me, 'merit');
    if (!me) { M.gate('حسابك غير مسند إلى منسوب في مؤيّد.'); return; }
    const cur = (me.roles || []).find((r) => r.is_current === true && r.school_id);
    const schools = (me.schools || []).filter((x) => !cur || x.id === cur.school_id);
    if (!schools.length) { M.gate('لا مدرسة مسندة لحسابك.'); return; }
    ui.school = schools[0].id;
    $('mView').hidden = false;
    await loadBank();
  }

  (async () => {
    const { data } = await M.sb.auth.getSession();
    if (!data.session) { location.replace('./'); return; }
    await enter();
  })();
})();
