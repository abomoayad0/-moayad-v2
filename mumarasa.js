// مؤيّد · ممارساتُ مادّتي (تكليف ⑳) — مشتركةٌ بين قسم درجات المادّة في صفحة المعلّم وبطاقة الطالب في «صفّي»
// القائمةُ ملكٌ مشترك (عامّة · مدرستي · مادّتي) — والقيمةُ والمصبُّ ملكُ المعلّم وحده لمادّته
// v2_plan_practices · v2_plan_practice_items · v2_plan_practice_set · v2_plan_practice_hide · v2_plan_practice_reset
// v2_plan_practice_add · v2_grade_item_practice · v2_practice_item_mark · v2_record_practice
// درجةُ بند الممارسات تُحسب ولا تُكتب — فلا حقلَ لها · والقيمةُ مقدارٌ موجب والاتّجاهُ من القطبيّة · ولا حذفَ إلّا ما صنعه: إخفاء
// ورسائلُ الأبواب تُعرض بلفظها — ولا يُمنع شيءٌ هنا
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { btn, arabize } = V;
  const arr = (d) => (Array.isArray(d) ? d : []);
  // عناوينُ ما تقوله القطبيّةُ والأصل — مفاتيحُها من الباب (positive · negative) وألفاظُها ألفاظُ الشاشة
  const POL = { positive: 'موجبة', negative: 'سالبة' };
  const msg = (d) => (typeof d === 'string' ? d : (d && (d.said_ar || d.summary_ar || d.note_ar)) || '');

  // بنودُ الممارسات في خطّةٍ — Map(رقم_البند ← صفُّها) — يُقرأ مرّةً لكلّ خطّة ويُجدَّد بعد كلّ تعليم
  const cache = new Map();
  async function practiceItems(plan, fresh) {
    if (!plan) return new Map();
    if (!fresh && cache.has(plan)) return cache.get(plan);
    const { data, error } = await M.rpc('v2_plan_practice_items', { p_plan: plan }, 'بنود الممارسات');
    const m = new Map(error ? [] : arr(data).map((x) => [x['رقم_البند'], x]));
    if (!error) cache.set(plan, m);
    return m;
  }

  // ========== تعليمُ البند «من الممارسات» — بابٌ وحدَه بعد إنشاء البند (v2_grade_item_practice) ==========
  // الدرجةُ المبدئيّةُ إلزاميّةٌ عند التعليم، ومداها من صفرٍ إلى سقف البند — والبابُ يقول ذلك إن نقصت
  function markForm(it, plan, done) {
    V.form({
      title: 'بندٌ من الممارسات', what: it.title_ar || '', ok: 'علّمه',
      fields: [{ key: 'base', type: 'number', label: 'الدرجةُ المبدئيّة — ما يبدأ به الطالبُ قبل أثر الممارسات', hint: it.max_ar ? 'سقفُ البند: ' + it.max_ar : null }],
      onOk: async (v) => {
        const x = await M.rpc('v2_grade_item_practice', { p_item: it.id, p_is_practice: true, p_base: v.base }, 'تعليم البند من الممارسات');
        if (x.error) return x.error;
        V.flash('ok', msg(x.data));
        await practiceItems(plan, true); done(); return null;
      },
    });
  }
  // وإرجاعُه بندًا عاديًّا — ويُرفض إن صبّت فيه ممارسات: فلا تبقى روابطُ معلّقة
  function unmarkForm(it, plan, done) {
    V.form({
      title: 'إرجاعُه بندًا عاديًّا', what: it.title_ar || '', ok: 'أرجعه',
      onOk: async () => {
        const x = await M.rpc('v2_grade_item_practice', { p_item: it.id, p_is_practice: false, p_base: null }, 'إرجاع البند عاديًّا');
        if (x.error) return x.error;
        V.flash('ok', msg(x.data));
        await practiceItems(plan, true); done(); return null;
      },
    });
  }

  // خليّةُ بندٍ محسوبٍ في كشف الفصل: لا حقلَ — واللمسُ يُظهر بيانَه من v2_practice_item_mark
  function markCell(item, student, name) {
    return btn('من الممارسات', 'gr-auto', () => showMark(item, student, name));
  }
  async function showMark(item, student, name) {
    const { data, error } = await M.rpc('v2_practice_item_mark', { p_item: item, p_student: student }, 'درجة بند الممارسات');
    if (error) { V.flash('bad', errText(error)); return; }
    const r = arr(data)[0];
    if (!r) { V.flash('bad', 'لم يرجع البابُ درجةً لهذا البند'); return; }
    V.flash('ok', [name, r['البيان']].filter(Boolean).join(' — '));
  }
  // بنودُ الممارسات في بطاقة درجات الطالب: سطرُ كلِّ بندٍ بيانُه من الباب، وأعدادُه في خاناتٍ معنونة
  async function studentBox(plan, student) {
    const box = el('div', 'gr-bucket');
    const items = [...(await practiceItems(plan)).values()];
    if (!items.length) return null;
    box.appendChild(el('div', 'gr-bhead', 'بنودُ الممارسات — تُحسب ولا تُكتب'));
    for (const it of items) {
      const { data, error } = await M.rpc('v2_practice_item_mark', { p_item: it['رقم_البند'], p_student: student }, 'درجة بند الممارسات');
      if (error) { box.appendChild(el('div', 'notice err', errText(error))); continue; }
      const r = arr(data)[0] || {};
      box.appendChild(el('b', null, r['البند'] || it['البند'] || ''));
      if (r['البيان']) box.appendChild(el('p', 'rs-meta', r['البيان']));
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['المبدأ', r['المبدأ']], ['أضافت', r['أضافت']], ['أنقصت', r['أنقصت']], ['الدرجة', r['الدرجة']], ['السقف', r['السقف']]]) if (v != null) lg.append(el('i', 'k', k + ':'), el('i', null, String(Number(v))));
      box.appendChild(lg);
    }
    return box;
  }

  // ========== لوحةُ «ممارساتُ مادّتي» ==========
  const st = { scope: '', polarity: '' };
  // opts.locked: التوزيعُ معتمدٌ مقفل (تكليف ٢٧) — فلا أزرارَ تعديلٍ إطلاقًا، والقائمةُ للقراءة
  async function panel(box, plan, opts) {
    const locked = !!(opts && opts.locked);
    box.textContent = '';
    const c = el('section', 'rs-card');
    box.appendChild(c);
    if (!plan) { c.appendChild(el('p', 'rs-meta', 'لم يُفتح توزيعُ درجات هذه المادّة بعد — افتحه من «بطاقة التوزيع» ثمّ اضبط ممارساتِك.')); return; }
    const items = await practiceItems(plan, true);
    // ① بنودُ الممارسات في خطّته — وإن لم يكن منها شيءٌ فخطوتُه الأولى في «بطاقة التوزيع»
    c.appendChild(el('h4', 'rs-sub', 'بنودُ الممارسات في توزيعي'));
    if (!items.size) c.appendChild(el('p', 'rs-meta', 'لا بندَ من الممارسات بعد — أضف بندًا في «بطاقة التوزيع» ثمّ علّمه «من الممارسات» بدرجته المبدئيّة، ثمّ اربط به ممارساتِك هنا.'));
    for (const it of items.values()) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [it['البند'], it['السلّة']].filter(Boolean).join(' · ')));
      if (it['البيان']) f.appendChild(el('p', 'rs-meta', it['البيان']));
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['المبدأ', it['المبدأ']], ['السقف', it['السقف']], ['الموجبة', it['الموجبة']], ['السالبة', it['السالبة']]]) if (v != null) lg.append(el('i', 'k', k + ':'), el('i', null, String(Number(v))));
      f.appendChild(lg);
      c.appendChild(f);
    }
    // ② القائمةُ كما يراها: بمجالها وقطبيّتها — والمرشّحان يُرسلان إلى الباب ولا يُصفّى في الشاشة
    c.appendChild(el('h4', 'rs-sub', 'القائمة'));
    const fl = el('div', 'rs-row');
    const ps = el('select');
    for (const [k, t] of [['', 'الموجبةُ والسالبة'], ['positive', 'الموجبة'], ['negative', 'السالبة']]) { const o = el('option', null, t); o.value = k; ps.appendChild(o); }
    ps.value = st.polarity;
    ps.addEventListener('change', () => { st.polarity = ps.value; panel(box, plan); });
    const ss = el('select');
    const o0 = el('option', null, 'كلُّ المجالات'); o0.value = ''; ss.appendChild(o0);
    const sc = await M.rpc('v2_practice_scopes', { p_school: M.state.school }, 'مجالات الممارسات');
    const scopes = arr(sc.data).slice().sort((a, b) => (a.ord || 0) - (b.ord || 0)).map((x) => [x.key, x.label || '']).filter((x) => x[0]);
    for (const [k, t] of scopes) { const o = el('option', null, t); o.value = k; ss.appendChild(o); }
    ss.value = st.scope;
    ss.addEventListener('change', () => { st.scope = ss.value; panel(box, plan); });
    fl.append(ps, ss);
    if (!locked) fl.appendChild(btn('أنشئ ممارسةً لمادّتي', 'rs-btn', () => addForm(box, plan, scopes)));
    c.appendChild(fl);
    const { data, error } = await M.rpc('v2_plan_practices', { p_plan: plan, p_scope: st.scope || null, p_polarity: st.polarity || null }, 'ممارسات مادّتي');
    if (error) { c.appendChild(el('div', 'notice err', errText(error))); arabize(c); return; }
    const rows = arr(data);
    // عدّادُ ما ينتظر قيمتَه — للخطّة كلِّها لا للمرشّح · فيُعرف النقصُ من أوّلِ يوم قبل أن تتراكم الرصدات
    // جملتُه من الباب (v2_grade_plan_check · بلا_قيمة_جملة) — ولا يُركَّب عددٌ بكلمة
    const ck = await M.rpc('v2_grade_plan_check', { p_plan: plan }, 'فحص توزيع الدرجات');
    const wl = ck.data && ck.data['بلا_قيمة_جملة'];
    if (wl) c.insertBefore(el('div', 'rs-said rs-red', wl), fl);
    if (!rows.length) c.appendChild(el('p', 'rs-meta', 'لا ممارسةَ في هذا المرشّح.'));
    for (const p of rows) c.appendChild(practiceRow(p, box, plan, items, locked));
    arabize(c);
  }
  // بلا قيمة: قيمتُها صفرٌ أو لم تُقيَّم أو بلا مصبّ — والمخفيّةُ لا تُعدّ
  const noValue = (p) => !p['مخفيّة'] && (!Number(p['قيمتي']) || !p['المصبّ']);
  function practiceRow(p, box, plan, items, locked) {
    const f = el('div', 'rs-file' + (p['مخفيّة'] ? ' rs-prev' : ''));
    f.appendChild(el('h5', null, [p['الممارسة'], POL[p['القطبيّة']] || p['القطبيّة']].filter(Boolean).join(' — ')));
    if (noValue(p)) f.appendChild(el('p', 'rs-red', '⚠ بلا قيمة — ما تُضيفُ شيئًا'));
    const lg = el('div', 'rs-lgd');
    // أصلُها كما يقوله الباب (عامّة · مدرستي · مادّتي) — والقيمةُ والمصبُّ والعتبةُ والملاحظةُ في خانات
    for (const [k, v] of [['أصلُها', p['أصلها']], ['المجال', p['لفظ_المجال'] || p['المجال']], ['الموضع', p['الموضع']], ['قيمتي', p['قيمتي'] == null ? 'لم تُقيَّم' : String(Number(p['قيمتي']))], ['المصبّ', p['المصبّ'] || 'لم يُحدَّد'], ['العتبة', p['عتبة']], ['الحال', p['مخفيّة'] ? 'مخفيّةٌ عن مادّتي' : null]]) if (v) lg.append(el('i', 'k', k + ':'), el('i', null, v));
    if (p['ملاحظتي']) lg.append(el('i', 'k', 'ملاحظتي:'), V.typed(p['ملاحظتي'], 'i'));
    f.appendChild(lg);
    if (locked) return f;
    const row = el('div', 'rs-row');
    row.append(btn('اضبط القيمةَ والمصبّ', 'rs-btn soft', () => setForm(p, box, plan, items)),
      btn(p['مخفيّة'] ? 'أظهِرها لمادّتي' : 'أخفِها عن مادّتي', 'rs-btn ghost', () => act('v2_plan_practice_hide', { p_plan: plan, p_code: p['الكود'], p_hidden: !p['مخفيّة'] }, 'إخفاء الممارسة', box, plan)));
    // الإرجاعُ لأصل المدرسة لما أُضيف إلى القائمة — وما صنعه هو لا أصلَ له يُرجع إليه
    if (p['أصلها'] !== 'مادّتي') row.appendChild(btn('أرجِعها لأصل المدرسة', 'rs-btn ghost', () => act('v2_plan_practice_reset', { p_plan: plan, p_code: p['الكود'] }, 'إرجاع الممارسة', box, plan)));
    f.appendChild(row);
    return f;
  }
  async function act(fn, args, label, box, plan) {
    const x = await M.rpc(fn, args, label);
    if (x.error) { V.flash('bad', errText(x.error)); return; }
    V.flash('ok', msg(x.data));
    panel(box, plan);
  }
  // القيمةُ مقدارٌ موجب — والاتّجاهُ من قطبيّة الممارسة · والمصبُّ بندٌ من بنود الممارسات في خطّته
  function setForm(p, box, plan, items) {
    const its = [...items.values()].map((x) => [x['رقم_البند'], x['البند'] || '', x['السلّة'] || '']);
    V.form({
      title: 'القيمةُ والمصبّ', what: [p['الممارسة'], POL[p['القطبيّة']]].filter(Boolean).join(' — '), ok: 'اضبطها',
      fields: [
        { key: 'points', type: 'number', label: 'القيمة — مقدارٌ بلا إشارة', value: p['قيمتي'] == null ? null : Number(p['قيمتي']), hint: p['القطبيّة'] === 'negative' ? 'سالبةٌ بقطبيّتها: تُنقص بهذا المقدار' : 'موجبةٌ بقطبيّتها: تُضيف بهذا المقدار' },
        its.length
          ? { key: 'item', type: 'choose', label: 'تصبُّ في', items: its, value: p['رقم_المصبّ'] || null }
          : { key: 'none', type: 'node', node: el('p', 'rs-meta', 'لا بندَ من الممارسات في توزيعك بعد — علّم بندًا «من الممارسات» في «بطاقة التوزيع» أوّلًا.') },
        { key: 'note', type: 'textarea', label: 'ملاحظتي (اختياريّة)', rows: 2, value: p['ملاحظتي'] || null },
      ],
      onOk: async (v) => {
        const x = await M.rpc('v2_plan_practice_set', { p_plan: plan, p_code: p['الكود'], p_points: v.points, p_item: v.item || null, p_note: v.note }, 'ضبط الممارسة');
        if (x.error) return x.error;
        V.flash('ok', msg(x.data));
        panel(box, plan); return null;
      },
    });
  }
  function addForm(box, plan, scopes) {
    V.form({
      title: 'ممارسةٌ لمادّتي', what: 'تُنشأ لمادّتك وحدَها، ثمّ تضبط قيمتَها ومصبَّها', ok: 'أنشئها',
      fields: [
        { key: 'title', label: 'الممارسة' },
        { key: 'pol', type: 'pick', label: 'القطبيّة', items: [['positive', 'موجبة'], ['negative', 'سالبة']] },
        { key: 'scope', type: 'choose', label: 'المجال', items: scopes },
        { key: 'once', type: 'pick', label: 'مرّةً في اليوم؟', items: [['yes', 'نعم'], ['no', 'لا']] },
        { key: 'tc', type: 'number', label: 'العتبة: عددُ المرّات (اختياريّ)' },
        { key: 'td', type: 'number', label: 'العتبة: خلال أيّام (اختياريّ)' },
        { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 },
      ],
      onOk: async (v) => {
        // «مرّةً في اليوم» لا يُرسل إن لم يُختر — فافتراضُه في الباب
        const args = Object.assign({ p_plan: plan, p_title: v.title, p_polarity: v.pol, p_scope: v.scope, p_threshold_count: v.tc, p_threshold_days: v.td, p_note: v.note }, v.once ? { p_once_per_day: v.once === 'yes' } : {});
        const x = await M.rpc('v2_plan_practice_add', args, 'إنشاء ممارسة');
        if (x.error) return x.error;
        V.flash('ok', msg(x.data));
        panel(box, plan); return null;
      },
    });
  }

  // ========== بطاقةُ الطالب في «صفّي»: ممارساتُ مادّتي للمادّة الجارية ==========
  // card_practices لا يعرف المادّة — فتُضمّ إليها ممارساتُ مادّته من v2_plan_practices (أصلُها «مادّتي» وغيرُ المخفيّة)
  // وخطّتُه للمادّة الجارية من v2_grade_my_subjects بالصفّ (grade_ar) والمادّة (subject_ar) · والرصدُ بـ v2_record_practice
  async function subjectPractices(grade_ar, subject_ar, positive) {
    if (!grade_ar || !subject_ar) return [];
    const g = await M.rpc('v2_grade_my_subjects', { p_school: M.state.school, p_term: null }, 'موادّي');
    const row = arr(g.data && g.data.rows).find((r) => r.grade_ar === grade_ar && r.subject_ar === subject_ar);
    if (!row || !row.plan_id) return [];
    const { data, error } = await M.rpc('v2_plan_practices', { p_plan: row.plan_id, p_scope: null, p_polarity: positive ? 'positive' : 'negative' }, 'ممارسات مادّتي');
    if (error) return [];
    return arr(data).filter((p) => p['أصلها'] === 'مادّتي' && !p['مخفيّة']);
  }
  function recordForm(p, student, period, subject, done) {
    V.form({
      title: p['الممارسة'] || '', what: 'من ممارسات مادّتي', ok: 'ارصدها',
      fields: [{ key: 'n', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 }],
      onOk: async (v) => {
        const x = await M.rpc('v2_record_practice', { p_student: student, p_code: p['الكود'], p_period: period, p_subject: subject, p_note: v.n || null }, 'رصد ممارسة');
        if (x.error) return x.error;
        V.flash('ok', msg(x.data));
        if (done) done(); return null;
      },
    });
  }

  window.MoayadMumarasa = { panel, practiceItems, markForm, unmarkForm, markCell, studentBox, subjectPractices, recordForm };
})();
