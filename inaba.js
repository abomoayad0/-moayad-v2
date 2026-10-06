// مؤيّد · «الإنابة في الصفات» في لوحة التحكّم — فلا يتعطّل العملُ بغياب صاحب الصفة.
// v2_delegations_board · v2_delegate_add · v2_delegate_revoke · v2_posts_list · v2_staff_list
// 🔑 الحرّاسُ في القاعدة: لا إنابةَ بلا سببٍ مكتوب، ولا يُناب أحدٌ عن نفسه، ولا تتكرّر إنابةٌ قائمة، والإلغاءُ بسببٍ ولا حذف.
// والواجهةُ تعرض ما أرجعته القاعدة وترسل ما كُتب — ورفضُ القاعدة يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));
  const span = (d1, d2) => (d1 || '—') + ' ← ' + (d2 || 'حتى تُلغى');

  async function delegationsTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ جلب الإنابات…'));
    const { data, error } = await M.rpc('v2_delegations_board', { p_school: school() }, 'الإنابات');
    box.textContent = '';
    if (error) { errBox(box, error); return; }
    const b = data || {};
    const live = b.live || [];
    const past = b.past || [];
    const vacant = b.vacant || [];

    if (vacant.length) {
      box.appendChild(el('div', 'rs-label', 'صفاتٌ شاغرةٌ في هيكل المدرسة (' + vacant.length + ')'));
      box.appendChild(el('div', 'rs-meta', vacant.map((x) => x.post_ar || x.post).join(' · ')));
    }

    box.appendChild(el('div', 'rs-label', 'الإناباتُ النافذة (' + live.length + ')'));
    if (!live.length) box.appendChild(el('div', 'rs-meta', 'لا إنابةَ نافذةٌ اليوم.'));
    for (const d of live) {
      const c = el('div', 'rs-card');
      c.appendChild(el('b', null, (d.post_ar || d.post) + ' — ' + (d.to || '')));
      c.appendChild(el('div', 'rs-meta', 'عن: ' + (d.from || 'صفةٍ شاغرة') + ' · ' + span(d.starts, d.ends)));
      c.appendChild(el('div', 'rs-meta', 'السبب: ' + (d.reason || '—') + (d.letter ? ' · خطاب: ' + d.letter : '') + (d.by ? ' · أصدرها: ' + d.by : '')));
      c.appendChild(btn('ألغِ الإنابة', 'rs-btn soft', () => revokeForm(box, d)));
      box.appendChild(c);
    }
    box.appendChild(btn('أنِب في صفة', 'rs-btn', () => addForm(box, vacant)));

    if (past.length) {
      const det = el('details', 'rs-dt');
      det.appendChild(el('summary', null, 'إناباتٌ منتهيةٌ أو ملغاة (' + past.length + ')'));
      const dd = el('div', 'rs-dtb');
      for (const d of past) {
        const r = el('div', 'rs-meta');
        r.textContent = (d.post_ar || '') + ' — ' + (d.to || '') + ' · ' + span(d.starts, d.ends) + ' · ' + (d.reason || '') +
          (d.revoked_at ? ' · أُلغيت: ' + String(d.revoked_at).slice(0, 10) + (d.revoked_why ? ' — ' + d.revoked_why : '') : ' · انتهت مدّتها');
        dd.appendChild(r);
      }
      det.appendChild(dd);
      box.appendChild(det);
    }
    arabize(box);
  }

  async function addForm(box, vacant) {
    const [p, s] = await Promise.all([
      M.rpc('v2_posts_list', undefined, 'الوظائف'),
      M.rpc('v2_staff_list', { p_school: school() }, 'قائمة المنسوبين'),
    ]);
    if (p.error) { flash('bad', errText(p.error)); return; }
    if (s.error) { flash('bad', errText(s.error)); return; }
    const vac = new Set((vacant || []).map((x) => x.post));
    V.form({
      title: 'إنابةٌ في صفة',
      what: 'كلُّ فعلٍ يقع بها يُقيَّد أنّه بإنابة.',
      fields: [
        { key: 'post', type: 'choose', label: 'الصفة', items: (p.data || []).map((x) => [x.key, x.label, vac.has(x.key) ? 'شاغرة' : (x.kind || '')]) },
        { key: 'to', type: 'choose', label: 'المُناب', items: (s.data || []).map((x) => [x.person_id, x.name_ar, x.post_ar || x.roles_ar || '']) },
        { key: 'starts', type: 'date', label: 'من (فارغٌ = اليوم)' },
        { key: 'ends', type: 'date', label: 'إلى (فارغٌ = حتى تُلغى)' },
        { key: 'reason', type: 'textarea', label: 'السبب — غيابٌ أو إجازةٌ أو انتدابٌ أو خلوُّ الوظيفة', rows: 2 },
        { key: 'letter', label: 'رقمُ الخطاب (اختياري)' },
      ],
      ok: 'أنِب',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_delegate_add', {
          p_school: school(), p_post: v.post || null, p_to: v.to || null,
          p_starts: v.starts || null, p_ends: v.ends || null, p_reason: v.reason || null, p_letter: v.letter || null,
        }, 'الإنابة');
        if (error) return error;
        flash('ok', (data && data.note) || 'أُنيب');
        delegationsTool(box);
        return null;
      },
    });
  }

  function revokeForm(box, d) {
    V.form({
      title: 'إلغاءُ الإنابة',
      what: (d.post_ar || '') + ' — ' + (d.to || ''),
      fields: [{ key: 'why', type: 'textarea', label: 'السبب', rows: 2 }],
      ok: 'ألغِها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_delegate_revoke', { p_delegation: d.id, p_why: v.why || null }, 'إلغاء الإنابة');
        if (error) return error;
        flash('ok', (data && data.note) || 'أُلغيت الإنابة');
        delegationsTool(box);
        return null;
      },
    });
  }

  window.MoayadInaba = { delegationsTool };
})();
