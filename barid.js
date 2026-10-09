// مؤيّد · بريدُ المدرسة (تكليفُ الشاشات ③) — الصادرُ والوارد
// الصادر: v2_outgoing_pending · v2_outgoing_register · v2_outgoing_one · v2_outgoing_create · v2_outgoing_sign
//         v2_outgoing_send · v2_outgoing_reply · v2_outgoing_close · v2_outgoing_cancel · v2_outgoing_attach
//         v2_outgoing_edit · v2_outgoing_enums (القوائمُ بألفاظها من القاعدة)
// الوارد: v2_mail_inbox · v2_mail_card · v2_mail_my_tasks · v2_mail_register · v2_mail_direct · v2_mail_acknowledge · v2_mail_followup_close
// 🔑 الصادرُ ليس دفترَ أرقام بل بابٌ يُقفل ما أوجبه الدليل — فصدرُه البنودُ التي تنتظر خطابًا،
//    والفرقُ بين «يُقفل بالخروج» و«لا يُقفل إلّا بالجواب» يُعرض في القائمة والإنشاء والبطاقة.
// وكلُّ بابٍ كاتبٍ يرجع ببطاقة الخطاب كاملةً ومعها note_ar — فتُعرض كما رجعت ولا يُعاد النداء. ولا حذفَ في هذا الباب.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash, pick } = V;

  // القوائمُ بألفاظها من v2_outgoing_enums — لا تُنسخ في الشاشة، فإن زيدت قناةٌ عُرفت
  let KINDS = []; let SECRECY = []; let CHANNELS = []; let STATUS = [['', 'الكلّ']]; let REPLY_DAYS = null;
  async function loadEnums() {
    if (KINDS.length) return;
    const { data } = await M.rpc('v2_outgoing_enums', undefined, 'قوائم الصادر');
    const d = data || {};
    const pairs = (xs) => (xs || []).map((x) => [x.v, x.ar]);
    KINDS = pairs(d.kind); SECRECY = pairs(d.secrecy); CHANNELS = pairs(d.channel);
    STATUS = [['', 'الكلّ']].concat(pairs(d.status));
    REPLY_DAYS = d.reply_days_default == null ? null : d.reply_days_default;
  }
  const ATTACH = [['link', 'رابط'], ['barcode', 'باركود'], ['file', 'ملفّ (مرجعه)'], ['form', 'نموذج']];
  // السجلُّ يرجع الحالَ بمفتاحه بلا state_ar — فهذي ألفاظُ بطاقة الخطاب نفسِها (v2.outgoing_card) مختصرة
  const DAYS = [[30, '٣٠ يومًا'], [90, '٩٠ يومًا'], [365, 'سنة']];

  const ui = { tab: 'pend', pend: null, picked: new Set(), rStatus: '', rDays: 365, mine: [] };

  const TABS = [['pend', 'ما ينتظر الصادر'], ['reg', 'السجلّ'], ['in', 'الوارد']];
  function renderTabs() {
    pick($('tabs'), TABS, ui.tab, (v) => { ui.tab = v; show(); });
  }
  function show() {
    $('pendView').hidden = ui.tab !== 'pend';
    $('regView').hidden = ui.tab !== 'reg';
    $('inView').hidden = ui.tab !== 'in';
    if (ui.tab === 'pend') loadPending();
    if (ui.tab === 'reg') loadRegister();
    if (ui.tab === 'in') loadIncoming();
  }

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    await loadEnums();
    renderTabs();
    show();
  }

  // ---------- ① ما ينتظر الصادر ----------
  const sec = (title) => { const s = el('div'); s.appendChild(el('h4', 'rs-sub', title)); return s; };
  async function loadPending() {
    const { data, error } = await M.rpc('v2_outgoing_pending', { p_school: M.state.school }, 'ما ينتظر الصادر');
    const body = $('pBody');
    body.textContent = '';
    if (error) { $('pSum').textContent = ''; $('pNote').textContent = ''; body.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = ui.pend = data || {};
    $('pSum').textContent = d.summary_ar || '';
    $('pNote').textContent = d.note_ar || '';
    // بنودُ السلّم من السلوك والمواظبة معًا — وكلٌّ يُحمل على الخطاب برقمه (p_tasks)
    const tw = (d.tasks_without_letter || []).concat((d.absence_without_letter || []).map((x) => Object.assign({}, x, { owner: [x.owner, x.days != null ? 'غيابُه ' + x.days + (x.excused != null ? ' · بعذر ' + x.excused : '') : null].filter(Boolean).join(' · ') })));
    for (const k of [...ui.picked]) if (!tw.some((x) => x.task === k)) ui.picked.delete(k);
    // ١ · بنودُ السلّم التي تنتظر خطابًا — أبرزُها، ومنها يبدأ كلُّ شيء · واختيارٌ متعدّد: خطابٌ واحدٌ يحمل بنودًا
    if (tw.length) {
      const s = sec('بنودٌ أوجب الدليلُ رفعَها ولم تخرج بعد');
      s.appendChild(el('p', 'rs-meta', 'المس البندَ لتختاره — والخطابُ الواحدُ يحمل بنودًا عدّة'));
      const many = btn('', 'rs-btn pri', () => createForm([...ui.picked].map((id) => tw.find((x) => x.task === id)).filter(Boolean)));
      const sync = () => { many.textContent = 'اكتب خطابًا بالمختارة (' + ui.picked.size + ')'; many.hidden = ui.picked.size < 2; arabize(many); };
      for (const t of tw) {
        const f = el('div', 'rs-file rs-sel' + (ui.picked.has(t.task) ? ' on' : ''));
        f.setAttribute('role', 'button');
        f.tabIndex = 0;
        f.setAttribute('aria-pressed', String(ui.picked.has(t.task)));
        f.append(el('h5', null, t.text || ''), el('p', null, [t.student, t.owner].filter(Boolean).join(' · ')), el('div', 'rs-need', t.need_ar || ''));
        V.tap(f, (e) => {
          if (e && e.target && e.target.closest('button')) return;
          if (ui.picked.has(t.task)) ui.picked.delete(t.task); else ui.picked.add(t.task);
          f.classList.toggle('on', ui.picked.has(t.task)); f.setAttribute('aria-pressed', String(ui.picked.has(t.task)));
          sync();
        });
        const r = el('div', 'rs-row');
        r.appendChild(btn('اكتب خطابًا بها', 'rs-btn', () => { const sel = new Set(ui.picked); sel.add(t.task); createForm([...sel].map((id) => tw.find((x) => x.task === id)).filter(Boolean)); }));
        f.appendChild(r);
        s.appendChild(f);
      }
      s.appendChild(many);
      sync();
      body.appendChild(s);
    }
    // ٢ · المسوّدات
    if ((d.drafts || []).length) {
      const s = sec('مسوّداتٌ تنتظر التوقيع');
      for (const m of d.drafts) {
        const f = el('div', 'rs-file');
        f.append(el('h5', null, m.subject || ''), el('p', null, [m.to_entity, 'منذ ' + m.age_days + ' يومًا'].filter(Boolean).join(' · ')));
        const r = el('div', 'rs-row');
        r.append(btn('أكمِلها', 'rs-btn', () => openCard(m.mail)), btn('اعرضها للتوقيع', 'rs-btn', () => act('v2_outgoing_sign', { p_mail: m.mail }, 'توقيع الصادر')));
        f.appendChild(r);
        s.appendChild(f);
      }
      body.appendChild(s);
    }
    // ٣ · مُوقَّعٌ لم يخرج
    if ((d.signed_not_sent || []).length) {
      const s = sec('مُوقَّعٌ لم يخرج');
      for (const m of d.signed_not_sent) {
        const f = el('div', 'rs-file');
        f.append(el('h5', null, 'الصادر رقم ' + m.serial + ' · ' + (m.subject || '')), el('p', null, [m.to_entity, m.signed_ar, 'منذ ' + m.age_days + ' يومًا'].filter(Boolean).join(' · ')));
        const r = el('div', 'rs-row');
        r.appendChild(btn('أخرِجه', 'rs-btn', () => sendForm({ mail: m.mail, serial_ar: 'الصادر رقم ' + m.serial, subject: m.subject })));
        f.appendChild(r);
        s.appendChild(f);
      }
      body.appendChild(s);
    }
    // ٤ · خرج وينتظر جوابًا — والمتأخّرُ بالتحذيريّ لا بالأحمر
    if ((d.awaiting_reply || []).length) {
      const s = sec('خرج وينتظر جوابًا');
      for (const m of d.awaiting_reply) {
        const f = el('div', 'rs-file' + (m.late_days > 0 ? ' rs-late' : ''));
        f.append(el('h5', null, 'الصادر رقم ' + m.serial + ' · ' + (m.subject || '')), el('p', null, [m.to_entity, m.sent_on ? 'خرج ' + m.sent_on : null, m.due_on ? 'موعدُ المراجعة ' + m.due_on : null].filter(Boolean).join(' · ')));
        if (m.late_days > 0) f.appendChild(el('span', 'rs-state late', 'متأخّرٌ عن موعده: ' + m.late_days));
        const r = el('div', 'rs-row');
        r.append(btn('سجّل الجواب', 'rs-btn', () => replyForm({ mail: m.mail, serial_ar: 'الصادر رقم ' + m.serial, subject: m.subject })), btn('افتحه', 'rs-btn ghost', () => openCard(m.mail)));
        f.appendChild(r);
        s.appendChild(f);
      }
      body.appendChild(s);
    }
    arabize(body);
  }

  // ---------- ② إنشاءُ خطاب ----------
  // pre: { subject, reply_to: {mail, subject, from, serial} }
  function createForm(tasks, pre) {
    pre = pre || {};
    const tb = el('div');
    if (pre.reply_to) tb.appendChild(el('div', 'rs-info', 'ردٌّ على الوارد' + (pre.reply_to.serial ? ' رقم ' + pre.reply_to.serial : '') + ' — ' + (pre.reply_to.subject || '') + (pre.reply_to.from ? ' · من ' + pre.reply_to.from : '')));
    if (tasks && tasks.length) {
      const c = el('div', 'rs-file');
      c.appendChild(el('h5', null, 'البنودُ التي يحملها الخطاب'));
      // الخطابُ الواحدُ يُقفل بعضَها بخروجه وبعضَها لا يُقفل إلّا بجواب الجهة — وهذا ما يُسأل عنه أوّلَ مرّة
      if (ui.pend && ui.pend.note_ar) c.appendChild(el('p', 'rs-meta', ui.pend.note_ar));
      const ul = el('ul', 'rs-acts');
      for (const t of tasks) { const li = el('li'); const b = el('span'); b.append(el('span', null, t.text || ''), el('div', 'rs-need', t.need_ar || '')); li.append(el('i', 'rs-tick', '○'), b); ul.appendChild(li); }
      c.appendChild(ul);
      tb.appendChild(c);
    }
    V.form({
      title: pre.mail ? 'تعديلُ المسوّدة' : pre.reply_to ? 'ردٌّ على وارد' : 'إنشاءُ خطابٍ صادر',
      fields: [
        { key: 'h', type: 'node', node: tb },
        { key: 'subject', label: 'الموضوع', value: pre.subject || null },
        { key: 'to', label: 'الجهة', value: pre.to || null },
        { key: 'kind', type: 'pick', label: 'النوع', items: KINDS, value: pre.kind || (pre.reply_to ? 'reply' : (tasks && tasks.length ? 'report' : 'letter')) },
        { key: 'secrecy', type: 'pick', label: 'السرّيّة', items: SECRECY, value: pre.secrecy || 'عادي' },
        { key: 'body', type: 'textarea', label: 'النصّ', rows: 4, value: pre.body || null },
        { key: 'needs', type: 'pick', label: 'ينتظر جوابًا؟', items: [['yes', 'نعم'], ['no', 'لا']], value: pre.needs_reply ? 'yes' : 'no' },
        // مدّةُ متابعة الجواب لا أصلَ لها في اللوحة بعد — تُكتب باليد (ينتظر كلمةَ مفرح)
        { key: 'due', type: 'date', label: 'موعدُ المراجعة', value: pre.due || null, hint: REPLY_DAYS != null ? 'إن تُرك حُسب من أصل اللوحة: ' + REPLY_DAYS + ' أيّامِ عمل — ولك تعديلُه' : 'يُكتب إن كان ينتظر جوابًا' },
      ],
      ok: pre.mail ? 'احفظ التعديل' : 'أنشئ المسوّدة',
      onOk: async (v) => {
        // تعديلُ مسوّدةٍ قائمة (v2_outgoing_edit) — والبنودُ المحمولةُ عليها باقيةٌ كما هي
        if (pre.mail) {
          const { data, error } = await M.rpc('v2_outgoing_edit', {
            p_mail: pre.mail, p_subject: v.subject, p_to_entity: v.to, p_body: v.body, p_kind: v.kind || 'letter', p_secrecy: v.secrecy || 'عادي',
            p_needs_reply: v.needs === 'yes', p_reply_due: v.due,
          }, 'تعديل مسوّدة الصادر');
          if (error) return error;
          if (!data || data.ok !== true) return 'لم يُعدّلها الجسر';
          setTimeout(() => showCard(data, data.note_ar), 0);
          reloadView();
          return null;
        }
        const { data, error } = await M.rpc('v2_outgoing_create', {
          p_subject: v.subject, p_to_entity: v.to, p_body: v.body, p_kind: v.kind || 'letter', p_secrecy: v.secrecy || 'عادي',
          p_needs_reply: v.needs === 'yes', p_reply_due: v.due, p_reply_to_mail: pre.reply_to ? pre.reply_to.mail : null,
          p_ref_table: null, p_ref_id: null, p_tasks: tasks && tasks.length ? tasks.map((t) => t.task) : null,
        }, 'إنشاء خطاب صادر');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُنشئ الجسرُ المسوّدة';
        ui.picked.clear();
        setTimeout(() => showCard(data, data.note_ar), 0); // بعد أن يُطوى اللوحُ الحاليّ
        reloadView();
        return null;
      },
    });
  }

  // ---------- ③ بطاقةُ الخطاب ----------
  async function openCard(mail) {
    const { data, error } = await M.rpc('v2_outgoing_one', { p_mail: mail }, 'بطاقة الصادر');
    if (error) { flash('bad', errText(error)); return; }
    showCard(data, null);
  }
  function cardNode(c, note) {
    const n = el('div');
    if (note) n.appendChild(el('div', 'rs-done-note', note));
    if (c.reply_to) n.appendChild(el('div', 'rs-info', 'ردٌّ على الوارد' + (c.reply_to.serial ? ' رقم ' + c.reply_to.serial : '') + ' — ' + (c.reply_to.subject || '') + (c.reply_to.from ? ' · من ' + c.reply_to.from : '')));
    n.appendChild(el('p', 'rs-sum', c.serial_ar || ''));
    n.appendChild(el('span', 'rs-state ' + (c.status === 'closed' ? 'done' : c.status === 'cancelled' ? 'void' : 'open'), c.state_ar || ''));
    if (c.overdue_ar) n.appendChild(el('span', 'rs-state late', c.overdue_ar));
    const lg = el('div', 'rs-lgd');
    for (const [k, v] of [['الموضوع', c.subject], ['الجهة', c.to_entity], ['النوع', c.kind_ar], ['السرّيّة', c.secrecy], ['التاريخ', c.issued_ar], ['أعدّه', c.prepared_by], ['وقّعه', c.signed_by],
      ['خرج', [c.sent_on, c.sent_channel, c.sent_ref].filter(Boolean).join(' · ')], ['موعدُ المراجعة', c.reply_due_ar || c.reply_due_on], ['الجواب', [c.reply_on, c.reply_ref, c.reply_note].filter(Boolean).join(' · ')], ['الإقفال', c.close_note]]) {
      if (v) lg.append(el('i', 'k', k + ':'), el('i', null, String(v)));
    }
    n.appendChild(lg);
    if (c.body) n.appendChild(el('p', 'rs-msg', c.body));
    const allTasks = (c.tasks || []).concat(c.absence_tasks || []);
    if (allTasks.length) {
      n.appendChild(el('div', 'rs-label', 'البنودُ التي يحملها'));
      const ul = el('ul', 'rs-acts');
      for (const t of allTasks) {
        const li = el('li');
        const b = el('span');
        b.append(el('span', null, t.text || ''), el('div', 'rs-need', t.closes_on_ar || ''));
        if (t.student) b.appendChild(el('div', 'rs-meta', t.student));
        li.append(el('i', 'rs-tick' + (t.status === 'done' ? ' ok' : ''), t.status === 'done' ? '✓' : '○'), b);
        ul.appendChild(li);
      }
      n.appendChild(ul);
    }
    if ((c.attachments || []).length) {
      n.appendChild(el('div', 'rs-label', 'المرفقات'));
      for (const a of c.attachments) {
        const p = el('p');
        if (a.url) { const l = el('a', null, a.name || a.url); l.href = a.url; l.target = '_blank'; l.rel = 'noopener'; p.appendChild(l); }
        else p.textContent = [a.name, a.barcode, a.form_entry ? 'نموذجٌ مرفق' : null].filter(Boolean).join(' · ');
        n.appendChild(p);
      }
    }
    return n;
  }
  // الأفعالُ بحال الخطاب كما في التكليف: الممكنُ وحدَه يظهر، ولا يُعطَّل شيء — والذي لا يُرجَع في آخر الشريط
  function showCard(c, note) {
    if (!c) return;
    const extra = [];
    let ok = false; let onOk = null;
    const st = c.status;
    const attach = { text: 'أرفِق', cls: 'rs-btn', onClick: () => { setTimeout(() => attachForm(c), 0); return null; } };
    const cancel = { text: 'ألغِ', cls: 'rs-btn irrev', onClick: () => { setTimeout(() => cancelForm(c), 0); return null; } };
    const edit = { text: 'عدّل', cls: 'rs-btn', onClick: () => { setTimeout(() => createForm([], { mail: c.mail, subject: c.subject, to: c.to_entity, body: c.body, kind: c.kind, secrecy: c.secrecy, needs_reply: c.needs_reply, due: c.reply_due_on }), 0); return null; } };
    if (st === 'draft') { ok = 'اعرضه للتوقيع'; onOk = () => act('v2_outgoing_sign', { p_mail: c.mail }, 'توقيع الصادر', true); extra.push(attach, edit, cancel); }
    else if (st === 'signed') { ok = 'أخرِجه'; onOk = () => { setTimeout(() => sendForm(c), 0); return null; }; extra.push(attach, cancel); }
    else if (st === 'sent') {
      if (c.needs_reply) { ok = 'سجّل الجواب'; onOk = () => { setTimeout(() => replyForm(c), 0); return null; }; }
      else { ok = 'أقفِله'; onOk = () => { setTimeout(() => closeForm(c), 0); return null; }; }
      extra.push(attach);
    } else if (st === 'replied') { ok = 'أقفِله'; onOk = () => { setTimeout(() => closeForm(c), 0); return null; }; extra.push(attach); }
    V.form({ title: c.subject || c.serial_ar || '', fields: [{ key: 'c', type: 'node', node: cardNode(c, note) }], ok, onOk, extra, cancel: 'إغلاق' });
  }

  // فعلٌ بلا حقول (التوقيع): يرجع ببطاقته و note_ar فتُعرض كما رجعت
  async function act(fn, args, what, inForm) {
    const { data, error } = await M.rpc(fn, args, what);
    if (error) { if (inForm) return error; flash('bad', errText(error)); return null; }
    if (!data || data.ok !== true) return inForm ? 'لم يُتمّ الجسرُ الفعل' : null;
    setTimeout(() => showCard(data, data.note_ar), 0);
    reloadView();
    return null;
  }

  // ---------- ④ الإخراج: القناةُ والمرجعُ وتاريخُ اليوم ثابتًا ----------
  function sendForm(c) {
    V.form({
      title: 'إخراجُ ' + (c.serial_ar || 'الخطاب'), what: c.subject || '',
      fields: [
        { key: 'ch', type: 'pick', label: 'القناة', items: CHANNELS },
        { key: 'ref', label: 'المرجع — مطلوبٌ إن خرج في «نظام رسمي»' },
        { key: 'on', type: 'node', node: el('p', 'rs-meta', 'تاريخُ الإخراج: اليوم ' + M.state.date) },
      ],
      ok: 'أخرِجه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_outgoing_send', { p_mail: c.mail, p_channel: v.ch || null, p_ref: v.ref }, 'إخراج الصادر');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُخرجه الجسر';
        setTimeout(() => showCard(data, data.note_ar), 0); // ما أُقفل وما بقي ينتظر جوابًا — كاملًا، بعد أن يُطوى اللوحُ الحاليّ
        reloadView();
        return null;
      },
    });
  }

  // ---------- ⑤ تسجيلُ الجواب ----------
  function replyForm(c) {
    V.form({
      title: 'جوابُ ' + (c.to_entity || 'الجهة') + ' على ' + (c.serial_ar || 'الخطاب'), what: c.subject || '',
      fields: [
        { key: 'ref', label: 'مرجعُ الجواب' },
        { key: 'note', type: 'textarea', label: 'خلاصتُه', rows: 3, hint: 'واحدٌ منهما على الأقلّ' },
        { key: 'on', type: 'date', label: 'تاريخُ الجواب', value: M.state.date },
      ],
      ok: 'سجّل الجواب',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_outgoing_reply', { p_mail: c.mail, p_on: v.on, p_ref: v.ref, p_note: v.note }, 'تسجيل جواب الجهة');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُسجّله الجسر';
        setTimeout(() => showCard(data, data.note_ar), 0); // بعد أن يُطوى اللوحُ الحاليّ
        reloadView();
        return null;
      },
    });
  }

  function closeForm(c) {
    V.form({
      title: 'إقفالُ ' + (c.serial_ar || 'الخطاب'), what: c.subject || '',
      fields: [{ key: 'note', type: 'textarea', label: 'ملاحظةُ الإقفال (اختياريّة)', rows: 2 }],
      ok: 'أقفِله',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_outgoing_close', { p_mail: c.mail, p_note: v.note }, 'إقفال الصادر');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُقفله الجسر';
        setTimeout(() => showCard(data, data.note_ar), 0); // بعد أن يُطوى اللوحُ الحاليّ
        reloadView();
        return null;
      },
    });
  }

  function attachForm(c) {
    V.form({
      title: 'إرفاقٌ على ' + (c.serial_ar || 'الخطاب'), what: c.subject || '',
      fields: [
        { key: 'kind', type: 'pick', label: 'النوع', items: ATTACH, value: 'link' },
        { key: 'name', label: 'الاسم' },
        { key: 'url', label: 'الرابط', show: (v) => v.kind === 'link' },
        { key: 'ref', label: 'مرجعُ الملفّ', show: (v) => v.kind === 'file' },
        { key: 'barcode', label: 'الباركود', show: (v) => v.kind === 'barcode' },
        { key: 'entry', label: 'رقمُ قيد النموذج', show: (v) => v.kind === 'form' },
      ],
      ok: 'أرفِقه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_outgoing_attach', {
          p_mail: c.mail, p_kind: v.kind || 'file', p_name: v.name, p_url: v.kind === 'link' ? v.url : null,
          p_file_ref: v.kind === 'file' ? v.ref : null, p_barcode: v.kind === 'barcode' ? v.barcode : null, p_form_entry: v.kind === 'form' ? v.entry : null,
        }, 'إرفاق على الصادر');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُرفقه الجسر';
        setTimeout(() => showCard(data, data.note_ar || null), 0);
        return null;
      },
    });
  }

  // ---------- ⑦ الإلغاء: السببُ بيد المستعمل · وما خرج لا يُلغى بل يُستدرك ----------
  function cancelForm(c) {
    V.form({
      title: 'إلغاءُ ' + (c.serial_ar || 'الخطاب'), what: c.subject || '',
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الإلغاء *', rows: 3, hint: 'يبقى في السجلّ باسمك — ولا يُحذف الخطاب' }],
      ok: 'ألغِ',
      okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_outgoing_cancel', { p_mail: c.mail, p_why: v.why }, 'إلغاء صادر');
        if (error) {
          if (/يُستدرك/.test(String(error.message || ''))) {
            return { text: errText(error), acts: [btn('اكتب خطابَ استدراك', 'rs-btn', () => {
              const m = document.querySelector('.rs-modal:not([hidden])'); if (m) m.hidden = true;
              setTimeout(() => createForm([], { subject: 'استدراكٌ على ' + (c.serial_ar || 'الصادر') + ' — ', to: c.to_entity }), 0);
            })] };
          }
          return error;
        }
        if (!data || data.ok !== true) return 'لم يُلغه الجسر';
        setTimeout(() => showCard(data, data.note_ar), 0); // بعد أن يُطوى اللوحُ الحاليّ
        reloadView();
        return null;
      },
    });
  }

  function reloadView() {
    if (ui.tab === 'pend') loadPending();
    if (ui.tab === 'reg') loadRegister();
  }

  // ---------- ⑥ السجلّ ----------
  async function loadRegister() {
    pick($('rStatus'), STATUS, ui.rStatus, (v) => { ui.rStatus = v; loadRegister(); });
    pick($('rDays'), DAYS, ui.rDays, (v) => { ui.rDays = v; loadRegister(); });
    const { data, error } = await M.rpc('v2_outgoing_register', { p_school: M.state.school, p_days: ui.rDays, p_status: ui.rStatus || null }, 'سجلّ الصادر');
    const box = $('rBody');
    box.textContent = '';
    if (error) { $('rSum').textContent = ''; $('rNote').textContent = ''; box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    $('rSum').textContent = d.summary_ar || '';
    $('rNote').textContent = d.note_ar || '';
    const rows = d.rows || [];
    if (!rows.length) return;
    const w = el('div', 'rs-tablewrap');
    const tb = el('table', 'rs-table');
    const hr = el('tr');
    for (const h of ['الرقم', 'الموضوع', 'الجهة', 'الحال', 'التاريخ', '']) hr.appendChild(el('th', null, h));
    const th = el('thead'); th.appendChild(hr); tb.appendChild(th);
    const body = el('tbody');
    for (const r of rows) {
      const tr = el('tr');
      const td = (...n) => { const c = el('td'); c.append(...n); tr.appendChild(c); return c; };
      td(document.createTextNode(r.serial_ar || ''));
      td(document.createTextNode(r.subject || ''));
      td(document.createTextNode(r.to_entity || ''));
      const st = td(el('span', 'rs-state ' + (r.status === 'closed' ? 'done' : r.status === 'cancelled' ? 'void' : 'open'), r.state_ar || r.status));
      if (r.overdue_days) st.appendChild(el('span', 'rs-state late', 'متأخّرٌ عن موعده: ' + r.overdue_days));
      td(document.createTextNode(r.issued_ar || ''));
      td(btn('افتحه', 'rs-btn', () => openCard(r.mail)));
      body.appendChild(tr);
    }
    tb.appendChild(body);
    w.appendChild(tb);
    box.appendChild(w);
    arabize(box);
  }

  // ---------- ⑧ الوارد ----------
  async function loadIncoming() {
    const [inb, mine] = await Promise.all([
      M.rpc('v2_mail_inbox', { p_school: M.state.school, p_status: null, p_days: 90 }, 'سجلّ الوارد'),
      M.rpc('v2_mail_my_tasks', { p_school: M.state.school }, 'ما عليّ من الوارد'),
    ]);
    ui.mine = mine.data || [];
    const mb = $('iMine');
    mb.textContent = '';
    if (mine.error) mb.appendChild(el('div', 'notice err', errText(mine.error)));
    else if (!ui.mine.length) mb.appendChild(el('p', 'rs-meta', 'لا بندَ واردٍ موجَّهٌ إليك.'));
    for (const x of ui.mine) {
      const f = el('div', 'rs-file' + (x.is_late ? ' rs-late' : ''));
      f.append(el('h5', null, 'وارد ' + (x.serial_no || '') + ' · ' + (x.subject_ar || '')), el('p', null, x.text_ar || ''), el('p', 'rs-meta', [x.due_h, x.is_late ? 'متأخّر' : null].filter(Boolean).join(' · ')));
      const r = el('div', 'rs-row');
      r.appendChild(btn('أتممتُه', 'rs-btn', () => followupForm(x)));
      f.appendChild(r);
      mb.appendChild(f);
    }
    arabize(mb);
    const box = $('iBody');
    box.textContent = '';
    const reg = el('div', 'rs-row');
    reg.appendChild(btn('سجّل واردًا', 'rs-btn', registerForm));
    box.appendChild(reg);
    if (inb.error) { box.appendChild(el('div', 'notice err', errText(inb.error))); return; }
    const rows = inb.data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', 'لا واردَ في التسعين يومًا الماضية.')); return; }
    const w = el('div', 'rs-tablewrap');
    const tb = el('table', 'rs-table');
    const hr = el('tr');
    for (const h of ['الرقم', 'الموضوع', 'من', 'ورد', 'الحال', 'البنود', '']) hr.appendChild(el('th', null, h));
    const th = el('thead'); th.appendChild(hr); tb.appendChild(th);
    const body = el('tbody');
    for (const m of rows) {
      const tr = el('tr');
      const td = (...n) => { const c = el('td'); c.append(...n); tr.appendChild(c); return c; };
      td(document.createTextNode([m.serial_no, m.ref_no].filter(Boolean).join(' · ')));
      td(document.createTextNode(m.subject_ar || ''));
      td(document.createTextNode(m.from_entity || ''));
      td(document.createTextNode(m.received_h || ''));
      td(document.createTextNode(m.status_ar || ''));
      const it = td(document.createTextNode(m.items_n + ' · مفتوح ' + m.open_items));
      if (m.late_items > 0) it.appendChild(el('span', 'rs-state late', 'متأخّر ' + m.late_items));
      td(btn('افتحه', 'rs-btn', () => openIncoming(m.mail_id)));
      body.appendChild(tr);
    }
    tb.appendChild(body);
    w.appendChild(tb);
    box.appendChild(w);
    arabize(box);
  }

  // بطاقةُ الوارد: ولكلّ موجَّهٍ إليه متابعتُه — فلا تُعرض في البطاقة إلّا متابعاتُك (من v2_mail_my_tasks)
  async function openIncoming(id) {
    const { data, error } = await M.rpc('v2_mail_card', { p_mail: id }, 'بطاقة الوارد');
    if (error) { flash('bad', errText(error)); return; }
    const c = data || {};
    const m = c.mail || {};
    const n = el('div');
    const lg = el('div', 'rs-lgd');
    for (const [k, v] of [['الرقم', [m.serial_no, m.ref_no].filter(Boolean).join(' · ')], ['من', m.from], ['ورد', m.received_h], ['تاريخُه', m.doc_date_h], ['السرّيّة', m.secrecy]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, String(v)));
    n.appendChild(lg);
    if (m.body) n.appendChild(el('p', 'rs-msg', m.body));
    for (const a of c.attachments || []) n.appendChild(el('p', 'rs-meta', '📎 ' + (a.name || '')));
    for (const i of c.items || []) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (i.ord ? i.ord + ' · ' : '') + (i.text || '')), el('p', 'rs-meta', [i.starts_h, i.ends_h].filter(Boolean).join(' — ')));
      // ولكلّ موجَّهٍ إليه متابعتُه — mine كما يرجع من الجسر
      for (const fu of (i.followups || []).filter((x) => x.mine === true)) {
        f.appendChild(el('p', null, 'متابعتُك' + (fu.due_h ? ' · حتى ' + fu.due_h : '') + (fu.late ? ' · متأخّرة' : '')));
        const r = el('div', 'rs-row');
        r.appendChild(btn('أتممتُه', 'rs-btn', () => { const x = ui.mine.find((y) => y.followup_id === fu.id); const mm = document.querySelector('.rs-modal:not([hidden])'); if (mm) mm.hidden = true; setTimeout(() => followupForm(x || { followup_id: fu.id, text_ar: i.text }), 0); }));
        f.appendChild(r);
      }
      n.appendChild(f);
    }
    // توجيهُ الوارد ببنودٍ إلى أشخاص (v2_mail_direct) — ومن ليس له يردّه الجسر
    const dirBtn = el('div', 'rs-row');
    dirBtn.appendChild(btn('وجّهه ببند', 'rs-btn', () => { const mm = document.querySelector('.rs-modal:not([hidden])'); if (mm) mm.hidden = true; setTimeout(() => directForm(m), 0); }));
    // الإقرارُ بالاطّلاع: «أقرُّ» و«أمتنع» متساويان بحدّ — والامتناعُ بسببٍ مكتوب
    V.form({
      title: m.subject || 'وارد',
      fields: [{ key: 'c', type: 'node', node: n }, { key: 'dir', type: 'node', node: dirBtn },
        { key: 'att', label: 'المرفق — يلزم التوقيعَ' }, { key: 'refuse', type: 'textarea', label: 'سببُ الامتناع — إن امتنعت', rows: 2 }],
      ok: 'أقرُّ بالاطّلاع',
      pair: true,
      pairNote: 'التوقيعُ يلزمه مرفق · والامتناعُ بسببٍ مكتوبٍ يُتمّ الخطوة',
      onOk: async (v) => {
        const { data: r, error: e } = await M.rpc('v2_mail_acknowledge', { p_mail: m.id, p_signed: true, p_refuse_reason: null, p_attachment_name: v.att }, 'الإقرار بالاطّلاع');
        if (e) return e;
        if (!r || r.ok !== true) return 'لم يُثبته الجسر';
        flash('ok', r.note_ar || '');
        return null;
      },
      extra: [{ text: 'أمتنع', cls: 'rs-btn', onClick: async (v) => {
        const { data: r, error: e } = await M.rpc('v2_mail_acknowledge', { p_mail: m.id, p_signed: false, p_refuse_reason: v.refuse, p_attachment_name: null }, 'الامتناع عن الإقرار');
        if (e) return e;
        if (!r || r.ok !== true) return 'لم يُثبته الجسر';
        flash('ok', r.note_ar || '');
        return null;
      } }],
    });
  }

  // تسجيلُ وارد (v2_mail_register) — ثمّ توجيهُه
  function registerForm() {
    V.form({
      title: 'تسجيلُ وارد',
      fields: [
        { key: 'from', label: 'الجهةُ الواردُ منها' },
        { key: 'subject', label: 'الموضوع' },
        { key: 'body', type: 'textarea', label: 'النصّ', rows: 3 },
        { key: 'ref', label: 'رقمُه عند الجهة' },
        { key: 'recv', type: 'date', label: 'تاريخُ الورود', value: M.state.date },
        { key: 'doc', type: 'date', label: 'تاريخُ الخطاب' },
        { key: 'secrecy', type: 'pick', label: 'السرّيّة', items: SECRECY, value: 'عادي' },
        { key: 'source', label: 'المصدر' },
      ],
      ok: 'سجّله',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_mail_register', { p_from_entity: v.from, p_subject: v.subject, p_body: v.body, p_ref_no: v.ref, p_received_on: v.recv, p_doc_date: v.doc, p_secrecy: v.secrecy || 'عادي', p_source: v.source }, 'تسجيل وارد');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُسجّله الجسر';
        flash('ok', data.note_ar || '');
        loadIncoming();
        return null;
      },
    });
  }

  let staffCache = null;
  async function directForm(m) {
    if (!staffCache) {
      const { data } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
      staffCache = (data || []).map((p) => [p.person_id, p.name_ar, p.post_ar || '']);
    }
    V.form({
      title: 'توجيهُ الوارد', what: m.subject || '',
      fields: [
        { key: 'text', type: 'textarea', label: 'نصُّ البند', rows: 2 },
        { key: 'kind', type: 'pick', label: 'نوعُه', items: [['تكليف', 'تكليف'], ['إبلاغ بالعلم', 'إبلاغ بالعلم']], value: 'تكليف' },
        { key: 'person', type: 'choose', label: 'إلى', items: staffCache },
        { key: 'due', type: 'date', label: 'حتى (اختياريّ)' },
      ],
      ok: 'وجّهه',
      onOk: async (v) => {
        const items = [{ text: v.text, kind: v.kind, targets: [{ kind: 'person', person: v.person, due_on: v.due }] }];
        const { data, error } = await M.rpc('v2_mail_direct', { p_mail: m.id, p_items: items }, 'توجيه الوارد');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُوجّهه الجسر';
        flash('ok', data.note_ar || '');
        loadIncoming();
        return null;
      },
    });
  }

  function followupForm(x) {
    V.form({
      title: 'إتمامُ بند وارد', what: x.text_ar || '',
      fields: [{ key: 'note', type: 'textarea', label: 'ما تمّ', rows: 3 }, { key: 'ev', label: 'الشاهد (اختياريّ)' }],
      ok: 'أتممتُه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_mail_followup_close', { p_followup: x.followup_id, p_note: v.note, p_evidence: v.ev }, 'إقفال متابعة الوارد');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُقفلها الجسر';
        flash('ok', data.note_ar || '');
        loadIncoming();
        return null;
      },
    });
  }

  M.start({ screen: 'barid', onChange: () => refresh() });
})();
