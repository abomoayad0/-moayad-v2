// مؤيّد · سجلّاتُ الرعاية عند الموجّه — تكليف ٣٦ (window.MoayadRiaya)
// ① «سجلّاتي»: v2_care_kinds(p_school) فهرسًا بعدّاد كلٍّ (عددهم — وعددُه_محجوب ⇒ «للموجّهِ وحدَه» لا صفر) · والضغطُ يفتح السجلّ: v2_care_register(p_school, p_kind)
//    وما يُفتَح فيه false (محسوبٌ أو ميدانُه آخر) يُعرض بملاحظته ولا وسمَ عليه · والمستجدّون بسببه كما جاء
// ② سجلّاتُ رعايته في ملفّ الطالب: v2_care_of_student(p_student) · ووسمُه من هنا: v2_care_set(p_student, p_kind, p_note)
//    والإخراجُ بسببٍ مكتوب: v2_care_end(p_student, p_kind, p_why) — والقاعدةُ تردّ ما قلّ عن حدّه · ولا زرَّ حذفٍ البتّة
// والسرّيُّ محجوبٌ في القاعدة: فهرسُ غيرِ الموجّه لا يحمله — فلا بابَ يُعرض له ليُردّ عنه
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { ar, arabize, btn, flash } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));

  // ======================= ① «سجلّاتي» =======================
  // openStudent(sid): يفتح ملفَّ الطالب في الشاشة نفسِها
  async function tab(box, openStudent) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_care_kinds', { p_school: school() }, 'سجلّاتي');
    box.textContent = '';
    if (error) { errBox(box, error); arabize(box); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-meta', d['البيان']));
    const rows = (d['السجلّات'] || []).filter((k) => k['مخفيّ'] !== true);
    const ul = el('ul', 'rs-acts');
    for (const k of rows) {
      const li = el('li', 'click');
      li.setAttribute('role', 'button'); li.tabIndex = 0;
      const sp = el('span'); sp.style.flex = '1';
      const h = el('b', null, k['السجلّ'] || '');
      if (k['سرّي']) h.appendChild(el('span', 'rs-tag', 'سرّيّ'));
      sp.appendChild(h);
      // ما لا يُوسَم بيدٍ: ملاحظتُه تقول لماذا — ولا زرَّ إضافة
      if (k['يُفتَح'] === false && k['ملاحظة']) sp.appendChild(el('div', 'rs-meta', k['ملاحظة']));
      li.appendChild(sp);
      // العدّاد: عددهم كما جاء · والمحجوبُ «للموجّهِ وحدَه» لا صفر · ولا عددَ لما لا يُعدّ
      if (k['عددُه_محجوب']) li.appendChild(el('span', 'rs-tag', 'للموجّهِ وحدَه'));
      else if (k['عددهم'] != null) li.appendChild(el('span', 'rs-tag own', ar(k['عددهم'])));
      V.tap(li, () => register(box, k, openStudent));
      ul.appendChild(li);
    }
    box.appendChild(ul);
    if (!rows.length) box.appendChild(el('p', 'rs-empty', 'لا سجلّاتِ رعاية.'));
    arabize(box);
  }

  async function register(box, k, openStudent) {
    box.textContent = '';
    box.appendChild(btn('→ سجلّاتي', 'rs-btn ghost', () => tab(box, openStudent)));
    const { data, error } = await M.rpc('v2_care_register', { p_school: school(), p_kind: k['المفتاح'] }, 'سجلّ رعاية');
    if (error) { errBox(box, error); arabize(box); return; }
    const d = data || {};
    box.appendChild(el('h4', 'rs-sub', d['السجلّ'] || k['السجلّ'] || ''));
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    if (d['تعريفه']) box.appendChild(el('p', 'rs-note', d['تعريفه']));
    for (const s of d['الطلاب'] || []) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [s['الطالب'], s['الصفّ']].filter(Boolean).join(' · ')));
      // بأيِّهما دخل المستجدّ (سببه) · ومنذ متى · وملاحظتُه · ومن أدخله
      if (s['سببه']) f.appendChild(el('p', null, s['سببه']));
      f.appendChild(V.line('p', 'rs-meta', [s['منذ_ar'], s['أدخلَه']]));
      if (s['ملاحظة'] && s['ملاحظة'] !== s['سببه']) f.appendChild(d['يُوسَم'] ? V.typed(s['ملاحظة'], 'p', 'rs-meta') : el('p', 'rs-meta', s['ملاحظة']));
      const r = el('div', 'rs-row');
      if (openStudent) r.appendChild(btn('افتحْ ملفَّه', 'rs-btn ghost', () => openStudent(s['الطالب_id'])));
      if (d['يُوسَم']) r.appendChild(btn('أخرِجْه', 'rs-btn', () => endForm({ id: s['الطالب_id'], name: s['الطالب'] }, { key: k['المفتاح'], label: d['السجلّ'] || k['السجلّ'] }, () => register(box, k, openStudent))));
      f.appendChild(r);
      box.appendChild(f);
    }
    arabize(box);
  }

  // ======================= ② سجلّاتُ رعايته في ملفّه =======================
  async function studentBlock(box, stu) {
    box.textContent = '';
    const [mine, kinds] = await Promise.all([
      M.rpc('v2_care_of_student', { p_student: stu.id }, 'سجلّات رعاية الطالب'),
      M.rpc('v2_care_kinds', { p_school: school() }, 'سجلّات الرعاية'),
    ]);
    if (mine.error) { errBox(box, mine.error); arabize(box); return; }
    const d = mine.data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-meta', d['البيان']));
    const have = new Set();
    for (const k of d['السجلّات'] || []) {
      have.add(k['المفتاح']);
      const f = el('div', 'rs-file');
      const h = el('h5', null, k['السجلّ'] || '');
      if (k['سرّي']) h.appendChild(el('span', 'rs-tag', 'سرّيّ'));
      f.appendChild(h);
      if (k['منذ_ar']) f.appendChild(el('p', 'rs-meta', k['منذ_ar']));
      if (k['ملاحظة']) f.appendChild(V.typed(k['ملاحظة'], 'p', 'rs-meta'));
      const r = el('div', 'rs-row');
      r.appendChild(btn('أخرِجْه', 'rs-btn', () => endForm(stu, { key: k['المفتاح'], label: k['السجلّ'] }, () => studentBlock(box, stu))));
      f.appendChild(r);
      box.appendChild(f);
    }
    // الوسمُ من هنا — وما يُفتَح وحدَه يُعرض للاختيار (المحسوبُ لا يُوسَم)
    const can = ((kinds.data && kinds.data['السجلّات']) || []).filter((k) => k['يُفتَح'] === true && !have.has(k['المفتاح']));
    if (kinds.error) errBox(box, kinds.error);
    else if (can.length) {
      const r = el('div', 'rs-row');
      r.appendChild(btn('ضعْ وسمًا', 'rs-btn soft', () => setForm(stu, can, () => studentBlock(box, stu))));
      box.appendChild(r);
    }
    arabize(box);
  }

  function setForm(stu, kinds, after) {
    V.form({
      title: 'وسمُ رعاية', what: stu.name || '',
      fields: [
        { key: 'kind', type: 'choose', label: 'السجلّ', items: kinds.map((k) => [k['المفتاح'], k['السجلّ'], k['سرّي'] ? 'سرّيّ' : '']) },
        { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 },
      ],
      ok: 'ضعْه',
      onOk: async (v) => {
        if (!v.kind) return 'اخترِ السجلّ';
        const { data, error } = await M.rpc('v2_care_set', { p_student: stu.id, p_kind: v.kind, p_note: v.note }, 'وسم رعاية');
        if (error) return error;
        flash('ok', (data && data['البيان']) || '');
        if (after) after();
        return null;
      },
    });
  }

  function endForm(stu, k, after) {
    V.form({
      title: 'إخراجٌ من سجلّ', what: (stu.name ? stu.name + ' — ' : '') + (k.label || ''),
      fields: [{ key: 'why', type: 'textarea', label: 'السبب — مكتوبًا', rows: 3, hint: 'ويبقى أثرُه في سجلِّه — لا حذف' }],
      ok: 'أخرِجْه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_care_end', { p_student: stu.id, p_kind: k.key, p_why: v.why }, 'إخراج من سجلّ رعاية');
        if (error) return error;
        flash('ok', (data && data['البيان']) || '');
        if (after) after();
        return null;
      },
    });
  }

  window.MoayadRiaya = { tab, studentBlock };
})();
