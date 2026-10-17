// مؤيّد · خططُ درجات المدرسة عند الوكيل والمدير — تكليف ٢٧ (window.MoayadDarajat)
// v2_grade_plans_of(p_school, p_term) ⇒ رقم · المادة · الصف · الفصل · النوع · المعلّم · بنوده · نواقص · الحال · الحال_مفتاح · سبب_القفل · تنتهي_المهلة · خطّتي
// v2_grade_plan_unlock(p_plan, p_why) — بسببٍ مكتوب، والمهلةُ تنتهي وحدَها
// ولا زرَّ «أقفلْه الآن» — لا بابَ له: الإقفالُ باعتماد المعلّم أو بمضيّ المهلة · ولا زرَّ فتحٍ لصاحب الخطّة على خطّته
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash } = V;
  const kv = (f, k, v) => { if (v != null && v !== '') f.appendChild(el('p', null, k + ': ' + v)); };

  async function plansTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_grade_plans_of', { p_school: M.state.school, p_term: null }, 'خطط الدرجات');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'لا خططَ درجاتٍ في المدرسة بعد.')); return; }
    for (const r of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [r['المادة'], r['الصف']].filter(Boolean).join(' · ')));
      f.appendChild(el('p', r['الحال_مفتاح'] === 'opened' ? 'rs-orange' : null, r['الحال'] || ''));
      kv(f, 'المعلّم', r['المعلّم']);
      f.appendChild(el('p', 'rs-meta', [r['الفصل'], r['النوع']].filter(Boolean).join(' · ')));
      kv(f, 'بنوده', r['بنوده'] == null ? null : V.ar(r['بنوده']));
      kv(f, 'نواقص', r['نواقص'] == null ? null : V.ar(r['نواقص']));
      if (r['سبب_القفل']) f.appendChild(el('p', 'rs-meta', r['سبب_القفل']));
      // الفتحُ للمعتمدة وحدَها · ولا يُعرض على صاحبها (خطّتي) — فالبابُ يردّه
      if (r['الحال_مفتاح'] === 'approved' && !r['خطّتي']) f.appendChild(btn('افتحْه للمعلّم', 'rs-btn soft', () => unlockForm(r, box)));
      box.appendChild(f);
    }
    arabize(box);
  }

  function unlockForm(r, box) {
    V.form({
      title: 'افتحْه للمعلّم', what: [r['المادة'], r['الصف'], r['المعلّم']].filter(Boolean).join(' · '),
      fields: [{ key: 'why', type: 'textarea', label: 'لماذا تفتحُ هذا التوزيع؟ (عشرةُ أحرفٍ على الأقلّ، وبأرقامٍ عربيّة)', rows: 3 }],
      ok: 'افتحْه',
      onOk: async (v) => {
        // تنبيهٌ قبل الإرسال — والقاعدةُ تردّ أيضًا
        if (/[0-9]/.test(v.why || '')) return 'الأرقامُ تُكتبُ عربيّةً في سببِ الفتح';
        const { data, error } = await M.rpc('v2_grade_plan_unlock', { p_plan: r['رقم'], p_why: v.why }, 'فتح توزيع الدرجات');
        if (error) return error;
        await plansTool(box);
        flash('ok', (data && data['البيان']) || '');
        return null;
      },
    });
  }

  window.MoayadDarajat = { plansTool };
})();
