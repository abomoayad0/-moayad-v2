// مؤيّد · لوحة الأخطاء — للمالك وإدارة المدرسة (view_errors).
// v2_errors(p_days, p_kind) · v2_error_fixed(p_id, p_note)
// error: عطب يُصلَح · guard: حارس عمل كما يجب فلا يُصلَح.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;

  const ui = { days: 7, kind: '', rows: [] };
  const KIND_AR = { error: 'عطب', guard: 'حارس' };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  async function refresh() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_errors', { p_days: ui.days, p_kind: ui.kind || null }, 'لوحة الأخطاء');
    if (error) { showLoadErr('تعذّر جلب الأخطاء: ' + errText(error)); ui.rows = []; render(); return; }
    ui.rows = data || [];
    render();
  }

  function render() {
    $('errTitle').textContent = ui.rows.length + ' سجلّاً';
    const box = $('errs');
    box.textContent = '';
    if (ui.rows.length === 0) { box.appendChild(el('div', 'empty', 'لا أخطاء في هذه المدة.')); return; }
    for (const r of ui.rows) {
      const c = el('div', 'ev err-row k-' + r.kind + (r.fixed ? ' fixed' : ''));
      const top = el('div', 'row1');
      const when = el('div', 'meta');
      when.append(M.ltr(new Date(r.at).toLocaleString('en-GB', { hour12: false })));
      top.append(when, el('span', 'badge ' + (r.kind === 'guard' ? 'b-permitted' : 'b-absent'),
        (KIND_AR[r.kind] || r.kind) + (r.times > 1 ? ' ×' + r.times : '')));
      c.appendChild(top);
      c.appendChild(el('div', 'name', r.message));
      c.appendChild(el('div', 'meta', [r.screen, r.action, r.fn_name, r.sqlstate].filter(Boolean).join(' · ')));
      c.appendChild(el('div', 'meta', [r.person_ar || 'مجهول', r.role_ar, r.school_ar].filter(Boolean).join(' · ')));
      if (r.params) {
        const d = el('details');
        d.append(el('summary', null, 'المعطيات'));
        const pre = el('pre', 'params');
        pre.textContent = JSON.stringify(r.params, null, 2);
        d.appendChild(pre);
        c.appendChild(d);
      }
      if (r.fixed) {
        c.appendChild(el('div', 'meta', '✓ أُصلح'));
      } else if (r.kind === 'error') {
        const acts = el('div', 'acts one');
        const b = el('button', 'a-accept', 'وسمه: أُصلح');
        b.type = 'button';
        b.addEventListener('click', () => markFixed(r));
        acts.appendChild(b);
        c.appendChild(acts);
      }
      box.appendChild(c);
    }
  }

  async function markFixed(r) {
    $('fixMsg').textContent = r.message;
    $('fixNote').value = '';
    if (await ask($('fixDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_error_fixed', { p_id: r.id, p_note: $('fixNote').value.trim() || null }, 'وسم خطأ أُصلح');
    if (error) { toast('لم يُوسم:\n' + errText(error)); return; }
    toast('وُسم: أُصلح.', true);
    await refresh();
  }

  function bindFilter(id, attr, key) {
    $(id).addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (!b) return;
      ui[key] = key === 'days' ? Number(b.dataset[attr]) : b.dataset[attr];
      for (const x of $(id).querySelectorAll('button')) x.setAttribute('aria-pressed', String(x === b));
      refresh();
    });
  }
  bindFilter('fDays', 'd', 'days');
  bindFilter('fKind', 'k', 'kind');

  M.start({ screen: 'errors', onChange: (why) => (why === 'enter' || why === 'role' ? refresh() : null) });
})();
