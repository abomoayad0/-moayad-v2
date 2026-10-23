// مؤيّد · بيدِ مدرستِك — تكليف ٣٨ (window.MoayadMadrasa): سجلّاتُ الرعاية وأرقامُ المدرسة في لوحة التحكّم
// ① سجلّاتُ الرعاية: v2_care_kinds(p_school) ⇒ السجلّات [المفتاح · السجلّ · الترتيب · كيف · سرّي · ملاحظة · أصله · سنده · ضبطتْه_مدرستُك · مخفيّ · عددهم · عددُه_محجوب]
//    والمخفيُّ مشطوبٌ ومعه «أظهِره» · ولا عددَ يُعرض هنا — فلا صفرَ كاذبَ على السرّيّ
//    v2_care_kind_add(p_school, p_label, p_secret, p_note, p_ord) — ووضعُه «وسم» دائمًا · ويُرجع سنده
//    v2_care_kind_set(p_school, p_key, p_hidden, p_label, p_ord, p_note) — ولا مفتاحَ سرّيّةٍ هنا: السرّيُّ يبقى سرّيًّا
// ② أرقامُ المدرسة: v2_rules(p_school) ⇒ الأرقام [المفتاح · البند · القيمة · الأصل · الوحدة · أدنى · أقصى · المصدر · سنده · علّته · يُضبَط · ضبطتْه_مدرستُك]
//    v2_rule_set(p_school, p_key, p_value, p_why) — والمقفلُ يُعرض بسنده ولا يُخفى
//    v2_rule_reset(p_school, p_key) — «ارجعْ إلى الأصل» على ما يُرجَع وحدَه (تكليف ٣٩) · ورجعَ_في سطرٌ هادئ
// والرفضُ بنصّه · والبيانُ كما جاء · ولا تاريخَ خامّ (ضُبطَ_في لا يُعرض)
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));

  // ======================= ① سجلّاتُ الرعاية =======================
  async function careTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_care_kinds', { p_school: school() }, 'سجلّات الرعاية');
    box.textContent = '';
    if (error) { errBox(box, error); arabize(box); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    const top = el('div', 'rs-row');
    top.appendChild(btn('أضفْ سجلًّا', 'rs-btn pri', () => addForm(box)));
    box.appendChild(top);
    const rows = d['السجلّات'] || [];
    for (const k of rows) {
      // المخفيُّ يُعرض للقيادة مشطوبًا ليُعادَ إظهارُه — ولا يظهر في فهرس الموجّه (مخفيّ من الباب)
      const hid = k['مخفيّ'] === true;
      const f = el('div', 'rs-file' + (hid ? ' rs-prev' : ''));
      const h = el('h5', null);
      const nm = el('span', null, k['السجلّ'] || '');
      if (hid) nm.style.textDecoration = 'line-through';
      h.appendChild(nm);
      if (hid) h.appendChild(el('span', 'rs-tag', 'مخفيّ'));
      // أصلُه وسمًا: من المنتَج أم من قرار المدرسة · وما ضبطته المدرسةُ عليه علامة
      if (k['أصله']) h.appendChild(el('span', 'rs-tag' + (k['أصله'] === 'قرارُ مدرستِك' ? ' own' : ''), k['أصله']));
      if (k['ضبطتْه_مدرستُك']) h.appendChild(el('span', 'rs-tag own', 'ضبطتْه مدرستُك'));
      if (k['سرّي']) h.appendChild(el('span', 'rs-tag', 'سرّيّ'));
      f.appendChild(h);
      if (k['كيف']) f.appendChild(el('p', 'rs-meta', k['كيف']));
      if (k['ملاحظة']) f.appendChild(V.typed(k['ملاحظة'], 'p', 'rs-meta'));
      // سندُه لما أنشأته المدرسة (null للعامّ) — كما جاء، ولا شعارَ وزارة
      if (k['سنده']) f.appendChild(el('p', 'rs-meta', k['سنده']));
      const r = el('div', 'rs-row');
      if (hid) r.appendChild(btn('أظهِره', 'rs-btn soft', async () => { const e = await send(k, { p_hidden: false, p_label: null, p_ord: null, p_note: null }, box); if (e) flash('bad', errText(e)); }));
      else {
        r.appendChild(btn('اضبطْه', 'rs-btn soft', () => setForm(k, box)));
        r.appendChild(btn('أخفِه', 'rs-btn ghost', () => hideForm(k, box)));
      }
      f.appendChild(r);
      box.appendChild(f);
    }
    if (!rows.length) box.appendChild(el('p', 'rs-empty', 'لا سجلّاتِ رعاية.'));
    arabize(box);
  }

  function addForm(box) {
    V.form({
      title: 'سجلُّ رعايةٍ لمدرستِك', what: 'يُوسَمُ الطلّابُ فيه بيدِ الموجّه',
      fields: [
        { key: 'label', label: 'اسمُ السجلّ' },
        { key: 'secret', type: 'pick', label: 'السرّيّة', items: [[false, 'غيرُ سرّيّ'], [true, 'سرّيٌّ لا يراه إلّا الموجّه']], value: false },
        { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)', rows: 2 },
      ],
      ok: 'أنشئْه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_care_kind_add', { p_school: school(), p_label: v.label, p_secret: v.secret === true, p_note: v.note, p_ord: null }, 'إنشاء سجلّ رعاية');
        if (error) return error;
        const r = data || {};
        flash('ok', [r['البيان'], r['سنده']].filter(Boolean).join(' — '));
        careTool(box);
        return null;
      },
    });
  }

  function setForm(k, box) {
    V.form({
      title: 'ضبطُ سجلّ', what: k['السجلّ'] || '',
      fields: [
        { key: 'label', label: 'الاسم', value: k['السجلّ'] },
        { key: 'ord', type: 'number', label: 'الترتيب', value: k['الترتيب'] },
        { key: 'note', type: 'textarea', label: 'ملاحظة', rows: 2, value: k['ملاحظة'] },
      ],
      ok: 'احفظ',
      onOk: async (v) => send(k, { p_hidden: false, p_label: v.label, p_ord: v.ord, p_note: v.note }, box),
    });
  }

  function hideForm(k, box) {
    V.form({
      title: 'إخفاءُ سجلّ', what: k['السجلّ'] || '',
      fields: [{ key: 'n', type: 'node', node: el('p', null, 'يُخفى من فهرس الموجّه — ولا يُخفى سجلٌّ فيه طلّابٌ قائمون.') }],
      ok: 'أخفِه', okCls: 'rs-btn irrev',
      onOk: async () => send(k, { p_hidden: true, p_label: null, p_ord: null, p_note: null }, box),
    });
  }

  async function send(k, args, box) {
    const { data, error } = await M.rpc('v2_care_kind_set', Object.assign({ p_school: school(), p_key: k['المفتاح'] }, args), 'ضبط سجلّ رعاية');
    if (error) return error;
    flash('ok', (data && data['البيان']) || '');
    careTool(box);
    return null;
  }

  // ======================= ② أرقامُ المدرسة =======================
  // مجموعةً بمصدرها — والمصادرُ بترتيب ورودها من الباب
  async function rulesTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_rules', { p_school: school() }, 'أرقام المدرسة');
    box.textContent = '';
    if (error) { errBox(box, error); arabize(box); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    const rows = d['الأرقام'] || [];
    const groups = [];
    for (const r of rows) if (!groups.includes(r['المصدر'])) groups.push(r['المصدر']);
    for (const g of groups) {
      const dt = el('details', 'rs-dt');
      dt.appendChild(el('summary', null, g || '—'));
      const b = el('div', 'rs-dtb');
      for (const r of rows.filter((x) => x['المصدر'] === g)) b.appendChild(ruleRow(r, box));
      dt.appendChild(b);
      box.appendChild(dt);
    }
    if (!rows.length) box.appendChild(el('p', 'rs-empty', 'لا أرقام.'));
    arabize(box);
  }

  const unit = (r) => (r['الوحدة'] ? ' ' + r['الوحدة'] : '');
  function ruleRow(r, box) {
    const f = el('div', 'rs-file' + (r['يُضبَط'] ? '' : ' rs-prev'));
    f.appendChild(el('h5', null, (r['يُضبَط'] ? '' : '🔒 ') + (r['البند'] || '')));
    // ما ضبطته المدرسة: القيمةُ وأصلُها معًا
    const val = r['ضبطتْه_مدرستُك']
      ? String(r['القيمة']) + unit(r) + ' — وأصلُه ' + String(r['الأصل'])
      : String(r['القيمة'] == null ? '—' : r['القيمة']) + unit(r);
    const p = el('p', 'rs-big', val);
    if (r['ضبطتْه_مدرستُك']) p.appendChild(el('span', 'rs-tag own', 'ضبطتْه مدرستُك'));
    f.appendChild(p);
    // المقفلُ ظاهرٌ بسنده كاملًا — فله سندٌ لا أنّه مفقود
    if (r['سنده']) f.appendChild(el('p', r['يُضبَط'] ? 'rs-meta' : null, r['سنده']));
    if (r['علّته']) f.appendChild(V.typed(r['علّته'], 'p', 'rs-meta'));
    // رجعتْ عنه المدرسةُ إلى أصلِه: أثرٌ هادئٌ لا تنبيه (رجعَ_في) — وتاريخُه الخامُّ لا يُعرض
    if (r['رجعَ_في'] && !r['ضبطتْه_مدرستُك']) f.appendChild(el('p', 'rs-meta', 'رجعَ إلى أصلِه'));
    if (r['يُضبَط']) {
      const a = el('div', 'rs-row');
      a.appendChild(btn('اضبطْه', 'rs-btn soft', () => ruleForm(r, box)));
      // «ارجعْ إلى الأصل» على ما يُرجَع وحدَه (تكليف ٣٩) — v2_rule_reset، ولا يحذف صفًّا
      if (r['يُرجَع']) a.appendChild(btn('ارجعْ إلى الأصل', 'rs-btn ghost', () => resetForm(r, box)));
      f.appendChild(a);
    }
    return f;
  }

  function resetForm(r, box) {
    V.form({
      title: 'ارجعْ إلى الأصل', what: r['البند'] || '',
      fields: [{ key: 'n', type: 'node', node: el('p', null, 'الآن ' + r['القيمة'] + unit(r) + ' — ويرجعُ إلى ' + r['الأصل'] + unit(r)) }],
      ok: 'ارجعْ',
      onOk: async () => {
        const { data, error } = await M.rpc('v2_rule_reset', { p_school: school(), p_key: r['المفتاح'] }, 'الرجوع إلى الأصل');
        if (error) return error;
        flash('ok', (data && data['البيان']) || '');
        rulesTool(box);
        return null;
      },
    });
  }

  function ruleForm(r, box) {
    const lo = r['أدنى']; const hi = r['أقصى'];
    const range = [lo != null ? 'أدناه ' + lo : null, hi != null ? 'أقصاه ' + hi : null].filter(Boolean).join(' · ');
    V.form({
      title: r['البند'] || '', what: 'الآن ' + r['القيمة'] + unit(r) + ' — وأصلُه ' + r['الأصل'],
      fields: [
        { key: 'v', type: 'number', label: 'القيمة' + unit(r), value: r['القيمة'], hint: range || null },
        { key: 'why', type: 'textarea', label: 'السبب (اختياريّ)', rows: 2 },
      ],
      ok: 'احفظ',
      onOk: async (v) => {
        // حارسُ الواجهة بالحدّين — لئلّا يُرسَل ما يُردّ · وحارسُ القاعدة باقٍ
        if (v.v == null) return 'للرقمِ «' + r['البند'] + '» قيمةٌ تُكتَب';
        if (!Number.isInteger(v.v)) return 'القيمةُ عددٌ صحيح';
        if (lo != null && v.v < lo) return 'أدنى ما يُقبَلُ لـ«' + r['البند'] + '» هو ' + lo;
        if (hi != null && v.v > hi) return 'أقصى ما يُقبَلُ لـ«' + r['البند'] + '» هو ' + hi;
        const { data, error } = await M.rpc('v2_rule_set', { p_school: school(), p_key: r['المفتاح'], p_value: v.v, p_why: v.why }, 'ضبط رقم');
        if (error) return error;
        flash('ok', (data && data['البيان']) || '');
        rulesTool(box);
        return null;
      },
    });
  }

  window.MoayadMadrasa = { careTool, rulesTool };
})();
