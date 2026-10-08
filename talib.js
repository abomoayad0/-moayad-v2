// مؤيّد · صفحة الطالب — viewS في المحاكي: درجةُ سلوكي · فرصٌ سجّلتُ فيها · الفرصُ المتاحة · شواهدي · رصداتي.
// v2_opps_open_for(p_student) ⇒ score · purpose · open · mine · v2_opp_join · v2_student_timeline(p_student, 'student')
// 🔴 حساباتُ الطلاب مغلقة، ولا جسرَ في القاعدة يعرّف الطالبَ بحسابه — فلا تُفتح الصفحةُ لطالبٍ حتى يُبنى.
//    وتُفتح معاينةً للمنسوب الذي يملك student_card بـ ?student=… — للقراءة وحدها، وأفعالُها معطّلة.
//    (v2_entry_file · ونموذجُ المشاركة يُرفع إلى upload_to من mine)
// ولا بنكَ عباراتٍ هنا — كلامُ الطالب شهادةٌ لا تُملى عليه. ولا اسمَ زميلٍ ولا درجتَه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText } = M;
  const { arabize, btn, flash } = V;

  const ui = { sid: null, preview: true, data: null };

  async function load() {
    const [o, tl, sc] = await Promise.all([
      M.rpc('v2_opps_open_for', { p_student: ui.sid }, 'درجة السلوك والفرص'),
      M.rpc('v2_student_timeline', { p_student: ui.sid, p_as: 'student' }, 'سجلّي'),
      M.rpc('v2_my_score', { p_student: ui.sid, p_term: null }, 'درجة سلوكي'),
    ]);
    ui.data = o.error ? null : (o.data || {});
    // ① درجةُ سلوكي من v2_my_score كما ترجع
    V.scoreBox($('score'), sc);
    if (!o.error && ui.data.purpose) $('score').appendChild(el('div', 'rs-note', ui.data.purpose));
    renderMine(o.error);
    renderOpen(o.error);
    renderEvid(o.error);
    renderRecs(tl);
  }

  const errBox = (box, e) => { box.textContent = ''; box.appendChild(el('div', 'notice err', errText(e))); };

  // ④ ما سجّلتُ فيه — وحالُ كلٍّ كما في القاعدة
  function renderMine(e) {
    const box = $('mine');
    if (e) { errBox(box, e); return; }
    box.textContent = '';
    const mine = ui.data.mine || [];
    if (!mine.length) { box.appendChild(el('p', 'rs-meta', 'لم تسجّل في فرصةٍ بعد.')); return; }
    for (const x of mine) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, x.merit || ''), el('p', null, [x.when, x.state, x.close_why].filter(Boolean).join(' · ')));
      let st;
      if (x.state === 'مفتوحة') st = 'مسجَّلٌ · الفرصةُ مفتوحة — تُقفل باكتمال العدد أو انتهاء الوقت';
      else if (!x.filed) st = 'أُغلقت — املأ نموذجَك وأرفق شاهدَك، ثمّ يقرّ من أقامها';
      else if (!x.verdict) st = 'رُفع نموذجُك — بانتظار الإقرار';
      else if (!x.graded) st = x.verdict + (x.note ? ' — ' + x.note : '') + ' · بانتظار تقدير اللجنة';
      else st = 'تمّ — قدّرت لك اللجنةُ ' + (x.points_ar || x.points) + ' درجة';
      f.appendChild(el('div', 'rs-note', st));
      // نموذجُ المشاركة يُرفع إلى upload_to كما ترجعه القاعدة — ولا يُبنى المسارُ هنا
      if (x.state !== 'مفتوحة' && !x.filed) {
        if (!x.upload_to) f.appendChild(el('div', 'notice err', 'لم ترجع القاعدةُ مسارَ الرفع (upload_to).'));
        else {
          const b = btn('املأ نموذجَك', 'rs-btn', () => fileMine(x));
          if (ui.preview) { b.disabled = true; b.title = 'معاينة — النموذجُ للطالب من حسابه'; }
          f.appendChild(b);
        }
      }
      box.appendChild(f);
    }
    arabize(box);
  }

  // ⑤ المتاحُ الآن — ولا اسمَ زميلٍ فيه، والعددُ من القاعدة
  function renderOpen(e) {
    const box = $('open');
    if (e) { errBox(box, e); return; }
    box.textContent = '';
    const list = (ui.data.open || []).filter((o) => !o.joined);
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لا فرصَ مفتوحةً الآن — تابع صفحتك.')); return; }
    for (const o of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (o.merit || '') + (o.points_note ? ' — ' + o.points_note : '')),
        el('p', null, [o.when, o.capacity ? 'سُجّل ' + o.taken + ' من ' + o.capacity : 'سُجّل ' + o.taken, o.group, o.source].filter(Boolean).join(' · ')));
      const b = btn('سجّل فيها', 'rs-btn', () => join(o, b));
      if (ui.preview) { b.disabled = true; b.title = 'معاينة — التسجيلُ للطالب من حسابه'; }
      f.appendChild(b);
      box.appendChild(f);
    }
    arabize(box);
  }

  async function join(o, b) {
    if (ui.preview) return;
    b.disabled = true;
    flash('wait', 'يُسجَّل… ' + (o.merit || ''));
    const { data, error } = await M.rpc('v2_opp_join', { p_opp: o.opp, p_student: ui.sid }, 'التسجيل في فرصة');
    b.disabled = false;
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', 'سُجّلتَ في: ' + (o.merit || '') + (data && data.capacity ? ' · ' + data.taken + ' من ' + data.capacity : ''));
    load();
  }

  // نموذجُ المشاركة: كلامُ الطالب بلسانه — لا بنكَ عبارات — والملفُّ إلى upload_to ثمّ v2_entry_file
  function fileMine(x) {
    if (ui.preview) return;
    V.form({
      title: 'نموذجُ مشاركتي', what: x.merit || '',
      fields: [
        { key: 'what', type: 'textarea', label: 'ماذا فعلتَ بالتحديد' },
        { key: 'file', type: 'file', label: 'الشاهدُ المرفق — ملفٌّ فعليّ' },
        { key: 'desc', label: 'وصفُ المرفق' },
      ],
      ok: 'ارفع النموذج',
      onOk: async (v) => {
        if (!v.file) return 'اختر ملفَّ الشاهد.';
        const path = x.upload_to + Date.now() + '-' + v.file.name.replace(/[^\w.-]+/g, '_');
        const up = await M.sb.storage.from('v2-attachments').upload(path, v.file, { upsert: false });
        if (up.error) {
          M.logError({ message: up.error.message, fn: 'storage.upload', action: 'رفع الشاهد', params: { path } });
          return up.error;
        }
        const { data, error } = await M.rpc('v2_entry_file', { p_entry: x.entry, p_what: v.what, p_evidence_path: path, p_evidence_desc: v.desc }, 'نموذج المشاركة');
        if (error) return error;
        flash('ok', 'رُفع نموذجُك' + (data && data.by ? ' — ' + data.by : '') + ' · ثمّ يقرّ من أقام الفرصة');
        load();
        return null;
      },
    });
  }

  // ⑦ شواهدي — ما رفعتُه وحالُه
  function renderEvid(e) {
    const box = $('evid');
    if (e) { errBox(box, e); return; }
    box.textContent = '';
    const filed = (ui.data.mine || []).filter((x) => x.filed);
    if (!filed.length) { box.appendChild(el('p', 'rs-meta', 'لم ترفع شاهدًا بعد.')); return; }
    const ul = el('ul', 'rs-acts');
    for (const x of filed) {
      const li = el('li');
      const body = el('span');
      body.style.flex = '1';
      body.appendChild(el('span', null, x.merit || ''));
      if (x.what) body.appendChild(el('div', 'rs-meta', x.what + (x.evidence ? ' · ' + x.evidence : '')));
      li.append(el('i', 'rs-tick' + (x.graded ? ' ok' : ''), x.graded ? '✓' : '○'), body,
        el('small', 'rs-who', x.graded ? 'قُدّرت ' + (x.points_ar || x.points) + ' درجة' : x.verdict ? 'عند اللجنة' : 'بانتظار الإقرار'));
      ul.appendChild(li);
    }
    box.appendChild(ul);
    arabize(box);
  }

  // رصداتي — من السجلّ بصفة الطالب
  function renderRecs(r) {
    const box = $('recs');
    if (r.error) { errBox(box, r.error); return; }
    box.textContent = '';
    const evs = ((r.data && r.data.events) || []).filter((e) => e.kind === 'behavior_record');
    if (!evs.length) { box.appendChild(el('p', 'rs-meta', 'لا رصداتِ عليك.')); return; }
    const ul = el('ul', 'rs-acts');
    for (const e of evs) {
      const li = el('li');
      const body = el('span');
      body.style.flex = '1';
      body.appendChild(el('span', null, e.title || ''));
      if (e.body) body.appendChild(el('div', 'rs-meta', e.body));
      // نصيحتُك من الرصدة نفسِها — advice مع الحدث، أو v2_record_advice برقمها
      body.appendChild(V.recordAdvice(e, 'نصيحةٌ لك'));
      li.append(el('i', 'rs-tick ok', '✓'), body, el('small', 'rs-who', e.on || ''));
      ul.appendChild(li);
    }
    box.appendChild(ul);
    arabize(box);
  }

  function renderOff() {
    const box = $('offCards');
    box.textContent = '';
    box.append(V.offCard('بانتظار توقيعك', 'سجلُّ المشكلات السلوكيّة — نموذج ٥ · ص٦٢'),
      V.offCard('اقترحها الموجّهُ لك', 'والاختيارُ لك — فالتعويضُ حقٌّ لا تكليف'),
      V.offCard('ممارسةٌ فرديّة', 'تفعلها وحدَك وتقدّم شاهدَها'));
  }

  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  (async () => {
    const { data: sess } = await M.sb.auth.getSession();
    if (!sess.session) { location.replace('./'); return; }
    let me;
    try { await M.defaultRole(); me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    const sid = new URLSearchParams(location.search).get('student');
    if (!me) {
      const { data: g } = await M.rpc('v2_guardian_me', undefined, 'حساب وليّ الأمر');
      if (g) { location.replace('walee.html'); return; }
      // الطالبُ بحسابه: لا جسرَ يرجع رقمَه بعد — فتُفتح صفحتُه برابطٍ فيه رقمُه (?student=)، والقاعدةُ تتحقّق أنّه هو
      if (!sid) { M.gate('صفحتُك تُفتح برابطها — ولا جسرَ في القاعدة يعرّف الطالبَ بحسابه بعد.'); return; }
      const chk = await M.rpc('v2_my_score', { p_student: sid, p_term: null }, 'درجة سلوكي');
      if (chk.error) { M.gate(errText(chk.error)); return; }
      ui.sid = sid;
      ui.preview = false;
      $('roleText').textContent = 'صفحتي';
      $('sView').hidden = false;
      renderOff();
      await load();
      return;
    }
    // منسوبٌ: معاينةٌ للقراءة وحدها، بطالبٍ يُسمّى في الرابط
    if (!(me.can && me.can.student_card) || !sid) { M.gate('صفحةُ الطالب للطالب. وللمنسوب معاينتُها من رابطٍ فيه الطالب (?student=).'); return; }
    ui.sid = sid;
    ui.preview = true;
    $('who').textContent = me.role_ar || '';
    const card = await M.rpc('v2_student_card', { p_student: sid }, 'بطاقة الطالب');
    const st = (card.data && card.data.student) || {};
    $('roleText').textContent = '';
    $('roleText').append('صفحة ', el('b', null, st.name || st.full_name || '—'));
    $('previewNote').hidden = false;
    $('previewNote').textContent = 'معاينةٌ بصفتك «' + (me.role_ar || '') + '» — للقراءة وحدها، والأفعالُ للطالب من حسابه.';
    if (card.error) flash('bad', errText(card.error));
    $('sView').hidden = false;
    renderOff();
    await load();
  })();
})();
