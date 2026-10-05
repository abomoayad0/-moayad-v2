// مؤيّد · لوحة التحكّم — أبوابُ الإعداد كما فهرستها القاعدة.
// v2_settings_catalog · v2_committee_board · v2_committee_quorum · v2_committee_seat_count
// المقفلُ يُقرأ بسببه وسنده ولا زرَّ تعديلٍ عليه. ومن يدخل اللوحة تحكم به القاعدة، ورفضُها يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'panel';

  // مفاتيح اللجان كما في المواصفة — وأسماؤها ونصابُها من v2_committee_board
  const COMMITTEES = ['guidance', 'admin', 'achievement', 'excellence', 'fund', 'safety', 'sped'];

  const ui = { catalog: [], school: null };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  // ---------- الأبواب ----------
  async function loadCatalog() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_settings_catalog', undefined, 'فهرس لوحة التحكّم');
    if (error) { showLoadErr(errText(error)); $('groups').textContent = ''; return; }
    ui.catalog = data || [];
    render();
  }

  function render() {
    const box = $('groups');
    box.textContent = '';
    // المجموعات بترتيب ورودها من القاعدة
    const groups = [];
    for (const r of ui.catalog) if (!groups.includes(r.group_ar)) groups.push(r.group_ar);
    for (const g of groups) {
      const card = el('section', 'panel pgroup');
      card.appendChild(el('h2', 'ph', g));
      for (const r of ui.catalog.filter((x) => x.group_ar === g)) card.appendChild(section(r));
      if (ui.catalog.some((x) => x.group_ar === g && x.key === 'committees')) {
        const c = el('div', 'ptool');
        c.id = 'committeeTool';
        card.appendChild(c);
      }
      box.appendChild(card);
    }
    loadCommittees();
  }

  function section(r) {
    const s = el('div', 'psec ' + (r.editable ? 'open' : 'locked'));
    const top = el('div', 'row1');
    top.append(el('div', 'name', (r.editable ? '✅ ' : '🔒 ') + r.label_ar),
      el('span', 'badge ' + (r.editable ? 'b-permitted' : 'b-absent'), r.rows_n == null ? '—' : r.rows_n + ' سجلّاً'));
    s.appendChild(top);
    if (!r.editable && r.locked_why) s.appendChild(el('div', 'detail red', r.locked_why));
    if (r.source_ar) s.appendChild(el('div', 'meta', 'السند: ' + r.source_ar));
    if (r.note_ar) s.appendChild(el('div', 'meta', r.note_ar));
    if (r.editable) {
      // لا جسرَ يقرأ صفوف الباب بعد، و v2_setting_update يطلب رقم الصفّ — فالزرّ ينتظره
      const b = el('button', 'btn-ghost wide', 'تعديل');
      b.type = 'button';
      b.disabled = true;
      s.append(b, el('div', 'meta nocan', 'التعديل ينتظر جسراً يقرأ صفوف هذا الباب من القاعدة.'));
    }
    return s;
  }

  // ---------- اللجان: النصاب وسعة المقعد المنتخَب ----------
  async function loadCommittees() {
    const box = $('committeeTool');
    if (!box || !ui.school) return;
    box.textContent = '';
    box.appendChild(el('h3', 'grp', 'النصاب وسعة المقاعد'));
    const res = await Promise.all(COMMITTEES.map((k) =>
      M.rpc('v2_committee_board', { p_school: ui.school, p_committee: k }, 'مجلس اللجنة')));
    res.forEach((r, i) => {
      const row = el('div', 'ev');
      if (r.error) { row.appendChild(el('div', 'notice err', COMMITTEES[i] + ': ' + errText(r.error))); box.appendChild(row); return; }
      const b = r.data || {};
      const c = b.committee || {};
      row.appendChild(el('div', 'name', c.label || COMMITTEES[i]));
      row.appendChild(el('div', 'meta', c.quorum == null ? 'لم يُحدَّد نصابٌ بعد' : 'النصاب: ' + c.quorum));
      if (c.quorum_note) row.appendChild(el('div', 'meta', c.quorum_note));
      const acts = el('div', 'acts one');
      const q = el('button', 'a-go', 'اضبط النصاب');
      q.type = 'button';
      q.addEventListener('click', () => setQuorum(c));
      acts.appendChild(q);
      row.appendChild(acts);
      // المقعد المنتخَب وحدَه تُعدَّل سعته — وما هو المنتخَب من القاعدة (elected)
      for (const s of (b.seats || []).filter((x) => x.elected)) {
        const line = el('div', 'meta', (s.role_ar || '') + ' — منتخَب: ' + (s.holders || []).length + ' من ' + s.count);
        row.appendChild(line);
        const sb = el('button', 'btn-ghost wide', 'غيّر سعة «' + (s.role_ar || '') + '»');
        sb.type = 'button';
        sb.addEventListener('click', () => setSeatCount(c, s));
        row.appendChild(sb);
      }
      box.appendChild(row);
    });
  }

  async function setQuorum(c) {
    $('qWhat').textContent = c.label || c.key;
    $('qNow').textContent = c.quorum == null ? 'لم يُحدَّد نصابٌ بعد' : 'النصاب الآن: ' + c.quorum;
    $('qMin').value = c.quorum == null ? '' : c.quorum;
    $('qNote').value = '';
    if (await ask($('quorumDlg')) !== 'ok') return;
    const v = $('qMin').value.trim();
    const { error } = await M.rpc('v2_committee_quorum',
      { p_committee: c.key, p_min: v === '' ? null : Number(v), p_note: $('qNote').value.trim() || null }, 'ضبط النصاب');
    if (error) { toast('لم يُضبط النصاب:\n' + errText(error)); return; }
    toast('ضُبط نصاب ' + (c.label || c.key) + '.', true);
    loadCommittees();
  }

  async function setSeatCount(c, s) {
    $('sWhat').textContent = (c.label || c.key) + ' · ' + (s.role_ar || '') + ' — السعة الآن ' + s.count;
    $('sCount').value = s.count;
    $('sReason').value = '';
    $('sOk').disabled = true;
    if (await ask($('seatDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_committee_seat_count', {
      p_committee: c.key, p_seat_role: s.role, p_count: Number($('sCount').value), p_reason: $('sReason').value.trim(),
    }, 'تعديل سعة مقعد');
    if (error) { toast('لم تُعدَّل السعة:\n' + errText(error)); return; }
    toast('عُدّلت السعة.', true);
    loadCommittees();
  }

  $('sReason').addEventListener('input', () => { $('sOk').disabled = $('sReason').value.trim() === ''; });
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  // ---------- الدخول ----------
  async function enter() {
    let me;
    try { await M.defaultRole(); me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    M.state.me = me;
    M.renderHeader(me, async (r) => { const m = await M.actAs(r); if (m) enter(); });
    M.renderNav(me, 'panel');
    if (!me) { M.gate('حسابك غير مسند إلى منسوب في مؤيّد.'); return; }
    // مدرسة الصفة النافذة — لعرض شاغلي المقاعد
    const cur = (me.roles || []).find((r) => r.is_current === true && r.school_id);
    const schools = (me.schools || []).filter((x) => !cur || x.id === cur.school_id);
    ui.school = schools.length ? schools[0].id : null;
    $('panelView').hidden = false;
    await loadCatalog();
  }

  (async () => {
    const { data } = await M.sb.auth.getSession();
    if (!data.session) { location.replace('./'); return; }
    await enter();
  })();
})();
