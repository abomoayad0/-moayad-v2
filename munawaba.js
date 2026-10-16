// مؤيّد · جدولُ المناوبة في لوحة التحكّم (تكليف ⑳) — ثلاثُ لوحات:
// ① مناوبةُ اليوم: v2_duty_day ⇐ الحالةُ محسوبةٌ من غياب المنسوبين (لا حقلَ ولا زرَّ حضور) · v2_duty_substitute · v2_duty_substitute_answer
// ② الجدول: v2_duty_zones (المواضعُ كلُّها ومنها الفارغ) · v2_duty_roster_view · v2_duty_eligible (مرتَّبًا بالعدل)
//    v2_duty_assign_day · v2_duty_release_day · v2_duty_zone_add · _remove · _replace · _move · v2_duty_autofill
// ③ طلباتُ المبادلة: v2_duty_swaps_board · v2_duty_swap_request · _partner · _approve · _cancel
// التكليفُ مرّةً ويستمرّ ولا جلسةَ تُفتح وتُغلق · والنصابُ حدٌّ أدنى يُخبَر به ولا يُمنع تجاوزُه
// وكلُّ معلّمٍ يرصد في مواضع اليوم ولو لم يُكلَّف — فلا منعَ ولا عقابَ هنا · ورسائلُ الأبواب بلفظها
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn } = V;
  const school = () => M.state.school;
  const arr = (d) => (Array.isArray(d) ? d : []);
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));
  const today = () => M.state.date || new Date().toLocaleDateString('en-CA');
  // أيّامُ الدراسة: p_weekday ٠–٦ كما في الباب (الأحد ٠) — والاسمُ من صفوف الجدول إن جاء
  const DAYS = [[0, 'الأحد'], [1, 'الاثنين'], [2, 'الثلاثاء'], [3, 'الأربعاء'], [4, 'الخميس']];
  // موافقةُ البديل ثلاث: لم يُجب · وافق · رفض — والرفضُ جوابٌ لا خطأ
  const answer = (v) => (v == null || v === '' ? 'لم يُجب' : ['true', 't', 'نعم', 'وافق'].includes(String(v)) ? 'وافق' : ['false', 'f', 'لا', 'رفض'].includes(String(v)) ? 'رفض' : String(v));
  const said = (d) => (typeof d === 'string' ? d : arr(d).map((r) => Object.values(r).filter((x) => typeof x === 'string').join(' — ')).join(' · '));

  const st = { tab: 'day', day: 0, eligible: null };
  async function rosterTool(box) {
    box.textContent = '';
    const pk = el('div', 'rs-pick'); const body = el('div');
    box.append(pk, body);
    V.pick(pk, [['day', 'مناوبةُ اليوم'], ['roster', 'الجدول'], ['swaps', 'طلباتُ المبادلة']], st.tab, (v) => { st.tab = v; draw(body); });
    draw(body);
  }
  function draw(body) {
    body.textContent = '';
    ({ day: dayTab, roster: rosterTab, swaps: swapsTab }[st.tab])(body);
  }
  async function eligible() {
    if (st.eligible) return st.eligible;
    const { data, error } = await M.rpc('v2_duty_eligible', { p_school: school() }, 'من يصلح للمناوبة');
    if (error) { V.flash('bad', errText(error)); return []; }
    // مرتَّبون بالعدل كما رجعوا — ومن استُثني يُقال سببُه
    st.eligible = arr(data).map((x) => [x.person_id, x.person_ar || '', [x.post_ar, x.excluded_ar].filter(Boolean).join(' · ')]);
    return st.eligible;
  }
  const flashRes = (d) => V.flash('ok', said(d));

  // ================= ① مناوبةُ اليوم =================
  async function dayTab(body) {
    const d = today();
    const { data, error } = await M.rpc('v2_duty_day', M.state.date ? { p_school: school(), p_date: d } : { p_school: school() }, 'مناوبة اليوم');
    if (error) { errBox(body, error); arabize(body); return; }
    const rows = arr(data);
    if (!rows.length) body.appendChild(el('p', 'rs-meta', 'لا مناوبةَ مسندةً لهذا اليوم.'));
    for (const r of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, r['الموضع'] || ''));
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['المناوب', r['المناوب']], ['الحالة', r['الحالة']], ['البديل', r['البديل']], ['موافقةُ البديل', r['بديل_id'] ? answer(r['موافقة_البديل']) : null], ['المقترح', r['المقترح']]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, v));
      f.appendChild(lg);
      if (r['البيان']) f.appendChild(el('p', 'rs-meta', r['البيان']));
      const row = el('div', 'rs-row');
      const zone = r['مفتاح_الموضع']; const absent = r['مناوب_id'];
      // البديلُ يكلّفه الوكيل ولا يُفرض عليه — والمقترحُ اقتراحٌ لا تنفيذ
      if (absent && r['الحالة'] !== 'حاضر') {
        if (r['مقترح_id']) row.appendChild(btn('كلّف المقترح', 'rs-btn', () => subForm(body, d, zone, absent, r['مقترح_id'], r['المقترح'])));
        row.appendChild(btn('كلّف بديلًا', 'rs-btn soft', () => subForm(body, d, zone, absent, null, null)));
      }
      // جوابُ البديل: له وحدَه، والبابُ يحرسه
      if (r['بديل_id'] && (r['موافقة_البديل'] == null || r['موافقة_البديل'] === '')) row.append(btn('أوافق على البدل', 'rs-btn soft', () => answerForm(body, d, zone, absent, true)), btn('أعتذر', 'rs-btn ghost', () => answerForm(body, d, zone, absent, false)));
      if (row.childNodes.length) f.appendChild(row);
      body.appendChild(f);
    }
    arabize(body);
  }
  async function subForm(body, d, zone, absent, sub, subName) {
    const items = sub ? [[sub, subName || '', 'المقترح']] : await eligible();
    V.form({
      title: 'تكليفُ بديل', what: 'يوافق البديلُ أو يعتذر — ولا يُفرض عليه', ok: 'كلّفه',
      fields: [{ key: 'p', type: 'choose', label: 'البديل', items, value: sub || null }, { key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_substitute', { p_school: school(), p_date: d, p_zone: zone, p_absent: absent, p_sub: v.p, p_note: v.n }, 'تكليف بديل');
        if (x.error) return x.error;
        flashRes(x.data); draw(body); return null;
      },
    });
  }
  function answerForm(body, d, zone, absent, ok) {
    V.form({
      title: ok ? 'الموافقةُ على البدل' : 'الاعتذارُ عن البدل', ok: ok ? 'أوافق' : 'أعتذر',
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_substitute_answer', { p_school: school(), p_date: d, p_zone: zone, p_absent: absent, p_ok: ok, p_note: v.n }, 'جواب البديل');
        if (x.error) return x.error;
        flashRes(x.data); draw(body); return null;
      },
    });
  }

  // ================= ② الجدول =================
  async function rosterTab(body) {
    const pk = el('div', 'rs-pick'); const b = el('div');
    body.append(pk, b);
    V.pick(pk, DAYS, st.day, (v) => { st.day = v; drawDay(b); });
    drawDay(b);
  }
  async function drawDay(b) {
    b.textContent = '';
    const wd = st.day;
    const [z, r] = await Promise.all([
      M.rpc('v2_duty_zones', { p_school: school(), p_weekday: wd }, 'مواضع المناوبة'),
      M.rpc('v2_duty_roster_view', { p_school: school(), p_weekday: wd }, 'جدول المناوبة'),
    ]);
    if (z.error) { errBox(b, z.error); arabize(b); return; }
    if (r.error) errBox(b, r.error);
    const roster = arr(r.data);
    const top = el('div', 'rs-row');
    top.appendChild(btn('كلّف يومًا كاملًا', 'rs-btn', () => assignDayForm(b, wd)));
    b.appendChild(top);
    for (const zn of arr(z.data)) {
      const key = zn['مفتاح'];
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      // لفظُ المقطع إن جاء — وإلّا فاسمُ الموضع وحدَه، ولا لفظَ من عندنا
      hd.append(el('h5', null, [zn['الموضع'], zn['لفظ_المقطع'] && zn['لفظ_المقطع'] !== zn['الموضع'] ? zn['لفظ_المقطع'] : null].filter(Boolean).join(' · ')));
      if (zn['دون_النصاب']) hd.appendChild(el('span', 'rs-state-open', 'دون النصاب'));
      f.appendChild(hd);
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['النصاب', zn['النصاب']], ['القائمون', zn['القائمون']]]) if (v != null) lg.append(el('i', 'k', k + ':'), el('i', null, String(v)));
      f.appendChild(lg);
      if (zn['ملاحظة']) f.appendChild(el('p', 'rs-meta', zn['ملاحظة']));
      const ul = el('ul', 'rs-acts');
      for (const p of roster.filter((x) => x['مفتاح_الموضع'] === key)) {
        const li = el('li'); const sp = el('span'); sp.style.flex = '1';
        // «من_تاريخ» خامٌّ بلا لفظ — فلا يُعرض حتى يأتي لفظُه من الباب
        sp.append(el('b', null, p['المنسوب'] || ''), el('div', 'rs-meta', p['النوع'] || ''));
        const w = el('span', 'rs-ibs');
        w.append(btn('استبدل', 'rs-btn ghost', () => replaceForm(b, wd, key, p)), btn('انقله', 'rs-btn ghost', () => moveForm(b, wd, key, p, arr(z.data))), btn('ارفعه', 'rs-btn ghost', () => removeForm(b, wd, key, p)));
        // رفعُ التكليف كاملًا بوسمه — ولا يظهر الزرّ إن لم يرجع الوسم
        if (p['وسم_التكليف']) w.appendChild(btn('ارفع التكليفَ كاملًا', 'rs-btn ghost', () => releaseForm(b, p)));
        li.append(sp, w); ul.appendChild(li);
      }
      f.appendChild(ul);
      const row = el('div', 'rs-row');
      row.append(btn('أسند منسوبًا', 'rs-btn soft', () => addForm(b, wd, key, zn['الموضع'])), btn('وزّع آليًّا بالعدل', 'rs-btn ghost', () => autofill(b, wd, key)));
      f.appendChild(row);
      b.appendChild(f);
    }
    arabize(b);
  }
  async function personForm(title, what, extra, run) {
    const items = await eligible();
    V.form({
      title, what, ok: 'أقرّ',
      fields: [{ key: 'p', type: 'choose', label: 'المنسوب', items }].concat(extra || []).concat([{ key: 'dec', label: 'القرار (اختياريّ)' }]),
      onOk: run,
    });
  }
  const dayName = (wd) => (DAYS.find((x) => x[0] === wd) || [0, ''])[1];
  function assignDayForm(b, wd) {
    personForm('تكليفُ يومٍ كامل', dayName(wd) + ' — بكلّ المواضع، ويستمرّ', null, async (v) => {
      const x = await M.rpc('v2_duty_assign_day', { p_school: school(), p_weekday: wd, p_person: v.p, p_decision: v.dec }, 'تكليف يوم كامل');
      if (x.error) return x.error;
      flashRes(x.data); drawDay(b); return null;
    });
  }
  function addForm(b, wd, key, zoneAr) {
    personForm('إسنادُ موضع', [dayName(wd), zoneAr].join(' — '), null, async (v) => {
      const x = await M.rpc('v2_duty_zone_add', { p_school: school(), p_weekday: wd, p_zone: key, p_person: v.p, p_decision: v.dec }, 'إسناد موضع');
      if (x.error) return x.error;
      flashRes(x.data); drawDay(b); return null;
    });
  }
  function replaceForm(b, wd, key, p) {
    personForm('استبدالُ مناوب', [p['المنسوب'], p['الموضع']].filter(Boolean).join(' — '), null, async (v) => {
      const x = await M.rpc('v2_duty_zone_replace', { p_school: school(), p_weekday: wd, p_zone: key, p_old_person: p['منسوب_id'], p_new_person: v.p, p_decision: v.dec }, 'استبدال مناوب');
      if (x.error) return x.error;
      flashRes(x.data); drawDay(b); return null;
    });
  }
  function moveForm(b, wd, key, p, zones) {
    const items = zones.filter((z) => z['مفتاح'] !== key).map((z) => [z['مفتاح'], z['الموضع'] || '']);
    V.form({
      title: 'نقلٌ بين موضعين', what: [p['المنسوب'], p['الموضع']].filter(Boolean).join(' — '), ok: 'انقله',
      fields: [{ key: 'to', type: 'choose', label: 'إلى', items }, { key: 'dec', label: 'القرار (اختياريّ)' }],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_zone_move', { p_school: school(), p_weekday: wd, p_person: p['منسوب_id'], p_from_zone: key, p_to_zone: v.to, p_decision: v.dec }, 'نقل مناوب');
        if (x.error) return x.error;
        flashRes(x.data); drawDay(b); return null;
      },
    });
  }
  function removeForm(b, wd, key, p) {
    V.form({
      title: 'رفعٌ من الموضع', what: [p['المنسوب'], p['الموضع'], dayName(wd)].filter(Boolean).join(' — '), ok: 'ارفعه',
      onOk: async () => {
        const x = await M.rpc('v2_duty_zone_remove', { p_school: school(), p_weekday: wd, p_zone: key, p_person: p['منسوب_id'] }, 'رفع من موضع');
        if (x.error) return x.error;
        flashRes(x.data); drawDay(b); return null;
      },
    });
  }
  function releaseForm(b, p) {
    V.form({
      title: 'رفعُ التكليف كاملًا', what: [p['المنسوب'], p['اليوم']].filter(Boolean).join(' — '), ok: 'ارفعه',
      onOk: async () => {
        const x = await M.rpc('v2_duty_release_day', { p_school: school(), p_day_ref: p['وسم_التكليف'] }, 'رفع تكليف كامل');
        if (x.error) return x.error;
        flashRes(x.data); drawDay(b); return null;
      },
    });
  }
  async function autofill(b, wd, key) {
    const x = await M.rpc('v2_duty_autofill', { p_school: school(), p_weekday: wd, p_zone: key }, 'توزيع آليّ');
    if (x.error) { V.flash('bad', errText(x.error)); return; }
    // يُقال من أُسند — بألفاظه كما رجعت
    const got = arr(x.data).map((r) => r['أُسند']).filter(Boolean);
    V.flash('ok', got.length ? 'أُسند: ' + got.join(' · ') : 'لم يُسند أحد');
    drawDay(b);
  }

  // ================= ③ طلباتُ المبادلة =================
  // المبادلةُ ليومين بعينهما ولا تمسّ تكليفَ العام · بموافقة الطرفين ثمّ الوكيل
  async function swapsTab(body) {
    const top = el('div', 'rs-row');
    top.appendChild(btn('اطلب مبادلة', 'rs-btn', () => requestForm(body)));
    body.appendChild(top);
    const { data, error } = await M.rpc('v2_duty_swaps_board', { p_school: school() }, 'طلبات المبادلة');
    if (error) { errBox(body, error); arabize(body); return; }
    const rows = arr(data);
    if (!rows.length) body.appendChild(el('p', 'rs-meta', 'لا طلبَ مبادلة.'));
    for (const r of rows) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, [r['الطالب'], r['الطرف']].filter(Boolean).join(' ⇄ ')), el('span', 'rs-who', r['الحال'] || ''));
      f.appendChild(hd);
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['يومُه', r['يومه']], ['يومُ الطرف', r['يوم_الطرف']], ['موافقةُ الطرف', r['موافقة_الطرف']], ['اعتمادُ الوكيل', r['اعتماد_الوكيل']]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, v));
      if (r['السبب']) lg.append(el('i', 'k', 'السبب:'), V.typed(r['السبب'], 'i'));
      f.appendChild(lg);
      // الأزرارُ لكلّ ذي شأن — والبابُ يحرس من يملك كلًّا منها
      const id = r['رقم'];
      const row = el('div', 'rs-row');
      row.append(btn('يوافق الطرف', 'rs-btn soft', () => okForm(body, 'v2_duty_swap_partner', id, true, 'جوابُ الطرف')),
        btn('يعتذر الطرف', 'rs-btn ghost', () => okForm(body, 'v2_duty_swap_partner', id, false, 'جوابُ الطرف')),
        btn('اعتمدها', 'rs-btn', () => okForm(body, 'v2_duty_swap_approve', id, true, 'اعتمادُ الوكيل')),
        btn('رُدّها', 'rs-btn ghost', () => okForm(body, 'v2_duty_swap_approve', id, false, 'اعتمادُ الوكيل')),
        btn('ألغِ الطلب', 'rs-btn ghost', () => cancelForm(body, id)));
      f.appendChild(row);
      body.appendChild(f);
    }
    arabize(body);
  }
  function okForm(body, fn, id, ok, title) {
    V.form({
      title, ok: ok ? 'أقرّ' : 'رُدّ',
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc(fn, { p_id: id, p_ok: ok, p_note: v.n }, title);
        if (x.error) return x.error;
        flashRes(x.data); draw(body); return null;
      },
    });
  }
  function cancelForm(body, id) {
    V.form({
      title: 'إلغاءُ طلب المبادلة', ok: 'ألغِه',
      onOk: async () => {
        const x = await M.rpc('v2_duty_swap_cancel', { p_id: id }, 'إلغاء المبادلة');
        if (x.error) return x.error;
        flashRes(x.data); draw(body); return null;
      },
    });
  }
  async function requestForm(body) {
    const items = await eligible();
    V.form({
      title: 'طلبُ مبادلة', what: 'يومُك بيومه — بموافقته ثمّ الوكيل، ولا يمسّ تكليفَ العام', ok: 'أرسل الطلب',
      fields: [
        { key: 'p', type: 'choose', label: 'الطرفُ الآخر', items },
        { key: 'mine', type: 'date', label: 'يومُ مناوبتي' },
        { key: 'his', type: 'date', label: 'يومُ مناوبته' },
        { key: 'r', type: 'textarea', label: 'السبب (اختياريّ)', rows: 2 },
      ],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_swap_request', { p_partner: v.p, p_my_date: v.mine, p_partner_date: v.his, p_reason: v.r }, 'طلب مبادلة');
        if (x.error) return x.error;
        flashRes(x.data); draw(body); return null;
      },
    });
  }

  window.MoayadMunawaba = { rosterTool };
})();
