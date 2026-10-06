// مؤيّد · شاشة رائد النشاط — viewA في المحاكي: دوري · إقرارُ المشاركات · فرصٌ أقيمها.
// الإقرارُ ضغطةٌ واحدةٌ على الحكم بعد الملاحظة — بلا نافذة؛ والإحالةُ تحتاج حقولًا فلوحٌ منزلق.
// v2_entries_pending · v2_entry_verdict · v2_entry_delegate · v2_opps_list · v2_staff_list
// والقاعدةُ تحكم: من يقرّ، وإلزامُ الملاحظة، والحكمُ أربعةٌ لا غير — ورفضُها يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash } = V;

  const BUCKET = 'v2-attachments';
  // الأحكامُ الأربعة كما يقبلها v2_entry_verdict — والقاعدةُ ترفض غيرها
  const VERDICTS = ['نفّذ', 'نفّذ جزئيًّا', 'لم ينفّذ', 'لم يحضر'];
  const ui = { pending: [], staff: null, busy: false };

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    ui.staff = null;
    await Promise.all([loadPending(), loadMine()]);
  }

  async function openEvidence(path) {
    const { data, error } = await M.sb.storage.from(BUCKET).createSignedUrl(path, 300);
    if (error) { flash('bad', errText(error)); return; }
    window.open(data.signedUrl, '_blank', 'noopener');
  }

  // ---------- ② إقرارُ المشاركات ----------
  async function loadPending() {
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: M.state.school }, 'ما ينتظر الإقرار');
    const box = $('pending');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    ui.pending = data || [];
    if (!ui.pending.length) { box.appendChild(el('p', 'rs-meta', 'لا مشاركاتِ تنتظر إقرارك.')); return; }
    for (const x of ui.pending) box.appendChild(entryCard(x));
    arabize(box);
  }

  function entryCard(x) {
    const f = el('div', 'rs-file');
    f.append(el('h5', null, (x.student || '') + ' — ' + (x.merit || '')),
      el('p', null, [x.when, x.delegated_to_me ? 'أُحيلت إليك' + (x.delegate_note ? ': ' + x.delegate_note : '') : null].filter(Boolean).join(' · ')));
    // ما كتبه الطالبُ وشاهدُه قبل أزرار الحكم
    const lg = el('div', 'rs-lgd');
    lg.append(el('i', 'k', 'ما كتبه:'), el('i', null, x.what || '—'), el('i', 'k', 'الشاهد:'), el('i', null, x.evidence || '—'));
    f.appendChild(lg);
    if (x.evidence_path) f.appendChild(btn('افتح المرفق', 'rs-btn soft', () => openEvidence(x.evidence_path)));
    const l = el('label', null, 'ملاحظتُك (إلزاميّة)');
    const note = el('textarea');
    note.rows = 2;
    note.id = 'n_' + x.entry;
    l.htmlFor = note.id;
    f.append(l, note);
    const row = el('div', 'rs-row');
    for (const v of VERDICTS) row.appendChild(btn(v, 'rs-btn', () => verdict(x, v, note, f)));
    f.appendChild(row);
    f.appendChild(btn('أحِل الإقرارَ لغيرك', 'rs-btn ghost', () => delegate(x)));
    return f;
  }

  async function verdict(x, v, note, card) {
    if (ui.busy) return;
    ui.busy = true;
    for (const b of card.querySelectorAll('button')) b.disabled = true;
    flash('wait', 'يُسجَّل… ' + (x.student || '') + ' — ' + v);
    const { error } = await M.rpc('v2_entry_verdict', { p_entry: x.entry, p_verdict: v, p_note: note.value.trim() || null, p_file: null }, 'إقرار مشاركة');
    ui.busy = false;
    for (const b of card.querySelectorAll('button')) b.disabled = false;
    // رُفض ⇒ تبقى البطاقةُ بملاحظتها، ونصُّ الرفض كما هو
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', 'سُجّل الحكم: ' + (x.student || '') + ' — ' + v + ' · وتقدّر اللجنةُ درجتَه');
    loadPending();
    loadMine();
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
