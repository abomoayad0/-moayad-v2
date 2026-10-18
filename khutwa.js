// مؤيّد · «ما يُنتظر منّي» لكلّ منسوب — تكليف ٣٧ (window.MoayadSteps)
// v2_card_my_steps(p_school) يعرف صاحبَه بنفسِه — فلا شرطَ صفةٍ عليه: من كُلِّف بخطوةٍ من لوحة التحكّم رآها
// ⇒ v2_card_step_do(p_step, p_note) · والجملُ (summary_ar · state_ar · note_ar) كما جاءت، ولا تاريخَ خامّ
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash } = V;

  // sum: عنصرُ الجملة · box: عنصرُ القائمة
  async function load(sum, box) {
    const { data, error } = await M.rpc('v2_card_my_steps', { p_school: M.state.school }, 'ما يُنتظر منّي');
    box.textContent = '';
    if (error) { sum.textContent = ''; box.appendChild(el('div', 'notice err', errText(error))); arabize(box); return; }
    const d = data || {};
    sum.textContent = d.summary_ar || '';
    for (const x of d.rows || []) {
      const f = el('div', 'rs-file' + (x.days_left < 0 ? ' rs-late' : ''));
      f.append(el('h5', null, (x.student_ar || '') + ' — ' + (x.title_ar || '')), el('p', 'rs-meta', x.state_ar || ''));
      const r = el('div', 'rs-row'); r.appendChild(btn('أنجزتُها', 'rs-btn', () => stepForm(x, () => load(sum, box)))); f.appendChild(r);
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize(sum.parentNode);
  }

  function stepForm(x, after) {
    V.form({
      title: 'إنجازُ خطوة', what: (x.student_ar ? x.student_ar + ' — ' : '') + (x.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ما فعلتَ', rows: 3 }],
      ok: 'أنجزتُها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_step_do', { p_step: x.step, p_note: v.n }, 'إنجاز خطوة');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg)) || ''); if (after) after(); return null;
      },
    });
  }

  window.MoayadSteps = { load };
})();
