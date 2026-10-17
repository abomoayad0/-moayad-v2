// مؤيّد · لوحةُ أوزانِ الممارسات — تكليف ٢٦ (window.MoayadAwzan)
// v2_practice_weights() بلا وسائط (المدرسةُ من الصفة) ⇒ rows · rules_ar · note_ar · rules
// v2_practice_weight_save(p_code, p_points, p_day_cap, p_active, p_note) — والبابُ يردُّ ما تجاوز حدودَه برسالته
// الرمزُ لاتينيٌّ كما هو (مفتاحُ الحفظ) · والوزنُ من weight_ar لا من points · والسالبةُ عتباتٌ لا خصم
// وليس هنا: إخفاءُ الممارسات (v2_practices_hidden) ولا إضافتُها (v2_practice_save)
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash, typed } = V;

  const TABS = [['positive', 'الموجبة'], ['negative', 'السالبة']];
  const NEG_NOTE = 'هذي عتباتٌ لا خصم. أوزانُها صفرٌ حتّى تضعَ المدرسةُ وزنًا إن أرادت.';
  // وزنُ الفهرس رقمًا ⇒ بالعربيّ وفاصلتِه «٠٫٥» — تحويلُ أرقامٍ لا حساب
  const num = (v) => V.ar(String(v == null ? '' : v)).replace('.', '٫');

  // opts: { polarity, q } — يُفتح بهما (لوحةُ الشكوى تفتحه على السالبة والبحثُ بالرمز)
  async function tool(box, opts) {
    const st = { polarity: (opts && opts.polarity) || 'positive', q: (opts && opts.q) || '' };
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_practice_weights', undefined, 'أوزان الممارسات');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    const rows = d.rows || [];
    // الحرّاسُ الثلاثة بارزةٌ فوق اللوحة · وسطرُ البيان تحتها
    if (d.rules_ar) box.appendChild(el('div', 'rs-said', d.rules_ar));
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    const tabs = el('div', 'rs-pick');
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث بالاسم أو الرمز'; q.value = st.q;
    q.setAttribute('aria-label', 'بحث في الممارسات');
    const neg = el('p', 'rs-note', NEG_NOTE);
    const list = el('div');
    box.append(tabs, neg, q, list);
    const draw = () => {
      neg.hidden = st.polarity !== 'negative';
      list.textContent = '';
      const t = q.value.trim().toLowerCase();
      let n = 0;
      for (const r of rows) {
        if (r.polarity !== st.polarity) continue;
        if (t && !((r.title_ar || '') + ' ' + (r.code || '')).toLowerCase().includes(t)) continue;
        n++;
        list.appendChild(row(r, box, st));
      }
      if (!n) list.appendChild(el('p', 'rs-empty', 'لا نتائج.'));
      arabize(list);
    };
    V.pick(tabs, TABS, st.polarity, (v) => { st.polarity = v; draw(); });
    q.addEventListener('input', () => { st.q = q.value; draw(); });
    draw();
  }

  function row(r, box, st) {
    const f = el('div', 'rs-file');
    f.appendChild(el('h5', null, r.title_ar || ''));
    // الرمزُ لاتينيٌّ صغيرٌ تحت الاسم — لا يُعرَّب
    f.appendChild(typed(r.code || '', 'small', 'rs-meta'));
    f.appendChild(el('p', null, [r.weight_ar, r.effect_ar].filter(Boolean).join(' · ')));
    const tag = el('p', 'rs-meta');
    tag.appendChild(el('span', 'rs-tag', r.is_school ? 'وزنُ المدرسة' : 'وزنُ الفهرس'));
    if (r.is_school) tag.appendChild(document.createTextNode(' وزنُ الفهرس: ' + num(r.catalogue_points)));
    f.appendChild(tag);
    const acts = el('div', 'rs-row');
    acts.appendChild(btn('عدّلْ وزنَه', 'rs-btn soft', () => edit(r, box, st)));
    if (r.is_school) acts.appendChild(btn('أعِدْه إلى وزنِ الفهرس', 'rs-btn ghost', () => save(r, { p_points: r.catalogue_points, p_day_cap: r.day_cap }, box, st)));
    f.appendChild(acts);
    return f;
  }

  function edit(r, box, st) {
    V.form({
      title: r.title_ar || '', what: r.code || '',
      fields: [
        { key: 'points', type: 'number', label: 'الوزن', value: r.points },
        { key: 'cap', type: 'number', label: 'سقفُ اليوم لهذي الممارسة (اختياريّ)', value: r.day_cap },
        { key: 'note', type: 'textarea', label: 'ملاحظة (اختياريّة)' },
      ],
      ok: 'احفظ',
      onOk: async (v) => save(r, { p_points: v.points, p_day_cap: v.cap, p_note: v.note }, box, st, true),
    });
  }

  async function save(r, args, box, st, inForm) {
    const { data, error } = await M.rpc('v2_practice_weight_save', Object.assign({ p_code: r.code }, args), 'حفظ وزن ممارسة');
    if (error) { if (inForm) return error; flash('bad', errText(error)); return null; }
    await tool(box, st);
    flash('ok', Object.values(data || {}).filter((x) => typeof x === 'string').join(' · ') || 'حُفظ');
    return null;
  }

  window.MoayadAwzan = { tool };
})();
