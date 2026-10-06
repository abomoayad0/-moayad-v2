// مؤيّد · شاشة رائد النشاط — viewA في المحاكي: دوري · إقرارُ المشاركات · فرصٌ أقيمها.
// الإقرارُ ضغطةٌ واحدةٌ على الحكم بعد الملاحظة — بلا نافذة؛ والإحالةُ تحتاج حقولًا فلوحٌ منزلق.
// v2_entries_pending · v2_entry_verdict · v2_entry_delegate · v2_opps_list · v2_staff_list
// والقاعدةُ تحكم: من يقرّ، وإلزامُ الملاحظة، والحكمُ أربعةٌ لا غير — ورفضُها يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, flash } = V;

  const ui = { pending: [], staff: null };

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    ui.staff = null;
    await Promise.all([loadPending(), loadMine()]);
  }

  // ---------- ② إقرارُ المشاركات ----------
  async function loadPending() {
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: M.state.school }, 'ما ينتظر الإقرار');
    const box = $('pending');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    ui.pending = data || [];
    if (!ui.pending.length) { box.appendChild(el('p', 'rs-meta', 'لا مشاركاتِ تنتظر إقرارك.')); return; }
    for (const x of ui.pending) box.appendChild(V.verdictCard(x, { onDone: () => { loadPending(); loadMine(); }, onDelegate: delegate }));
    arabize(box);
  }

  async function delegate(x) {
    if (!ui.staff) {
      const { data, error } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
      if (error) { flash('bad', errText(error)); return; }
      ui.staff = data || [];
    }
    V.form({
      title: 'إحالةُ الإقرار', what: (x.student || '') + ' — ' + (x.merit || ''),
      fields: [
        { key: 'to', type: 'choose', label: 'إلى من حضر الفرصة', items: ui.staff.map((p) => [p.person_id, p.name_ar, p.post_ar || p.roles_ar || '']) },
        { key: 'note', type: 'textarea', label: 'السبب', rows: 2 },
      ],
      ok: 'أحِلها',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_entry_delegate', { p_entry: x.entry, p_person: v.to, p_note: v.note }, 'إحالة الإقرار');
        if (error) return error;
        flash('ok', 'أُحيل الإقرار');
        loadPending();
        return null;
      },
    });
  }

  // ---------- ③ فرصٌ أقيمها ----------
  async function loadMine() {
    const { data, error } = await M.rpc('v2_opps_list', { p_school: M.state.school, p_state: null, p_days: 180 }, 'بنك الفرص');
    const box = $('mine');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const me = M.state.me && M.state.me.person_id;
    const mine = (data || []).filter((o) => o.held_by_id === me);
    if (!mine.length) { box.appendChild(el('p', 'rs-meta', 'لا فرصَ أُسندت إليك — تفتحها اللجنةُ وتسندها إليك.')); return; }
    for (const o of mine) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (o.title || o.merit || '') + ' — ' + (o.state || '')),
        el('p', null, [o.when, o.points_note, o.source].filter(Boolean).join(' · ')),
        el('p', null, 'المسجّلون ' + o.joined + (o.capacity ? ' من ' + o.capacity : '') + ' · رفعوا ' + o.filed + ' · أقررتَ ' + o.verdicted + ' · قدّرت اللجنةُ ' + o.graded));
      if (o.close_why) f.appendChild(el('p', null, 'سببُ الإغلاق: ' + o.close_why));
      box.appendChild(f);
    }
    arabize(box);
  }

  M.start({ screen: 'raed', onChange: () => refresh() });
})();
