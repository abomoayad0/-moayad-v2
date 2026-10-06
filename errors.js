// مؤيّد · لوحةُ الأخطاء — على نموذج المحاكي. للمالك وإدارة المدرسة (view_errors).
// v2_errors(p_days, p_kind) · v2_error_fixed(p_id, p_note)
// error: عطبٌ يُصلَح · guard: حارسٌ عمل كما يجب فلا يُصلَح.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, pick } = V;

  const ui = { days: 7, kind: '', rows: [] };
  const KIND_AR = { error: 'عطب', guard: 'حارس' };
  const DAYS = [[1, 'اليوم'], [7, 'أسبوع'], [30, 'شهر']];
  const KINDS = [['', 'الكلّ'], ['error', 'أعطاب'], ['guard', 'حرّاس']];

  function filters() {
    pick($('fDays'), DAYS, ui.days, (v) => { ui.days = v; filters(); refresh(); });
    pick($('fKind'), KINDS, ui.kind, (v) => { ui.kind = v; filters(); refresh(); });
  }

  async function refresh() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_errors', { p_days: ui.days, p_kind: ui.kind || null }, 'لوحة الأخطاء');
    if (error) { showLoadErr('تعذّر جلب الأخطاء: ' + errText(error)); ui.rows = []; render(); return; }
    ui.rows = data || [];
    render();
  }

  function render() {
    V.renderRole();
    $('errTitle').textContent = ui.rows.length + ' سجلًّا';
    const box = $('errs');
    box.textContent = '';
    if (!ui.rows.length) box.appendChild(el('p', 'rs-empty', 'لا أخطاءَ في هذه المدّة.'));
    for (const r of ui.rows) {
      const f = el('div', 'rs-file' + (r.fixed ? ' rs-off' : ''));
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, r.message), el('span', 'rs-who ' + (r.kind === 'guard' ? 'rs-state-done' : 'rs-state-open'), (KIND_AR[r.kind] || r.kind) + (r.times > 1 ? ' ×' + r.times : '')));
      f.appendChild(hd);
      f.appendChild(el('p', null, [r.at_ar || r.at_h || r.at, r.screen, r.action].filter(Boolean).join(' · ')));
      f.appendChild(el('p', 'rs-meta', [r.person_ar || 'مجهول', r.role_ar, r.school_ar].filter(Boolean).join(' · ')));
      const tech = [r.fn_name, r.sqlstate].filter(Boolean).join(' · ');
      if (tech || r.params) {
        const d = el('details', 'rs-dt');
        d.appendChild(el('summary', null, 'التفاصيلُ التقنيّة'));
        const body = el('div', 'rs-dtb');
        if (tech) body.appendChild(el('div', null, tech));
        if (r.params) { const pre = el('pre', 'params'); pre.textContent = JSON.stringify(r.params, null, 2); body.appendChild(pre); }
        d.appendChild(body);
        f.appendChild(d);
      }
      if (r.fixed) f.appendChild(el('p', 'rs-meta', '✓ أُصلح'));
      else if (r.kind === 'error') f.appendChild(btn('وسمُه: أُصلح', 'rs-btn soft', () => fixForm(r)));
      box.appendChild(f);
    }
    // الأرقامُ عربيّةٌ إلا المعطياتُ التقنيّة فتبقى كما رجعت
    for (const n of box.querySelectorAll('.rs-hd, p')) arabize(n);
    arabize($('errTitle'));
  }

  function fixForm(r) {
    V.form({
      title: 'وسمُ الخطأ: أُصلح', what: r.message,
      fields: [{ key: 'note', type: 'textarea', label: 'ما الذي أُصلح (اختياريّ)' }],
      ok: 'أُصلح',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_error_fixed', { p_id: r.id, p_note: v.note || null }, 'وسم خطأ أُصلح');
        if (error) return error;
        V.flash('ok', 'وُسم: أُصلح');
        await refresh();
        return null;
      },
    });
  }

  filters();
  M.start({ screen: 'errors', onChange: (why) => (why === 'enter' || why === 'role' ? refresh() : null) });
})();
