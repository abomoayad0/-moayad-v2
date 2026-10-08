// مؤيّد · بوّابة وليّ الأمر — viewG في المحاكي: بطاقةُ الابن · رصداتُه · ما فعلته المدرسة · سلوكُه المتميّز · نماذج تنتظرك.
// ⑤ «اتّصلت بك المدرسة» من أحداث guardian_contact في السجلّ · ودعواتُ المدرسة: v2_guardian_pending ⇒ v2_guardian_reply
// خطّةُ تعديل السلوك ورأيُه: v2_plan_of ⇒ v2_plan_opinion(guardian) · ونصيحةُ الرصدة: v2_record_advice
// v2_guardian_me · v2_guardian_child · v2_opps_open_for · v2_student_timeline(p_student, 'guardian') · v2_guardian_forms · v2_guardian_form_read
// v2_guardian_form_reply · v2_form_sign(p_entry, 'ولي الأمر', …)
// 🔒 لا يرى دراسةَ الحالة ولا الجلسات: يُطلب السجلُّ بصفة 'guardian' لا غير، والقاعدةُ تحجب ما سواه.
// ولا بنكَ عباراتٍ في ردّه — كلامُه رأيُه. وما لم يُبنَ في المحرّك معطَّلٌ بسببه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { ar, arabize, btn, flash, pick } = V;

  const SIGNER = 'ولي الأمر';
  const ui = { g: null, kid: null, forms: [], read: new Set(), busy: false };

  function selectKid(id) {
    ui.kid = (ui.g.children || []).find((k) => k.student_id === id) || null;
    const kids = ui.g.children || [];
    $('kids').hidden = kids.length < 2;
    if (kids.length > 1) pick($('kids'), kids.map((k) => [k.student_id, k.name]), id, selectKid);
    loadKid();
  }

  async function loadKid() {
    const k = ui.kid;
    if (!k) return;
    // بطاقةُ الابن من جسور البوّابة وحدها: v2_guardian_child — لا بطاقةُ المنسوبين (v2_student_card)
    const [child, opp, tl, pend, plans] = await Promise.all([
      M.rpc('v2_guardian_child', { p_student: k.student_id }, 'بطاقة الابن'),
      M.rpc('v2_opps_open_for', { p_student: k.student_id }, 'درجة السلوك'),
      M.rpc('v2_student_timeline', { p_student: k.student_id, p_as: 'guardian' }, 'سجلّ الابن'),
      M.rpc('v2_guardian_pending', { p_student: k.student_id }, 'الدعوات المنتظرة'),
      M.rpc('v2_plan_of', { p_student: k.student_id }, 'خطّة تعديل السلوك'),
    ]);
    const st = (child.data && child.data.student) || k;
    $('kidName').textContent = st.name || k.name || '';
    $('kidMeta').textContent = [st.class_ar, st.school, st.student_no ? 'رقمه ' + st.student_no : null].filter(Boolean).join(' · ');
    const att = $('attend');
    att.textContent = '';
    if (child.error) att.appendChild(el('div', 'notice err', errText(child.error)));
    else {
      const a = (child.data && child.data.attendance) || {};
      // مفاتيحُ الحضور عربيّةٌ كما يرجعها v2.fn_attendance_state
      if (a['أيام_بعذر'] != null || a['أيام_بلا_عذر'] != null) {
        att.appendChild(el('p', 'rs-meta', 'الغياب: بعذر ' + (a['أيام_بعذر'] || 0) + ' · بلا عذر ' + (a['أيام_بلا_عذر'] || 0) + (a['الحرمان'] ? ' · بلغ حدَّ الحرمان' : '')));
      }
      if (a['تنبيه']) att.appendChild(el('div', 'rs-note', a['تنبيه']));
    }
    arabize($('kidCard'));
    renderScore(opp);
    renderTimeline(tl);
    renderInvites(pend);
    renderPlans(plans);
    renderMerit(opp);
    renderForms();
  }

  // ① الدرجةُ من القاعدة كما ترجع — ولا تُحسب هنا
  function renderScore(r) {
    const box = $('score');
    box.textContent = '';
    if (r.error) { box.appendChild(el('div', 'notice err', 'تعذّر جلبُ درجة السلوك: ' + errText(r.error))); return; }
    const s = (r.data && r.data.score) || {};
    const chips = el('div', 'rs-pick');
    chips.append(el('span', 'k', 'الإيجابيُّ ' + s.positive + ' من ٨٠'), el('span', 'k', 'المتميّزُ ' + s.merit + ' من ٢٠'), el('span', 'k', 'المجموعُ ' + s.total + ' من ١٠٠'));
    box.appendChild(chips);
    if (r.data && r.data.purpose) box.appendChild(el('div', 'rs-note', r.data.purpose));
    arabize(box);
  }

  // ② ③ من السجلّ بصفة وليّ الأمر
  function renderTimeline(r) {
    const recs = $('recs');
    recs.textContent = '';
    const tlBox = $('timeline');
    if (r.error) {
      recs.appendChild(el('div', 'notice err', errText(r.error)));
      tlBox.textContent = '';
      tlBox.appendChild(el('div', 'notice err', errText(r.error)));
      return;
    }
    const evs = (r.data && r.data.events) || [];
    // ⑤ اتّصلت بك المدرسة: نوعُها الخاصّ guardian_contact
    const cbox = $('contacts');
    cbox.textContent = '';
    const calls = evs.filter((e) => e.kind === 'guardian_contact');
    if (!calls.length) cbox.appendChild(el('p', 'rs-meta', 'لم يُسجَّل اتّصالٌ بك بعد.'));
    else {
      const ul = el('ul', 'rs-acts');
      for (const e of calls) {
        const li = el('li');
        const body = el('span');
        body.style.flex = '1';
        body.appendChild(el('span', null, e.title || ''));
        if (e.body) body.appendChild(el('div', 'rs-meta', e.body));
        li.append(el('i', 'rs-tick ok', '✓'), body, el('small', 'rs-who', e.on || ''));
        ul.appendChild(li);
      }
      cbox.appendChild(ul);
    }
    arabize(cbox);
    const beh = evs.filter((e) => e.kind === 'behavior_record');
    if (!beh.length) recs.appendChild(el('p', 'rs-meta', 'لا رصداتِ على ابنك.'));
    else {
      const ul = el('ul', 'rs-acts');
      for (const e of beh) {
        const li = el('li');
        const body = el('span');
        body.style.flex = '1';
        body.appendChild(el('span', null, e.title || ''));
        if (e.body) body.appendChild(el('div', 'rs-meta', e.body));
        li.append(el('i', 'rs-tick ok', '✓'), body, el('small', 'rs-who', e.on || ''));
        ul.appendChild(li);
        // النصيحةُ التربويّة من الرصدة نفسِها (v2_record_advice) — متى حمل الحدثُ رقمَ رصدته
        const rec = e.record || e.ref_id;
        if (rec) adviceOf(rec, body);
      }
      recs.appendChild(ul);
    }
    arabize(recs);
    $('tlSum').textContent = 'السجلّ (' + ar(evs.length) + ')';
    V.events(tlBox, evs);
  }

  async function adviceOf(rec, body) {
    const { data } = await M.rpc('v2_record_advice', { p_record: rec }, 'نصيحة الرصدة');
    if (!data || !data.text) return;
    const a = el('div', 'rs-advice');
    a.append(el('b', null, 'نصيحةٌ لابنك: '), document.createTextNode(data.text));
    body.appendChild(a);
  }

  // دعواتُ المدرسة من v2_guardian_pending: ما لم يُردّ عليه ينتظر ردَّه، وما ردّ عليه يظهر ردُّه ولا يُسأل ثانية
  const REPLIES = ['أحضر', 'أعتذر وأقترح موعدًا', 'لا أستطيع']; // كما يقبلها v2_guardian_reply — والقاعدةُ ترفض غيرها
  function renderInvites(r) {
    const box = $('invites');
    box.textContent = '';
    if (r.error) { box.appendChild(el('div', 'notice err', errText(r.error))); return; }
    const list = r.data || [];
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لا دعوةَ تنتظر ردَّك.')); return; }
    for (const e of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, e.title || ''), el('p', null, [e.body, e.on_date].filter(Boolean).join(' · ')));
      if (e.replied) {
        f.appendChild(el('p', 'rs-state-done', 'ردُّك: ' + (e.reply || '') + (e.suggested ? ' · تقترح ' + e.suggested : '') + (e.reply_note ? ' — ' + e.reply_note : '')));
      } else {
        if (e.action) f.appendChild(el('p', 'rs-meta', e.action));
        f.appendChild(btn('ردّ على الدعوة', 'rs-btn', () => inviteReply(e)));
      }
      box.appendChild(f);
    }
    arabize(box);
  }

  function inviteReply(e) {
    const k = ui.kid;
    V.form({
      title: 'ردُّك على الدعوة', what: e.title || '',
      fields: [
        { key: 'reply', type: 'pick', label: 'ردُّك', items: REPLIES.map((x) => [x, x]) },
        { key: 'date', type: 'date', label: 'الموعدُ الذي تقترحه', show: (v) => v.reply === 'أعتذر وأقترح موعدًا' },
        { key: 'note', type: 'textarea', label: 'ملاحظتُك', rows: 2, hint: 'وإن لم تستطع فاكتب سببَك' },
      ],
      ok: 'أرسل ردَّك',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_guardian_reply', {
          p_student: k.student_id, p_event: e.event || null, p_kind: 'دعوة', p_reply: v.reply, p_note: v.note,
          p_suggested: v.reply === 'أعتذر وأقترح موعدًا' ? v.date : null,
        }, 'ردّ وليّ الأمر');
        if (error) return error;
        flash('ok', (data && data.note) || 'وصل ردُّك إلى المدرسة');
        loadKid();
        return null;
      },
    });
  }

  // خطّةُ تعديل السلوك ورأيُه فيها: رأيُ وليّ الأمر يكتبه هو (v2_plan_opinion · guardian)
  function renderPlans(r) {
    const box = $('plans');
    box.textContent = '';
    if (r.error) { box.appendChild(el('div', 'notice err', 'تعذّر جلبُ الخطّة: ' + errText(r.error))); return; }
    const list = r.data || [];
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لم تُكتب لابنك خطّة.')); return; }
    for (const p of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (p.target || '—') + ' — ' + (p.state_ar || '')), el('p', null, p.desc || ''));
      const steps = (Array.isArray(p.steps) ? p.steps : String(p.steps || '').split('\n')).filter((x) => String(x).trim() !== '');
      if (steps.length) { const ul = el('ul', 'rs-acts'); for (const x of steps) ul.appendChild(el('li', null, '• ' + x)); f.appendChild(ul); }
      f.appendChild(el('p', null, 'رأيُك: ' + (p.guardian || 'لم تُبدِه بعد')));
      if (p.status === 'draft') f.appendChild(btn(p.guardian ? 'عدّل رأيَك' : 'أبدِ رأيَك', 'rs-btn', () => V.form({
        title: 'رأيُك في الخطّة', what: p.target || '',
        fields: [{ key: 'text', type: 'textarea', label: 'رأيُك', rows: 3, value: p.guardian }],
        ok: 'أرسل رأيَك',
        onOk: async (v) => {
          const { error } = await M.rpc('v2_plan_opinion', { p_plan: p.plan, p_who: 'guardian', p_text: v.text }, 'رأيُ وليّ الأمر');
          if (error) return error;
          flash('ok', 'وصل رأيُك إلى المدرسة');
          loadKid();
          return null;
        },
      })));
      box.appendChild(f);
    }
    arabize(box);
  }

  // ④ ما قدّرته اللجنة
  function renderMerit(r) {
    const box = $('merit');
    box.textContent = '';
    if (r.error) { box.appendChild(el('div', 'notice err', errText(r.error))); return; }
    const done = ((r.data && r.data.mine) || []).filter((x) => x.graded);
    if (!done.length) { box.appendChild(el('p', 'rs-meta', 'لم يُقدَّر لابنك سلوكٌ متميّزٌ بعد.')); return; }
    const ul = el('ul', 'rs-acts');
    for (const x of done) {
      const li = el('li');
      li.append(el('i', 'rs-tick ok', '✓'), el('span', null, x.merit || ''), el('small', 'rs-who', '+' + (x.points_ar || x.points) + ' درجة'));
      ul.appendChild(li);
    }
    box.append(ul, el('div', 'rs-note', 'قدّرتها لجنةُ التوجيه الطلابيّ'));
    arabize(box);
  }

  // ⑥ ⑧ نماذج تنتظرك — لابنه المختار
  async function loadForms() {
    const { data, error } = await M.rpc('v2_guardian_forms', undefined, 'نماذج وليّ الأمر');
    if (error) { showLoadErr('تعذّر جلب النماذج: ' + errText(error)); ui.forms = []; }
    else ui.forms = data || [];
    renderForms();
  }

  function renderForms() {
    const box = $('forms');
    box.textContent = '';
    const k = ui.kid;
    const list = ui.forms.filter((f) => !k || f.student_ar === k.name);
    const waiting = list.filter((f) => f.needs_sign || f.needs_reply).length;
    $('formsTitle').textContent = 'نماذج تنتظرك' + (list.length ? ' — ' + ar(waiting) + ' تنتظر ردَّك من ' + ar(list.length) : '');
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لا نماذجَ وصلتك.')); return; }
    for (const f of list) box.appendChild(formCard(f));
    arabize(box);
  }

  function formCard(f) {
    const c = el('div', 'rs-file');
    const unread = !f.read_at && !ui.read.has(f.inbox_id);
    c.append(el('h5', null, (f.title_ar || 'نموذج ' + f.form_no) + ' — ' + (f.needs_sign ? 'ينتظر توقيعك' : f.needs_reply ? 'ينتظر ردَّك' : unread ? 'جديد' : 'للاطّلاع')),
      el('p', null, [f.delivered_h ? 'وصل ' + f.delivered_h : null, f.source].filter(Boolean).join(' · ')));
    const d = el('details', 'rs-dt');
    d.appendChild(el('summary', null, 'اقرأ النموذج'));
    const body = el('div', 'rs-dtb');
    const kv = Array.isArray(f.fields_kv) ? f.fields_kv : [];
    if (!kv.length) body.appendChild(el('div', 'notice err', 'لم تُرسل القاعدةُ نصَّ النموذج بعناوينه.'));
    for (const p of kv) {
      const row = el('div');
      row.append(el('b', null, (p.label || p.key || '') + ': '), document.createTextNode(p.value == null ? '—' : String(p.value)));
      body.appendChild(row);
    }
    const signed = Array.isArray(f.signed) ? f.signed : [];
    if (signed.length) body.appendChild(el('div', null, 'وقّع: ' + signed.join(' · ')));
    d.appendChild(body);
    d.addEventListener('toggle', () => { if (d.open) markRead(f); });
    c.appendChild(d);
    if (f.reply) c.appendChild(el('p', null, 'ردُّك: ' + f.reply));

    // التوقيع: «أقرّ» ضغطةٌ واحدة، والامتناعُ بسببٍ في لوح
    if (f.needs_sign) {
      const row = el('div', 'rs-row');
      row.append(btn('أقرّ', 'rs-btn', () => sign(f, true, null)), btn('امتنع بسبب', 'rs-btn ghost', () => refuse(f)));
      c.appendChild(row);
    }
    // الردّ: خياراتُه من القاعدة، وملاحظةٌ اختياريّةٌ يكتبها هو
    if (f.needs_reply) {
      const opts = Array.isArray(f.reply_options) ? f.reply_options : [];
      if (!opts.length) c.appendChild(el('div', 'notice err', 'لم تُرسل القاعدةُ خياراتِ الردّ.'));
      else {
        const l = el('label', null, 'ملاحظتُك (اختياريّة)');
        const note = el('textarea');
        note.rows = 2;
        note.id = 'rn_' + f.inbox_id;
        l.htmlFor = note.id;
        const row = el('div', 'rs-row');
        for (const o of opts) row.appendChild(btn(o, 'rs-btn', () => reply(f, o, note.value.trim() || null)));
        c.append(l, note, row);
      }
    }
    return c;
  }

  async function markRead(f) {
    if (f.read_at || ui.read.has(f.inbox_id)) return;
    ui.read.add(f.inbox_id);
    const { error } = await M.rpc('v2_guardian_form_read', { p_inbox: f.inbox_id }, 'وسم نموذج مقروءًا');
    if (error) { ui.read.delete(f.inbox_id); flash('bad', errText(error)); }
  }

  async function sign(f, signed, reason) {
    if (ui.busy) return null;
    ui.busy = true;
    if (signed) flash('wait', 'يُسجَّل إقرارُك…');
    const { error } = await M.rpc('v2_form_sign', { p_entry: f.entry_id, p_signer: SIGNER, p_signed: signed, p_refuse_reason: reason }, 'توقيع وليّ الأمر');
    ui.busy = false;
    if (error) { if (signed) flash('bad', errText(error)); return error; }
    flash('ok', signed ? 'سُجّل إقرارُك — ' + (f.title_ar || '') : 'سُجّل امتناعُك وسببُه — ' + (f.title_ar || ''));
    loadForms();
    return null;
  }

  function refuse(f) {
    V.form({
      title: 'الامتناعُ عن التوقيع', what: f.title_ar || '',
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الامتناع' }],
      ok: 'سجّل الامتناع',
      onOk: (v) => sign(f, false, v.why),
    });
  }

  async function reply(f, choice, note) {
    if (ui.busy) return;
    ui.busy = true;
    flash('wait', 'يُرسل ردُّك… ' + choice);
    const { error } = await M.rpc('v2_guardian_form_reply', { p_inbox: f.inbox_id, p_reply: choice, p_note: note }, 'ردّ وليّ الأمر');
    ui.busy = false;
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', 'أُرسل ردُّك: ' + choice);
    loadForms();
  }

  function renderOff() {
    const box = $('offCards');
    box.textContent = '';
    box.append(
      V.offCard('النصيحةُ التربويّة لابنك', 'v2_record_advice جاهزٌ ويُنادى هنا — لكنّ السجلَّ لا يحمل رقمَ الرصدة الذي يطلبه'));
  }

  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  (async () => {
    const { data: sess } = await M.sb.auth.getSession();
    if (!sess.session) { location.replace('./'); return; }
    const { data: g, error } = await M.rpc('v2_guardian_me', undefined, 'حساب وليّ الأمر');
    if (error) { M.gate('تعذّر جلب حسابك: ' + errText(error)); return; }
    if (!g) { M.gate('حسابك غير مربوطٍ بوليّ أمرٍ في مؤيّد.'); return; }
    ui.g = g;
    $('gWho').textContent = g.name || '';
    $('roleText').textContent = '';
    $('roleText').append('بوّابة ', el('b', null, g.name || ''), ' · وليّ أمر');
    $('gView').hidden = false;
    renderOff();
    const kids = g.children || [];
    if (!kids.length) { showLoadErr('لا ابنَ مربوطٌ بحسابك.'); return; }
    await loadForms();
    selectKid(kids[0].student_id);
  })();
})();
