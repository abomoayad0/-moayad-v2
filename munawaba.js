// مؤيّد · جدولُ المناوبة في لوحة التحكّم (تكليف ⑳) — ثلاثُ لوحات:
// ① مناوبةُ اليوم: v2_duty_day ⇐ الحالةُ محسوبةٌ من غياب المنسوبين (لا حقلَ ولا زرَّ حضور) · v2_duty_substitute · v2_duty_substitute_answer
// ② الجدول: v2_duty_zones (المواضعُ كلُّها ومنها الفارغ) · v2_duty_roster_view · v2_duty_eligible (مرتَّبًا بالعدل)
//    v2_duty_assign_day · v2_duty_release_day · v2_duty_zone_add · _remove · _replace · _move · v2_duty_autofill
// ③ طلباتُ المبادلة: v2_duty_swaps_board · v2_duty_swap_request · _partner · _approve · _cancel
// ④ لوحةُ المواضع (تكليف ٣٠): v2_zone_board (المواضعُ بأرقامها · و«بلا_موضع» سطرٌ مستقلّ) · والضغطُ على موضعٍ v2_zone_records
//    وشريطُ التجربة إن كانت «منها_تجربة» فوق الصفر — ولا تُطرح من الجملة · والمدى افتراضُه اليومُ (لا يُرسل إن لم يُختر)
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
    V.pick(pk, [['day', 'مناوبةُ اليوم'], ['roster', 'الجدول'], ['swaps', 'طلباتُ المبادلة'], ['zones', 'لوحةُ المواضع']], st.tab, (v) => { st.tab = v; draw(body); });
    draw(body);
  }
  function draw(body) {
    body.textContent = '';
    ({ day: dayTab, roster: rosterTab, swaps: swapsTab, zones: zonesTab }[st.tab])(body);
  }
  // ---------- ④ لوحةُ المواضع ----------
  async function zonesTab(body) {
    const c = el('section', 'rs-card');
    body.appendChild(c);
    const rng = el('div', 'rs-row');
    const inp = (lbl, v) => { const w = el('label', null, lbl); const i = el('input'); i.type = 'date'; i.value = v || ''; w.appendChild(i); rng.appendChild(w); return i; };
    const fi = inp('من', st.zFrom); const ti = inp('إلى', st.zTo);
    rng.appendChild(btn('اعرض', 'rs-btn soft', () => { st.zFrom = fi.value || null; st.zTo = ti.value || null; body.textContent = ''; zonesTab(body); }));
    c.appendChild(rng);
    const args = Object.assign({ p_school: school() }, st.zFrom ? { p_from: st.zFrom } : {}, st.zTo ? { p_to: st.zTo } : {});
    const { data, error } = await M.rpc('v2_zone_board', args, 'لوحة المواضع');
    if (error) { errBox(c, error); arabize(c); return; }
    const d = data || {};
    // 🔴 شريطُ التجربة — والعددُ كما رجع، ولا يُطرح من الجملة
    const trial = d['منها_تجربة'];
    if (trial && !/^[0٠]$/.test(String(trial))) c.appendChild(el('div', 'rs-said rs-orange', '⚠ من هذي الرصداتِ ' + trial + ' رصدةٍ تجريبيّة — المدرسةُ في وضعِ التجربة'));
    c.appendChild(el('p', 'rs-meta', [d['من'], d['إلى'] && d['إلى'] !== d['من'] ? d['إلى'] : null].filter(Boolean).join(' ← ')));
    if (d['البيان']) c.appendChild(el('p', 'rs-sum', d['البيان']));
    if (d['الجملة'] != null) c.appendChild(el('p', null, 'الجملة: ' + d['الجملة']));
    // الأكثرُ رصدًا أوّلًا (عدد رقمًا للترتيب) — والباقي بترتيبه
    const rows = arr(d['المواضع']).slice().sort((a, b) => (Number(b['عدد']) || 0) - (Number(a['عدد']) || 0));
    for (const z of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, z['الموضع'] || z['مفتاح']));
      f.appendChild(el('p', 'rs-meta', [z['المقطع'] && z['المقطع'] !== '—' ? z['المقطع'] : null, z['النصاب'] != null ? 'النصاب: ' + V.ar(z['النصاب']) : null, z['آخرُ رصدة'] && z['آخرُ رصدة'] !== '—' ? 'آخرُ رصدة: ' + z['آخرُ رصدة'] : null].filter(Boolean).join(' · ')));
      if (z['البيان']) f.appendChild(el('p', null, z['البيان']));
      const recs = el('div');
      if (Number(z['عدد']) > 0) f.appendChild(btn('رصداتُه', 'rs-btn soft', () => zoneRecords(recs, z, args)));
      f.appendChild(recs);
      c.appendChild(f);
    }
    // «بلا_موضع» سطرٌ مستقلٌّ لا يُخلط بالمواضع — ممارساتُ الحصّة
    const nz = d['بلا_موضع'];
    if (nz) {
      const f = el('div', 'rs-file rs-prev');
      f.appendChild(el('h5', null, 'بلا موضع'));
      if (nz['البيان']) f.appendChild(el('p', null, nz['البيان']));
      c.appendChild(f);
    }
    arabize(c);
  }
  async function zoneRecords(box, z, args) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_zone_records', Object.assign({}, args, { p_zone: z['مفتاح'] }), 'رصدات الموضع');
    if (error) { errBox(box, error); arabize(box); return; }
    const rows = arr(data);
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'لا رصدات.')); return; }
    const ul = el('ul', 'rs-acts');
    for (const r of rows) {
      const li = el('li');
      const sp = el('span'); sp.style.flex = '1';
      sp.appendChild(el('b', null, [r['الطالب'], r['الصف']].filter(Boolean).join(' · ')));
      sp.appendChild(el('div', 'rs-meta', [r['الممارسة'], r['القطبية'], r['الوزن']].filter(Boolean).join(' · ')));
      sp.appendChild(el('div', 'rs-meta', [r['التاريخ'], r['الراصد'], r['صفتُه']].filter(Boolean).join(' · ')));
      if (r['الملاحظة']) sp.appendChild(V.typed(r['الملاحظة'], 'div', 'rs-meta'));
      li.appendChild(sp);
      ul.appendChild(li);
    }
    box.appendChild(ul);
    arabize(box);
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
    const again = () => draw(body);
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
        if (r['مقترح_id']) row.appendChild(btn('كلّف المقترح', 'rs-btn', () => subForm(again, d, zone, absent, r['مقترح_id'], r['المقترح'])));
        row.appendChild(btn('كلّف بديلًا', 'rs-btn soft', () => subForm(again, d, zone, absent, null, null)));
      }
      // جوابُ البديل: له وحدَه، والبابُ يحرسه
      if (r['بديل_id'] && (r['موافقة_البديل'] == null || r['موافقة_البديل'] === '')) row.append(btn('أوافق على البدل', 'rs-btn soft', () => answerForm(again, d, zone, absent, true)), btn('أعتذر', 'rs-btn ghost', () => answerForm(again, d, zone, absent, false)));
      if (row.childNodes.length) f.appendChild(row);
      body.appendChild(f);
    }
    arabize(body);
  }
  async function subForm(again, d, zone, absent, sub, subName) {
    const items = sub ? [[sub, subName || '', 'المقترح']] : await eligible();
    V.form({
      title: 'تكليفُ بديل', what: 'يوافق البديلُ أو يعتذر — ولا يُفرض عليه', ok: 'كلّفه',
      fields: [{ key: 'p', type: 'choose', label: 'البديل', items, value: sub || null }, { key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_substitute', { p_school: school(), p_date: d, p_zone: zone, p_absent: absent, p_sub: v.p, p_note: v.n }, 'تكليف بديل');
        if (x.error) return x.error;
        flashRes(x.data); again(); return null;
      },
    });
  }
  function answerForm(again, d, zone, absent, ok) {
    V.form({
      title: ok ? 'الموافقةُ على البدل' : 'الاعتذارُ عن البدل', ok: ok ? 'أوافق' : 'أعتذر',
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc('v2_duty_substitute_answer', { p_school: school(), p_date: d, p_zone: zone, p_absent: absent, p_ok: ok, p_note: v.n }, 'جواب البديل');
        if (x.error) return x.error;
        flashRes(x.data); again(); return null;
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
        // تاريخُ التكليف بلفظه (من_تاريخ_ar) إن جاء — والخامُّ (من_تاريخ) لا يُعرض
        sp.append(el('b', null, p['المنسوب'] || ''), el('div', 'rs-meta', [p['النوع'], p['من_تاريخ_ar'] ? 'بدايةُ التكليف: ' + p['من_تاريخ_ar'] : null].filter(Boolean).join(' · ')));
        const w = el('span', 'rs-ibs');
        w.append(btn('استبدل', 'rs-btn ghost', () => replaceForm(b, wd, key, p)), btn('انقله', 'rs-btn ghost', () => moveForm(b, wd, key, p, arr(z.data))), btn('ارفعه', 'rs-btn ghost', () => removeForm(b, wd, key, p)));
        // رفعُ التكليف كاملًا لكلّ صفّ: بوسمه إن أُنشئ بـ«كلّف يومًا كاملًا» (v2_duty_release_day) · وإلّا بالمنسوب ويومه (v2_duty_release_person)
        w.appendChild(btn('ارفع التكليفَ كاملًا', 'rs-btn ghost', () => releaseForm(b, wd, p)));
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
  function releaseForm(b, wd, p) {
    V.form({
      title: 'رفعُ التكليف كاملًا', what: [p['المنسوب'], p['اليوم']].filter(Boolean).join(' — '), ok: 'ارفعه',
      onOk: async () => {
        const x = p['وسم_التكليف']
          ? await M.rpc('v2_duty_release_day', { p_school: school(), p_day_ref: p['وسم_التكليف'] }, 'رفع تكليف كامل')
          : await M.rpc('v2_duty_release_person', { p_school: school(), p_weekday: wd, p_person: p['منسوب_id'] }, 'رفع تكليف كامل');
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
  // اللفظُ إن جاء (X_ar)، وإلّا القديمُ إن كان نصًّا لا تاريخًا خامًّا — فلا تنكسر الشاشةُ قبل تبديل البابِ ولا بعده
  const dayOf = (r, k) => r[k + '_ar'] || (typeof r[k] === 'string' && !/^\d{4}-\d{2}-\d{2}$/.test(r[k]) ? r[k] : null);
  async function swapsTab(body) { await swapsList(body, () => draw(body), true); }
  async function swapsList(body, again, admin) {
    const top = el('div', 'rs-row');
    top.appendChild(btn('اطلب مبادلة', 'rs-btn', () => requestForm(again)));
    body.appendChild(top);
    const { data, error } = await M.rpc('v2_duty_swaps_board', { p_school: school() }, 'طلبات المبادلة');
    if (error) { errBox(body, error); arabize(body); return; }
    const rows = arr(data);
    if (!rows.length) body.appendChild(el('p', 'rs-meta', 'لا طلبَ مبادلة.'));
    for (const r of rows) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, [r['صاحب_الطلب'] || r['الطالب'], r['الطرف']].filter(Boolean).join(' ⇄ ')), el('span', 'rs-who', r['الحال'] || ''));
      f.appendChild(hd);
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['يومُه', dayOf(r, 'يومه')], ['يومُ الطرف', dayOf(r, 'يوم_الطرف')], ['موافقةُ الطرف', r['موافقة_الطرف']], ['اعتمادُ الوكيل', r['اعتماد_الوكيل']]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, v));
      if (r['السبب']) lg.append(el('i', 'k', 'السبب:'), V.typed(r['السبب'], 'i'));
      f.appendChild(lg);
      // الأزرارُ لكلّ ذي شأن — والبابُ يحرس من يملك كلًّا منها · والاعتمادُ للوكيل في لوحته وحدَها
      const id = r['رقم'];
      const row = el('div', 'rs-row');
      row.append(btn('يوافق الطرف', 'rs-btn soft', () => okForm(again, 'v2_duty_swap_partner', id, true, 'جوابُ الطرف')),
        btn('يعتذر الطرف', 'rs-btn ghost', () => okForm(again, 'v2_duty_swap_partner', id, false, 'جوابُ الطرف')));
      if (admin) row.append(btn('اعتمدها', 'rs-btn', () => okForm(again, 'v2_duty_swap_approve', id, true, 'اعتمادُ الوكيل')),
        btn('رُدّها', 'rs-btn ghost', () => okForm(again, 'v2_duty_swap_approve', id, false, 'اعتمادُ الوكيل')));
      row.appendChild(btn('ألغِ الطلب', 'rs-btn ghost', () => cancelForm(again, id)));
      f.appendChild(row);
      body.appendChild(f);
    }
    arabize(body);
  }

  // ================= صفحةُ المعلّم: مناوبتي — البدلُ الذي ينتظر جوابَه · وطلباتُ المبادلة =================
  // المبادلةُ بين معلّمين، فمكانُها صفحتُه لا لوحةٌ لا يفتحها (قرارُ مفرح)
  async function mineTool(box) {
    box.textContent = '';
    const again = () => mineTool(box);
    const me = (M.state.me && M.state.me.person_id) || null;
    const d = today();
    box.appendChild(el('h4', 'rs-sub', 'بدلٌ ينتظر جوابي'));
    const { data, error } = await M.rpc('v2_duty_day', M.state.date ? { p_school: school(), p_date: d } : { p_school: school() }, 'مناوبة اليوم');
    if (error) errBox(box, error);
    const mine = arr(data).filter((r) => me && r['بديل_id'] === me && (r['موافقة_البديل'] == null || r['موافقة_البديل'] === ''));
    if (!error && !mine.length) box.appendChild(el('p', 'rs-meta', 'لا بدلَ ينتظر جوابك اليوم.'));
    for (const r of mine) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, r['الموضع'] || ''));
      if (r['البيان']) f.appendChild(el('p', 'rs-meta', r['البيان']));
      const row = el('div', 'rs-row');
      row.append(btn('أوافق على البدل', 'rs-btn', () => answerForm(again, d, r['مفتاح_الموضع'], r['مناوب_id'], true)), btn('أعتذر', 'rs-btn ghost', () => answerForm(again, d, r['مفتاح_الموضع'], r['مناوب_id'], false)));
      f.appendChild(row);
      box.appendChild(f);
    }
    box.appendChild(el('h4', 'rs-sub', 'طلباتُ المبادلة'));
    const sw = el('div'); box.appendChild(sw);
    await swapsList(sw, again, false);
    arabize(box);
  }
  function okForm(again, fn, id, ok, title) {
    V.form({
      title, ok: ok ? 'أقرّ' : 'رُدّ',
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc(fn, { p_id: id, p_ok: ok, p_note: v.n }, title);
        if (x.error) return x.error;
        flashRes(x.data); again(); return null;
      },
    });
  }
  function cancelForm(again, id) {
    V.form({
      title: 'إلغاءُ طلب المبادلة', ok: 'ألغِه',
      onOk: async () => {
        const x = await M.rpc('v2_duty_swap_cancel', { p_id: id }, 'إلغاء المبادلة');
        if (x.error) return x.error;
        flashRes(x.data); again(); return null;
      },
    });
  }
  async function requestForm(again) {
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
        flashRes(x.data); again(); return null;
      },
    });
  }

  window.MoayadMunawaba = { rosterTool, mineTool };
})();
