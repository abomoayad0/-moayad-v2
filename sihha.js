// مؤيّد · السجلُّ الصحّيّ — تكليف ٣٩: v2_health_register(p_school)
// ⇒ الجملة · الطلّاب · الحرجة · تحتاجُ_مراجعة · منتهية · مدّةُ_المراجعة · بحسبِ_النوع · أنا_الموجّهُ_الصحّيّ · الأسماءُ_محجوبة · الحالات · البيان
// وجهان: الموجّهُ الصحّيُّ يرى «الحالات» بأسمائها والحرجُ أوّلًا (الترتيبُ من الباب — لا يُعاد) · والقيادةُ تأتيها null فلا جدولَ ينتظرها، وبيانُها كما جاء
// 🔴 والملاحظةُ الخاصّة لا تخرج لأحد — فلا حقلَ لها ولا طلب · والصفرُ صادقٌ لا عطب، والحالةُ الفارغةُ كالمملوءة
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { ar, arabize } = V;

  async function refresh() {
    if (!M.state.school) return;
    V.renderRole();
    showLoadErr('');
    const box = $('reg');
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_health_register', { p_school: M.state.school }, 'السجلّ الصحّيّ');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); arabize(box); return; }
    const d = data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    // العدّاداتُ بألفاظ مفاتيحها كما جاءت
    const c = el('p', 'rs-meta', [['الحرجة', 'الحرجة'], ['تحتاجُ_مراجعة', 'تحتاجُ مراجعة'], ['منتهية', 'منتهية']]
      .filter(([k]) => d[k] != null).map(([k, t]) => t + ' ' + ar(d[k])).join(' · '));
    box.appendChild(c);
    // بحسب النوع — كلُّ نوعٍ فعّالٍ ولو بصفر
    const kinds = d['بحسبِ_النوع'] || [];
    if (kinds.length) {
      box.appendChild(el('div', 'rs-label', 'بحسبِ النوع'));
      const ul = el('ul', 'rs-acts');
      for (const k of kinds) {
        const li = el('li');
        const sp = el('span', null, k['النوع'] || ''); sp.style.flex = '1';
        li.append(sp, el('span', 'rs-tag', ar(k['العدد'] == null ? 0 : k['العدد'])));
        ul.appendChild(li);
      }
      box.appendChild(ul);
    }
    // الحالاتُ بأسمائها للموجّه الصحّيّ وحدَه — وnull للقيادة فلا يُبنى لها شيء
    const rows = d['الحالات'];
    if (Array.isArray(rows)) {
      box.appendChild(el('div', 'rs-label', 'الحالات'));
      for (const r of rows) {
        const f = el('div', 'rs-file' + (r['الانتباه'] === 'حرج' ? ' rs-late' : ''));
        const h = el('h5', null, [r['الطالب'], r['النوع']].filter(Boolean).join(' · '));
        if (r['الانتباه']) h.appendChild(el('span', 'rs-tag' + (r['الانتباه'] === 'حرج' ? ' own' : ''), r['الانتباه']));
        if (r['تحتاجُ_مراجعة']) h.appendChild(el('span', 'rs-tag', 'تحتاجُ مراجعة'));
        f.appendChild(h);
        if (r['العنوان']) f.appendChild(el('p', null, r['العنوان']));
        f.appendChild(el('p', 'rs-meta', [r['من'], r['إلى']].filter(Boolean).join(' — ')));
        box.appendChild(f);
      }
      if (!rows.length) box.appendChild(el('p', 'rs-meta', 'لا حالة.'));
    }
    arabize(box);
  }

  M.start({ screen: 'sihha', onChange: () => refresh() });
})();
