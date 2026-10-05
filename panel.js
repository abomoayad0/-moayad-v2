// مؤيّد · لوحة التحكّم — أبوابُ الإعداد كما فهرستها القاعدة.
// v2_settings_catalog · v2_setting_rows · v2_setting_update · v2_committee_board · v2_committee_quorum · v2_committee_seat_count
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
    if (r.editable && r.own_bridge) {
      // الباب الحسّاس له جسره الخاصّ بحرّاسه — لا يُعدَّل من هنا
      s.appendChild(el('div', 'meta nocan', 'يُدار من جسره الخاصّ' + (r.bridge_ar ? ': ' + r.bridge_ar : '') + ' — لا من التعديل العامّ.'));
    } else if (r.editable) {
      const b = el('button', 'btn-ghost wide', 'تعديل');
      b.type = 'button';
      const rowsBox = el('div', 'prows');
      rowsBox.hidden = true;
      b.addEventListener('click', () => {
        rowsBox.hidden = !rowsBox.hidden;
        b.textContent = rowsBox.hidden ? 'تعديل' : 'أغلق';
        if (!rowsBox.hidden) openRows(r, rowsBox);
      });
      s.append(b, rowsBox);
    }
    return s;
  }

  // ---------- صفوف الباب: الأعمدة المسموحة وحدها كما أرجعتها القاعدة ----------
  function inputFor(v) {
    const c = document.createElement('input');
    if (typeof v === 'boolean') { c.type = 'checkbox'; c.checked = v; return c; }
    if (typeof v === 'number') { c.type = 'number'; c.value = String(v); return c; }
    c.type = typeof v === 'string' && /^\d\d:\d\d(:\d\d)?$/.test(v) ? 'time' : 'text';
    if (c.type === 'time') c.step = 60;
    c.value = v == null ? '' : String(v);
    return c;
  }
  function valueOf(c, orig) {
    if (c.type === 'checkbox') return c.checked;
    const v = c.value.trim();
    if (c.type === 'number') return v === '' ? null : Number(v);
    if (c.type === 'time' && typeof orig === 'string' && orig.length === 8 && v.length === 5) return v + ':00';
    return v === '' ? null : v;
  }

  async function openRows(r, box) {
    box.textContent = '';
    box.appendChild(el('div', 'meta', 'جارٍ جلب الصفوف…'));
    const { data, error } = await M.rpc('v2_setting_rows', { p_key: r.key, p_school: ui.school }, 'صفوف ' + r.label_ar);
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const cols = (data && data.cols) || [];
    const rows = (data && data.rows) || [];
    const labels = (data && data.cols_ar) || {};
    if (!rows.length) { box.appendChild(el('div', 'empty', 'لا صفوف.')); return; }
    for (const row of rows) {
      // معرّف الصفّ في __id (وفي id قديماً) — وما سوى الأعمدة المسموحة سياقٌ يُقرأ ولا يُكتب
      const rid = row.__id != null ? row.__id : row.id;
      const card = el('div', 'prow');
      const ctx = Object.keys(row).filter((k) => k !== '__id' && k !== 'id' && !cols.includes(k));
      if (ctx.length) {
        card.appendChild(el('div', 'pctx', ctx.map((k) => (labels[k] || k) + ': ' + (row[k] == null ? '—' : row[k])).join(' · ')));
      }
      const ctl = {};
      for (const k of cols) {
        const lab = el('label', null, labels[k] || k);
        const c = inputFor(row[k]);
        c.id = 'pr_' + rid + '_' + k;
        lab.htmlFor = c.id;
        ctl[k] = c;
        card.append(lab, c);
      }
      const save = el('button', 'btn-accept wide', 'احفظ هذا الصفّ');
      save.type = 'button';
      save.addEventListener('click', async () => {
        // يُرسل ما تغيّر وحده
        const patch = {};
        for (const k of cols) {
          const v = valueOf(ctl[k], row[k]);
          if (v !== row[k] && !(v == null && row[k] == null)) patch[k] = v;
        }
        if (!Object.keys(patch).length) { toast('لم يتغيّر شيء في هذا الصفّ.'); return; }
        const { error: e2 } = await M.rpc('v2_setting_update', { p_key: r.key, p_id: String(rid), p_patch: patch }, 'تعديل ' + r.label_ar);
        if (e2) { toast('لم يُحفظ:\n' + errText(e2)); return; }
        toast('حُفظ في «' + r.label_ar + '».', true);
        openRows(r, box);
      });
      card.appendChild(save);
      box.appendChild(card);
    }
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
      { p_school: ui.school, p_committee: c.key, p_min: v === '' ? null : Number(v), p_note: $('qNote').value.trim() || null }, 'ضبط النصاب');
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
      p_school: ui.school, p_committee: c.key, p_seat_role: s.role, p_count: Number($('sCount').value), p_reason: $('sReason').value.trim(),
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
