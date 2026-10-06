// مؤيّد · لوحة التحكّم — أبوابُ الإعداد كما فهرستها القاعدة.
// v2_settings_catalog · v2_setting_rows · v2_setting_update · v2_committee_board · v2_committee_quorum · v2_committee_seat_count
// v2_practices(p_school,…) · v2_practice_scopes · v2_practice_upsert · v2_practice_toggle · v2_practice_unfork · v2_scope_upsert
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
      // الباب الحسّاس له جسره الخاصّ بحرّاسه — لا يُعدَّل من التعديل العامّ
      s.appendChild(el('div', 'meta nocan', 'يُدار من جسره الخاصّ' + (r.bridge_ar ? ': ' + r.bridge_ar : '') + ' — لا من التعديل العامّ.'));
      const tool = OWN_TOOLS[r.key];
      if (tool) {
        const b = el('button', 'btn-ghost wide', 'افتح');
        b.type = 'button';
        const box = el('div', 'prows');
        box.hidden = true;
        b.addEventListener('click', () => {
          box.hidden = !box.hidden;
          b.textContent = box.hidden ? 'افتح' : 'أغلق';
          if (!box.hidden) tool(box);
        });
        s.append(b, box);
      }
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
    // المدرسةُ التي قرأت القاعدةُ صفوفَها — مدرسةُ الجلسة إن لم تُسمَّ
    if (data && data.school_ar) box.appendChild(el('div', 'meta', 'المدرسة: ' + data.school_ar));
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

  // ---------- ممارسات الصفّ ----------
  // ١٢٧ مشتركةً للمجمّع أصلٌ لا يُمسّ. والمدرسةُ تفصل نسختَها فتحجب الأصلَ عندها، فلا تزدوج.
  // والقاعدةُ تعرف بنفسها أيُّ الثلاثة يقع عند الحفظ: أُضيفت · عُدّلت · فُصلت لمدرستك — فلا نسأل المستخدم.
  const POLARITY_AR = { positive: 'إيجابيّة', negative: 'سلبيّة' };
  const KIND_AR = { practice: 'ممارسة', state: 'حالة' };
  const pr = { scope: '', polarity: '', scopes: [] };

  async function loadScopes() {
    const { data, error } = await M.rpc('v2_practice_scopes', { p_school: ui.school }, 'مجالات الممارسة');
    if (error) return { error };
    pr.scopes = data || [];
    return { data: pr.scopes };
  }

  function practicesFilters(box) {
    const bar = el('div', 'prow');
    const sl = el('label', null, 'المجال');
    const ss = document.createElement('select');
    ss.id = 'prScope';
    sl.htmlFor = ss.id;
    ss.appendChild(new Option('كلّ المجالات', ''));
    for (const s of pr.scopes) ss.appendChild(new Option(s.label, s.key));
    ss.value = pr.scope;
    const pl = el('label', null, 'النوع');
    const ps = document.createElement('select');
    ps.id = 'prPolarity';
    pl.htmlFor = ps.id;
    ps.append(new Option('الكلّ', ''), new Option('إيجابيّة', 'positive'), new Option('سلبيّة', 'negative'));
    ps.value = pr.polarity;
    ss.addEventListener('change', () => { pr.scope = ss.value; practicesTool(box); });
    ps.addEventListener('change', () => { pr.polarity = ps.value; practicesTool(box); });
    const add = el('button', 'btn-accept wide', 'أضف ممارسةً لمدرستي');
    add.type = 'button';
    add.addEventListener('click', () => editPractice(null, box));
    bar.append(sl, ss, pl, ps, add);
    return bar;
  }

  async function practicesTool(box) {
    box.textContent = '';
    if (!ui.school) { box.appendChild(el('div', 'notice err', 'لم تُحدَّد مدرستُك — بدّل صفتك إلى صفةٍ في مدرسة.')); return; }
    box.appendChild(el('div', 'meta', 'جارٍ جلب الممارسات…'));
    const sc = await loadScopes();
    const { data, error } = await M.rpc('v2_practices',
      { p_school: ui.school, p_scope: pr.scope || null, p_polarity: pr.polarity || null }, 'ممارسات الصفّ');
    box.textContent = '';
    if (sc.error) { box.appendChild(el('div', 'notice err', errText(sc.error))); return; }
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    box.appendChild(practicesFilters(box));
    const owned = rows.filter((p) => p.owned).length;
    box.appendChild(el('div', 'meta', rows.length + ' ممارسةً نافذة · منها ' + owned + ' مفصولةٌ لمدرستك'));
    if (!rows.length) { box.appendChild(el('div', 'empty', 'لا ممارسات.')); return; }
    let lastScope = null;
    for (const p of rows) {
      if (p.scope !== lastScope) {
        box.appendChild(el('h3', 'grp', p.scope_ar || p.scope));
        lastScope = p.scope;
      }
      box.appendChild(practiceRow(p, box));
    }
  }

  function practiceRow(p, box) {
    const row = el('div', 'ev');
    const top = el('div', 'row1');
    top.append(el('div', 'name', p.title),
      el('span', 'badge ' + (p.owned ? 'b-late' : 'b-permitted'), p.owned ? 'مفصولةٌ لمدرستك' : 'موحَّدةٌ للمجمّع'));
    row.appendChild(top);
    const bits = [POLARITY_AR[p.polarity] || p.polarity, KIND_AR[p.kind] || p.kind, 'النقاط: ' + p.points];
    if (p.zone) bits.push('الموضع: ' + p.zone);
    if (p.once_per_day) bits.push('مرّةً في اليوم');
    if (p.threshold_count) bits.push('الحدّ: ' + p.threshold_count + (p.threshold_days ? ' خلال ' + p.threshold_days + ' يومًا' : ''));
    if (p.escalate_to) bits.push('تُصعَّد إلى المخالفة ' + p.escalate_to);
    row.appendChild(el('div', 'meta', bits.join(' · ')));
    if (p.escalate_note) row.appendChild(el('div', 'meta', p.escalate_note));
    if (p.note) row.appendChild(el('div', 'meta', p.note));
    if (p.owned && p.based_on) row.appendChild(el('div', 'meta', 'أصلُها المشترك: ' + p.based_on));
    const acts = el('div', 'acts two');
    const ed = el('button', null, 'عدّل');
    ed.type = 'button';
    ed.addEventListener('click', () => editPractice(p, box));
    acts.appendChild(ed);
    if (!p.owned) {
      const f = el('button', null, 'افصلها لمدرستي');
      f.type = 'button';
      f.addEventListener('click', () => savePractice(p.code, p, box));
      acts.appendChild(f);
    } else if (p.based_on) {
      const u = el('button', null, 'أعدها للمشترك');
      u.type = 'button';
      u.addEventListener('click', () => unforkPractice(p, box));
      acts.appendChild(u);
    } else {
      // أنشأتها المدرسة ولا أصلَ لها — لا تُحذف، تُخفى
      const h = el('button', 'a-reject', 'أخفِها');
      h.type = 'button';
      h.addEventListener('click', () => hidePractice(p, box));
      acts.appendChild(h);
    }
    row.appendChild(acts);
    return row;
  }

  // نموذجُ الممارسة: فارغٌ للإضافة، وممتلئٌ للتعديل. والحفظُ جسرٌ واحد تختار القاعدةُ فيه الوضع.
  async function editPractice(p, box) {
    const f = (id) => $(id);
    f('pcWhat').textContent = p ? p.title + ' — ' + (p.owned ? 'مفصولةٌ لمدرستك' : 'موحَّدةٌ للمجمّع، وحفظُها يفصلها لمدرستك') : 'ممارسةٌ جديدةٌ لمدرستك';
    const ss = f('pcScope');
    ss.textContent = '';
    for (const s of pr.scopes) ss.appendChild(new Option(s.label, s.key));
    const v = p || {};
    f('pcTitle').value = v.title || '';
    f('pcPoints').value = v.points == null ? '' : v.points;
    f('pcPolarity').value = v.polarity || 'positive';
    ss.value = v.scope || pr.scope || (pr.scopes[0] && pr.scopes[0].key) || '';
    f('pcKind').value = v.kind || 'practice';
    f('pcZone').value = v.zone || '';
    f('pcOnce').checked = !!v.once_per_day;
    f('pcThrCount').value = v.threshold_count == null ? '' : v.threshold_count;
    f('pcThrDays').value = v.threshold_days == null ? '' : v.threshold_days;
    f('pcEsc').value = v.escalate_to == null ? '' : v.escalate_to;
    f('pcEscNote').value = v.escalate_note || '';
    f('pcNote').value = v.note || '';
    f('pcOrd').value = v.ord == null ? '' : v.ord;
    if (await ask($('practiceDlg')) !== 'ok') return;
    const num = (id) => { const t = f(id).value.trim(); return t === '' ? null : Number(t); };
    const txt = (id) => { const t = f(id).value.trim(); return t === '' ? null : t; };
    await savePractice(p ? p.code : null, {
      title: f('pcTitle').value.trim(), points: num('pcPoints'), polarity: f('pcPolarity').value,
      scope: ss.value, kind: f('pcKind').value, zone: txt('pcZone'), once_per_day: f('pcOnce').checked,
      threshold_count: num('pcThrCount'), threshold_days: num('pcThrDays'), escalate_to: num('pcEsc'),
      escalate_note: txt('pcEscNote'), note: txt('pcNote'), ord: num('pcOrd'),
    }, box);
  }

  async function savePractice(code, v, box) {
    const { data, error } = await M.rpc('v2_practice_upsert', {
      p_school: ui.school, p_code: code, p_title: v.title, p_points: v.points, p_polarity: v.polarity,
      p_scope: v.scope, p_kind: v.kind, p_zone: v.zone, p_once_per_day: v.once_per_day,
      p_threshold_count: v.threshold_count, p_threshold_days: v.threshold_days,
      p_escalate_to: v.escalate_to, p_escalate_note: v.escalate_note, p_note: v.note, p_ord: v.ord,
    }, 'حفظ ممارسة');
    if (error) { toast('لم تُحفظ الممارسة:\n' + errText(error)); return; }
    toast((data && data.mode) || 'حُفظت', true);
    practicesTool(box);
  }

  async function unforkPractice(p, box) {
    const { error } = await M.rpc('v2_practice_unfork', { p_school: ui.school, p_code: p.code }, 'إعادة ممارسة للمشترك');
    if (error) { toast('لم تُعَد:\n' + errText(error)); return; }
    toast('أُعيدت للمشترك، وصار أصلُها نافذًا في مدرستك.', true);
    practicesTool(box);
  }

  async function hidePractice(p, box) {
    const { error } = await M.rpc('v2_practice_toggle', { p_school: ui.school, p_code: p.code, p_active: false }, 'إخفاء ممارسة');
    if (error) { toast('لم تُخفَ:\n' + errText(error)); return; }
    toast('أُخفيت. وما رُصد بها على الطلاب باقٍ مرتبطًا بها.', true);
    practicesTool(box);
  }

  // ---------- مجالات الممارسة ----------
  // الثمانيةُ المشتركة تُقرأ ولا تُعدَّل من مدرسةٍ واحدة. وللمدرسة مجالاتُها.
  async function scopesTool(box) {
    box.textContent = '';
    if (!ui.school) { box.appendChild(el('div', 'notice err', 'لم تُحدَّد مدرستُك — بدّل صفتك إلى صفةٍ في مدرسة.')); return; }
    const sc = await loadScopes();
    if (sc.error) { box.appendChild(el('div', 'notice err', errText(sc.error))); return; }
    const add = el('button', 'btn-accept wide', 'أضف مجالًا لمدرستي');
    add.type = 'button';
    add.addEventListener('click', () => editScope(null, box));
    box.appendChild(add);
    for (const s of pr.scopes) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', s.label),
        el('span', 'badge ' + (s.owned ? 'b-late' : 'b-permitted'), s.owned ? 'لمدرستك' : 'مشتركٌ للمجمّع'));
      row.appendChild(top);
      if (s.owned) {
        const b = el('button', 'btn-ghost wide', 'عدّل');
        b.type = 'button';
        b.addEventListener('click', () => editScope(s, box));
        row.appendChild(b);
      }
      box.appendChild(row);
    }
  }

  async function editScope(s, box) {
    $('scWhat').textContent = s ? s.label : 'مجالٌ جديدٌ لمدرستك';
    $('scLabel').value = s ? s.label : '';
    $('scOrd').value = s && s.ord != null ? s.ord : '';
    $('scActive').checked = true;
    if (await ask($('scopeDlg')) !== 'ok') return;
    const o = $('scOrd').value.trim();
    const { error } = await M.rpc('v2_scope_upsert', {
      p_school: ui.school, p_key: s ? s.key : null, p_label: $('scLabel').value.trim(),
      p_ord: o === '' ? null : Number(o), p_active: $('scActive').checked,
    }, 'حفظ مجال');
    if (error) { toast('لم يُحفظ المجال:\n' + errText(error)); return; }
    toast('حُفظ المجال.', true);
    scopesTool(box);
  }

  // الأبوابُ ذواتُ الجسر الخاصّ التي لها أداةٌ هنا
  const OWN_TOOLS = { class_practices: practicesTool, practice_scopes: scopesTool };

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
