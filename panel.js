// مؤيّد · لوحة التحكّم — أبوابُ الإعداد كما فهرستها القاعدة.
// v2_settings_catalog · v2_setting_rows · v2_setting_update · v2_committee_board · v2_committee_seat_count
// v2_staff_board · v2_staff_save · v2_posts_list · v2_assign_add · v2_assign_end · v2_students_board · v2_student_save · v2_enrolment_end
// v2_guardians_of · v2_guardian_save · v2_accounts_board · v2_account_toggle · v2_portal_toggle · v2_school_card
// v2_practices(p_school,…) · v2_practices_hidden · v2_practice_save · v2_practice_state · v2_practice_scopes · v2_scope_upsert · v2_committee_rules · v2_committee_rules_get
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
    if (r.editable && (r.own_bridge || OWN_TOOLS[r.key])) {
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
    box.appendChild(el('h3', 'grp', 'قواعد اللجان وسعة المقاعد'));
    const res = await Promise.all(COMMITTEES.map((k) =>
      M.rpc('v2_committee_board', { p_school: ui.school, p_committee: k }, 'مجلس اللجنة')));
    res.forEach((r, i) => {
      const row = el('div', 'ev');
      if (r.error) { row.appendChild(el('div', 'notice err', COMMITTEES[i] + ': ' + errText(r.error))); box.appendChild(row); return; }
      const b = r.data || {};
      const c = b.committee || {};
      row.appendChild(el('div', 'name', c.label || COMMITTEES[i]));
      // قواعدُ مدرستك كما يرجعها المجلس: النصابُ والردُّ عن بُعدٍ وحكمُ التعادل
      row.appendChild(el('div', 'meta', ruleText({ quorum_min: c.quorum, allow_remote: c.allow_remote, tie_rule: c.tie_rule })));
      if (c.quorum_note) row.appendChild(el('div', 'meta', c.quorum_note));
      // سعةُ الدليل مقابل سعةِ مدرستك — تُعرض حين تختلفان
      for (const s of (b.seats || []).filter((x) => x.count_guide != null && Number(x.count) !== Number(x.count_guide))) {
        row.appendChild(el('div', 'meta', (s.role_ar || '') + ': سعةُ مدرستك ' + s.count + ' · سعةُ الدليل ' + s.count_guide));
      }
      const acts = el('div', 'acts one');
      const q = el('button', 'a-go', 'اضبط القواعد');
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

  function ruleText(r) {
    return 'النصاب: ' + (r.quorum_min == null ? 'لم يُحدَّد' : r.quorum_min) +
      ' · الردُّ عن بُعد: ' + (r.allow_remote ? 'مقبول' : 'غيرُ مقبول') +
      ' · التعادل: ' + (r.tie_rule === 'رئيس' ? 'يُرجَّح جانبُ الرئيس' : 'يُؤجَّل البند');
  }

  // النصابُ والردُّ عن بُعدٍ وحكمُ التعادل في نداءٍ واحد — والنموذجُ يُملأ من القاعدة قبل عرضه
  async function setQuorum(c) {
    const { data: r, error: e0 } = await M.rpc('v2_committee_rules_get', { p_school: ui.school, p_committee: c.key }, 'قراءة قواعد اللجنة');
    if (e0) { toast('تعذّرت قراءة القواعد:\n' + errText(e0)); return; }
    $('qWhat').textContent = c.label || c.key;
    $('qNow').textContent = ruleText(r) + ' · أعضاؤها الآن ' + r.members + (r.seat_count != null ? ' · سعةُ مقعد العضو ' + r.seat_count : '');
    $('qMin').value = r.quorum_min == null ? '' : r.quorum_min;
    $('qClear').checked = false;
    $('qMin').disabled = false;
    $('qRemote').value = r.allow_remote ? 'yes' : 'no';
    $('qTie').value = r.tie_rule || 'رئيس';
    $('qNote').value = '';
    if (await ask($('quorumDlg')) !== 'ok') return;
    const v = $('qMin').value.trim();
    const clear = $('qClear').checked;
    const { data, error } = await M.rpc('v2_committee_rules', {
      p_school: ui.school, p_committee: c.key,
      p_quorum: clear || v === '' ? null : Number(v),
      p_allow_remote: $('qRemote').value === 'yes', p_tie_rule: $('qTie').value,
      p_note: $('qNote').value.trim() || null, p_clear_quorum: clear,
    }, 'ضبط قواعد اللجنة');
    if (error) { toast('لم تُضبط القواعد:\n' + errText(error)); return; }
    toast('ضُبطت قواعد ' + (c.label || c.key) + (data ? ':\n' + ruleText(data) : '.'), true);
    loadCommittees();
  }

  $('qClear').addEventListener('change', () => { $('qMin').disabled = $('qClear').checked; });

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
  // الأصلُ المشتركُ يبقى بكوده، والمدرسةُ تضع عليه سطرَ تعديلٍ أو إخفاء — فالكودُ واحدٌ أبدًا ولا ينقطع سجلُّ الطالب.
  // والقاعدةُ تعرف بنفسها وضعَ الحفظ: أُضيفت · عُدّلت · عُدّلت لمدرستك — فلا نسأل المستخدم.
  const POLARITY_AR = { positive: 'إيجابيّة', negative: 'سلبيّة' };
  const KIND_AR = { practice: 'ممارسة', state: 'حالة' };
  const pr = { scope: '', polarity: '', scopes: [] };

  function tagOf(p) {
    if (p.edited) return ['b-late', 'معدَّلةٌ لمدرستك'];
    if (p.mine) return ['b-present', 'أنشأتها مدرستُك'];
    return ['b-permitted', 'موحَّدةٌ للمجمّع'];
  }

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
    const [act, hid] = await Promise.all([
      M.rpc('v2_practices', { p_school: ui.school, p_scope: pr.scope || null, p_polarity: pr.polarity || null }, 'ممارسات الصفّ'),
      M.rpc('v2_practices_hidden', { p_school: ui.school }, 'الممارسات المخفيّة'),
    ]);
    box.textContent = '';
    if (sc.error) { box.appendChild(el('div', 'notice err', errText(sc.error))); return; }
    if (act.error) { box.appendChild(el('div', 'notice err', errText(act.error))); return; }
    const rows = act.data || [];
    box.appendChild(practicesFilters(box));
    const edited = rows.filter((p) => p.edited).length;
    const mine = rows.filter((p) => p.mine).length;
    box.appendChild(el('div', 'meta', rows.length + ' ممارسةً نافذة · معدَّلةٌ لمدرستك ' + edited + ' · أنشأتها مدرستُك ' + mine));
    if (!rows.length) box.appendChild(el('div', 'empty', 'لا ممارسات.'));
    let lastScope = null;
    for (const p of rows) {
      if (p.scope !== lastScope) {
        box.appendChild(el('h3', 'grp', p.scope_ar || p.scope));
        lastScope = p.scope;
      }
      box.appendChild(practiceRow(p, box));
    }
    // المخفيُّ في مدرستك — ومنه يُظهَر
    box.appendChild(el('h3', 'grp', 'المخفيّ في مدرستك'));
    if (hid.error) { box.appendChild(el('div', 'notice err', errText(hid.error))); return; }
    const hidden = hid.data || [];
    if (!hidden.length) { box.appendChild(el('div', 'meta', 'لا ممارسةَ مخفيّة.')); return; }
    for (const h of hidden) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', h.title), el('span', 'badge b-absent', 'مخفيّة'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', [h.scope_ar || h.scope, POLARITY_AR[h.polarity] || h.polarity,
        h.mine ? 'أنشأتها مدرستُك' : 'موحَّدةٌ للمجمّع'].join(' · ')));
      const b = el('button', 'btn-ghost wide', 'أظهِرها');
      b.type = 'button';
      b.addEventListener('click', () => setState(h, 'أظهِر', box));
      row.appendChild(b);
      box.appendChild(row);
    }
  }

  function practiceRow(p, box) {
    const row = el('div', 'ev');
    const top = el('div', 'row1');
    const [cls, tag] = tagOf(p);
    top.append(el('div', 'name', p.title), el('span', 'badge ' + cls, tag));
    row.appendChild(top);
    const bits = [POLARITY_AR[p.polarity] || p.polarity, KIND_AR[p.kind] || p.kind, 'النقاط: ' + p.points];
    if (p.zone) bits.push('الموضع: ' + p.zone);
    if (p.once_per_day) bits.push('مرّةً في اليوم');
    if (p.threshold_count) bits.push('الحدّ: ' + p.threshold_count + (p.threshold_days ? ' خلال ' + p.threshold_days + ' يومًا' : ''));
    if (p.escalate_to) bits.push('تُصعَّد إلى المخالفة ' + p.escalate_to);
    row.appendChild(el('div', 'meta', bits.join(' · ')));
    if (p.escalate_note) row.appendChild(el('div', 'meta', p.escalate_note));
    if (p.note) row.appendChild(el('div', 'meta', p.note));
    const acts = el('div', 'acts ' + (p.edited ? 'three' : 'two'));
    const ed = el('button', null, 'عدّل');
    ed.type = 'button';
    ed.addEventListener('click', () => editPractice(p, box));
    acts.appendChild(ed);
    if (p.edited) {
      // «أعدها للأصل» للمشتركة المعدَّلة وحدَها
      const u = el('button', null, 'أعدها للأصل');
      u.type = 'button';
      u.addEventListener('click', () => setState(p, 'أعدها للأصل', box));
      acts.appendChild(u);
    }
    // «أخفِها» للجميع — المشتركةِ وما أنشأته المدرسة
    const h = el('button', 'a-reject', 'أخفِها');
    h.type = 'button';
    h.addEventListener('click', () => setState(p, 'أخفِ', box));
    acts.appendChild(h);
    row.appendChild(acts);
    return row;
  }

  // نموذجُ الممارسة: فارغٌ للإضافة، وممتلئٌ للتعديل. والحفظُ جسرٌ واحد تختار القاعدةُ فيه الوضع.
  async function editPractice(p, box) {
    const f = (id) => $(id);
    let what = 'ممارسةٌ جديدةٌ لمدرستك';
    if (p) what = p.title + ' — ' + (p.mine ? 'أنشأتها مدرستُك' : p.edited ? 'معدَّلةٌ لمدرستك' : 'موحَّدةٌ للمجمّع، وحفظُها يعدّلها لمدرستك وحدَها');
    f('pcWhat').textContent = what;
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
    const { data, error } = await M.rpc('v2_practice_save', {
      p_school: ui.school, p_code: p ? p.code : null, p_title: f('pcTitle').value.trim(), p_points: num('pcPoints'),
      p_polarity: f('pcPolarity').value, p_scope: ss.value, p_kind: f('pcKind').value, p_zone: txt('pcZone'),
      p_once_per_day: f('pcOnce').checked, p_threshold_count: num('pcThrCount'), p_threshold_days: num('pcThrDays'),
      p_escalate_to: num('pcEsc'), p_escalate_note: txt('pcEscNote'), p_note: txt('pcNote'), p_ord: num('pcOrd'),
    }, 'حفظ ممارسة');
    if (error) { toast('لم تُحفظ الممارسة:\n' + errText(error)); return; }
    toast((data && data.mode) || 'حُفظت', true);
    practicesTool(box);
  }

  const STATE_DONE = {
    'أخفِ': 'أُخفيت. وما رُصد بها على الطلاب باقٍ مرتبطًا بها.',
    'أظهِر': 'ظهرت.',
    'أعدها للأصل': 'رجعت للمشترك كما هو.',
  };
  async function setState(p, state, box) {
    const { error } = await M.rpc('v2_practice_state', { p_school: ui.school, p_code: p.code, p_state: state }, state + ' ممارسة');
    if (error) { toast('لم يقع:\n' + errText(error)); return; }
    toast(STATE_DONE[state], true);
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

  // ---------- أبوابُ الأساس: المنسوبون · التكاليف · الطلّابُ والقيد · أولياءُ الأمور · الحسابات · بطاقةُ المدرسة ----------
  // كلُّ حارسٍ في القاعدة، والشاشةُ تعرض رفضَها بنصّه. ولا حذفَ لطالب، ولا صلاحيّةَ تُرفع، ولا كلمةَ مرورٍ تُنشأ أو تُعرض.
  const ASSIGN_END = [
    ['transferred', 'نُقل'], ['resigned', 'استقال'], ['assignment_ended', 'انتهى التكليف'], ['deceased', 'توفّي'],
    ['leave', 'إجازة'], ['year_closed', 'أُغلق العام'], ['other', 'أخرى'],
  ];
  const ENROL_END = ['نقل', 'تخرّج', 'طيّ قيد', 'انقطاع', 'سفر', 'أخرى'];
  const base = { posts: null, staffQ: '', stuQ: '', stuGrade: '', stuSection: '' };

  function noSchool(box) {
    if (ui.school) return false;
    box.appendChild(el('div', 'notice err', 'لم تُحدَّد مدرستُك — بدّل صفتك إلى صفةٍ في مدرسة.'));
    return true;
  }
  function btn(text, cls, fn) {
    const b = el('button', cls || null, text);
    b.type = 'button';
    b.addEventListener('click', fn);
    return b;
  }
  function searchBar(value, placeholder, onGo) {
    const bar = el('div', 'prow');
    const inp = document.createElement('input');
    inp.type = 'text';
    inp.placeholder = placeholder;
    inp.value = value;
    inp.addEventListener('keydown', (e) => { if (e.key === 'Enter') onGo(inp.value.trim()); });
    bar.append(inp, btn('ابحث', 'btn-ghost wide', () => onGo(inp.value.trim())));
    return bar;
  }
  const val = (id) => { const t = $(id).value.trim(); return t === '' ? null : t; };
  const num = (id) => { const t = $(id).value.trim(); return t === '' ? null : Number(t); };

  // ----- المنسوبون والتكاليف -----
  async function loadPosts() {
    if (base.posts) return base.posts;
    const { data, error } = await M.rpc('v2_posts_list', undefined, 'الوظائف في الملاك');
    if (error) { toast('تعذّر جلب الوظائف:\n' + errText(error)); return []; }
    base.posts = data || [];
    return base.posts;
  }

  async function staffTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    box.appendChild(searchBar(base.staffQ, 'اسمٌ أو هويّة', (q) => { base.staffQ = q; staffTool(box); }));
    box.appendChild(btn('أضف منسوبًا', 'btn-accept wide', () => editStaff(null, box)));
    const { data, error } = await M.rpc('v2_staff_board', { p_school: ui.school, p_q: base.staffQ || null }, 'كشف المنسوبين');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    box.appendChild(el('div', 'meta', rows.length + ' منسوبًا بتكليفٍ قائمٍ في مدرستك'));
    for (const p of rows) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', p.name), el('span', 'badge ' + (p.has_account ? 'b-present' : 'b-absent'), p.has_account ? 'له حساب' : 'بلا حساب'));
      row.appendChild(top);
      const bits = [];
      if (p.national_id) bits.push('الهويّة ' + p.national_id);
      if (p.employee_no) bits.push('الرقم الوظيفيّ ' + p.employee_no);
      if (p.phone) bits.push('الجوّال ' + p.phone);
      if (p.email) bits.push(p.email);
      if (bits.length) row.appendChild(el('div', 'meta', bits.join(' · ')));
      const more = [p.major, p.rank, p.qualification].filter(Boolean);
      if (more.length) row.appendChild(el('div', 'meta', more.join(' · ')));
      for (const a of (p.posts || [])) {
        const line = el('div', 'prow');
        line.appendChild(el('div', 'meta', (a.post_ar || a.post) + ' — ' + (a.school || '') + ' · خطاب ' + (a.letter_no || '—') +
          (a.letter_date ? ' في ' + a.letter_date : '') + ' · منذ ' + (a.started_on || '—') + (a.entitled === false ? ' · غيرُ مستحقّ' : '')));
        if (a.school_id === ui.school) line.appendChild(btn('أنهِ هذا التكليف', 'btn-ghost wide', () => endAssignment(a, p, box)));
        row.appendChild(line);
      }
      const acts = el('div', 'acts two');
      acts.append(btn('عدّل بياناته', null, () => editStaff(p, box)), btn('أسند تكليفًا', null, () => addAssignment(p.person, p.name, box)));
      row.appendChild(acts);
      box.appendChild(row);
    }
  }

  async function editStaff(p, box) {
    $('stWhat').textContent = p ? p.name : 'منسوبٌ جديد — ولا يعمل حتى يُسند له تكليف';
    const v = p || {};
    $('stName').value = v.name || '';
    $('stNid').value = v.national_id || '';
    $('stEmp').value = v.employee_no || '';
    $('stPhone').value = v.phone || '';
    $('stEmail').value = v.email || '';
    $('stMajor').value = v.major || '';
    $('stRank').value = v.rank || '';
    $('stQual').value = v.qualification || '';
    if (await ask($('staffDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_staff_save', {
      p_school: ui.school, p_person: p ? p.person : null, p_full_name: $('stName').value.trim(),
      p_national_id: val('stNid'), p_employee_no: val('stEmp'), p_phone: val('stPhone'), p_email: val('stEmail'),
      p_major: val('stMajor'), p_rank: val('stRank'), p_qualification: val('stQual'),
    }, p ? 'تعديل منسوب' : 'إضافة منسوب');
    if (error) { toast('لم يُحفظ:\n' + errText(error)); return; }
    toast(((data && data.mode) || 'حُفظ') + (data && data.note ? '\n' + data.note : ''), true);
    if (!p && data && data.person) {
      // المضافُ لا يظهر في الكشف حتى يُسند له تكليف — فيُفتح نموذجُ التكليف الآن
      await addAssignment(data.person, $('stName').value.trim(), box);
      return;
    }
    staffTool(box);
  }

  async function addAssignment(person, name, box) {
    const posts = await loadPosts();
    const ps = $('asPost');
    ps.textContent = '';
    for (const x of posts) ps.appendChild(new Option(x.label, x.key));
    $('asWhat').textContent = name || '';
    $('asLetter').value = '';
    $('asLetterDate').value = '';
    $('asStart').value = '';
    $('asEntitled').checked = true;
    $('asReason').value = '';
    if (await ask($('assignDlg')) !== 'ok') { staffTool(box); return; }
    const { error } = await M.rpc('v2_assign_add', {
      p_school: ui.school, p_person: person, p_post: ps.value, p_letter_no: $('asLetter').value.trim(),
      p_letter_date: val('asLetterDate'), p_started_on: val('asStart'), p_entitled: $('asEntitled').checked,
      p_reason: val('asReason'),
    }, 'إسناد تكليف');
    if (error) { toast('لم يُسنَد:\n' + errText(error)); staffTool(box); return; }
    toast('أُسند التكليف.', true);
    staffTool(box);
  }

  async function endAssignment(a, p, box) {
    $('aeWhat').textContent = p.name + ' — ' + (a.post_ar || a.post);
    const rs = $('aeReason');
    rs.textContent = '';
    for (const [k, l] of ASSIGN_END) rs.appendChild(new Option(l, k));
    $('aeDate').value = '';
    if (await ask($('assignEndDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_assign_end', { p_assignment: a.assignment, p_ended_on: val('aeDate'), p_reason: rs.value }, 'إنهاء تكليف');
    if (error) { toast('لم يُنهَ:\n' + errText(error)); return; }
    toast('أُنهي التكليف.', true);
    staffTool(box);
  }

  // ----- الطلّابُ والقيد، وأولياءُ الأمور -----
  async function studentsTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    box.appendChild(searchBar(base.stuQ, 'اسمٌ أو رقمُ نورٍ أو هويّة', (q) => { base.stuQ = q; studentsTool(box); }));
    const f = el('div', 'prow');
    const gl = el('label', null, 'الصفّ');
    const g = document.createElement('input');
    g.type = 'number'; g.id = 'sbGrade'; gl.htmlFor = g.id; g.value = base.stuGrade;
    const sl = el('label', null, 'الشعبة');
    const s = document.createElement('input');
    s.type = 'text'; s.id = 'sbSection'; sl.htmlFor = s.id; s.value = base.stuSection;
    f.append(gl, g, sl, s, btn('صفِّ', 'btn-ghost wide', () => { base.stuGrade = g.value.trim(); base.stuSection = s.value.trim(); studentsTool(box); }));
    box.appendChild(f);
    box.appendChild(btn('قيّد طالبًا', 'btn-accept wide', () => editStudent(null, box)));
    const { data, error } = await M.rpc('v2_students_board', {
      p_school: ui.school, p_grade: base.stuGrade === '' ? null : Number(base.stuGrade),
      p_section: base.stuSection || null, p_q: base.stuQ || null,
    }, 'كشف الطلّاب');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    box.appendChild(el('div', 'meta', rows.length + ' طالبًا مقيَّدًا'));
    for (const st of rows) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', st.name), el('span', 'badge ' + (st.portal ? 'b-present' : 'b-permitted'), st.portal ? 'بوّابتُه مفتوحة' : 'بوّابتُه مغلقة'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', ['نور ' + (st.student_no || '—'), 'الصفّ ' + (st.grade == null ? '—' : st.grade) + (st.section ? ' / ' + st.section : ''),
        st.national_id ? 'الهويّة ' + st.national_id : null, st.nationality, st.birth_hijri ? 'مولده ' + st.birth_hijri : null,
        'أولياؤه ' + (st.guardians || 0)].filter(Boolean).join(' · ')));
      const gbox = el('div');
      const acts = el('div', 'acts three');
      acts.append(btn('عدّل', null, () => editStudent(st, box)),
        btn('أولياؤه', null, () => guardiansOf(st, gbox)),
        btn('أنهِ القيد', 'a-reject', () => endEnrolment(st, box)));
      row.appendChild(acts);
      row.appendChild(btn(st.portal ? 'أغلق بوّابةَ الطالب' : 'افتح بوّابةَ الطالب', 'btn-ghost wide', () => togglePortal('student', st.student, !st.portal, () => studentsTool(box))));
      row.appendChild(gbox);
      box.appendChild(row);
    }
  }

  async function editStudent(st, box) {
    $('suWhat').textContent = st ? st.name : 'قيدُ طالبٍ جديد';
    const v = st || {};
    $('suName').value = v.name || '';
    $('suNo').value = v.student_no || '';
    $('suNo').disabled = !!st;
    $('suNid').value = v.national_id || '';
    $('suNat').value = v.nationality || '';
    $('suBirth').value = v.birth_hijri || '';
    $('suSex').value = v.sex || '';
    $('suPhone').value = v.phone || '';
    $('suGrade').value = v.grade == null ? '' : v.grade;
    $('suSection').value = v.section || '';
    if (await ask($('studentDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_student_save', {
      p_school: ui.school, p_student: st ? st.student : null, p_full_name: $('suName').value.trim(),
      p_student_no: st ? null : val('suNo'), p_national_id: val('suNid'), p_nationality: val('suNat'),
      p_birth_hijri: val('suBirth'), p_sex: val('suSex'), p_phone: val('suPhone'),
      p_grade: num('suGrade'), p_section: val('suSection'),
    }, st ? 'تعديل طالب' : 'قيد طالب');
    if (error) { toast('لم يُحفظ:\n' + errText(error)); return; }
    toast((data && data.mode) || 'حُفظ', true);
    studentsTool(box);
  }

  async function endEnrolment(st, box) {
    $('eeWhat').textContent = st.name + ' — لا يُحذف طالب: يُنهى قيدُه بسبب، وتُغلق بوّابتُه وبوّابةُ وليّه، والسجلُّ باقٍ.';
    const rs = $('eeReason');
    rs.textContent = '';
    for (const r of ENROL_END) rs.appendChild(new Option(r, r));
    $('eeNote').value = '';
    if (await ask($('enrolEndDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_enrolment_end', { p_school: ui.school, p_student: st.student, p_reason: rs.value, p_note: val('eeNote') }, 'إنهاء قيد');
    if (error) { toast('لم يُنهَ القيد:\n' + errText(error)); return; }
    toast((data && data.note) || 'أُنهي القيد.', true);
    studentsTool(box);
  }

  async function guardiansOf(st, gbox) {
    gbox.textContent = '';
    const { data, error } = await M.rpc('v2_guardians_of', { p_student: st.student }, 'أولياء الأمر');
    if (error) { gbox.appendChild(el('div', 'notice err', errText(error))); return; }
    gbox.appendChild(el('h3', 'grp', 'أولياءُ ' + (st.display || st.name)));
    for (const g of (data || [])) {
      const row = el('div', 'prow');
      const top = el('div', 'row1');
      top.append(el('div', 'name', g.name + (g.relation ? ' — ' + g.relation : '')),
        el('span', 'badge ' + (g.is_primary ? 'b-present' : 'b-permitted'), g.is_primary ? 'الأساسيّ' : 'غيرُ أساسيّ'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', [g.phone && 'الجوّال ' + g.phone, g.work_phone && 'العمل ' + g.work_phone,
        g.home_phone && 'المنزل ' + g.home_phone, g.workplace, g.national_id && 'الهويّة ' + g.national_id].filter(Boolean).join(' · ') || '—'));
      row.appendChild(el('div', 'meta', (g.has_account ? 'له حساب' : 'بلا حساب') + ' · ' + (g.portal ? 'بوّابتُه مفتوحة' : 'بوّابتُه مغلقة')));
      const acts = el('div', 'acts two');
      acts.append(btn('عدّل', null, () => editGuardian(st, g, gbox)),
        btn(g.portal ? 'أغلق بوّابتَه' : 'افتح بوّابتَه', null, () => togglePortal('guardian', g.guardian, !g.portal, () => guardiansOf(st, gbox))));
      row.appendChild(acts);
      gbox.appendChild(row);
    }
    gbox.appendChild(btn('أضف وليَّ أمر', 'btn-ghost wide', () => editGuardian(st, null, gbox)));
  }

  async function editGuardian(st, g, gbox) {
    $('gdWhat').textContent = (g ? g.name : 'وليُّ أمرٍ جديد') + ' — لـ' + (st.display || st.name);
    const v = g || {};
    $('gdName').value = v.name || '';
    $('gdRel').value = v.relation || '';
    $('gdNid').value = v.national_id || '';
    $('gdPhone').value = v.phone || '';
    $('gdWork').value = v.work_phone || '';
    $('gdHome').value = v.home_phone || '';
    $('gdPlace').value = v.workplace || '';
    $('gdPrimary').checked = !!v.is_primary;
    if (await ask($('guardianDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_guardian_save', {
      p_student: st.student, p_guardian: g ? g.guardian : null, p_full_name: $('gdName').value.trim(),
      p_relation: $('gdRel').value.trim(), p_national_id: val('gdNid'), p_phone: val('gdPhone'),
      p_work_phone: val('gdWork'), p_home_phone: val('gdHome'), p_workplace: val('gdPlace'),
      p_is_primary: $('gdPrimary').checked,
    }, 'حفظ وليّ أمر');
    if (error) { toast('لم يُحفظ:\n' + errText(error)); return; }
    toast('حُفظ وليُّ الأمر.', true);
    guardiansOf(st, gbox);
  }

  async function togglePortal(kind, id, open, after) {
    const { error } = await M.rpc('v2_portal_toggle', { p_kind: kind, p_id: id, p_open: open }, open ? 'فتح بوّابة' : 'إغلاق بوّابة');
    if (error) { toast('لم يقع:\n' + errText(error)); return; }
    toast(open ? 'فُتحت البوّابة.' : 'أُغلقت البوّابة.', true);
    after();
  }

  // ----- الحساباتُ والبوّابات: تفعيلٌ وإيقافٌ لا غير -----
  async function accountsTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    box.appendChild(el('div', 'meta', 'تفعيلٌ وإيقافٌ فقط. ولا تُرفع صلاحيّةٌ من هنا، ولا تُنشأ كلمةُ مرورٍ ولا تُعرض — فإنشاءُ الحسابات بيد المالك.'));
    const { data, error } = await M.rpc('v2_accounts_board', { p_school: ui.school }, 'كشف الحسابات');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const r = data || {};
    const cnt = (o) => o ? ('الكلّ ' + o.total + ' · لهم حساب ' + o.with_account + ' · بوّاباتُهم مفتوحة ' + o.portal_open) : '—';
    box.appendChild(el('div', 'meta', 'أولياءُ الأمور: ' + cnt(r.guardians)));
    box.appendChild(el('div', 'meta', 'الطلّاب: ' + cnt(r.students)));
    box.appendChild(el('h3', 'grp', 'حساباتُ المنسوبين'));
    for (const s of (r.staff || [])) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', s.name), el('span', 'badge ' + (s.active ? 'b-present' : 'b-absent'), s.active ? 'مفعَّل' : 'موقوف'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', (s.posts || '—') + ' · الصلاحيّة: ' + (s.role || '—')));
      row.appendChild(btn(s.active ? 'أوقف الحساب' : 'فعِّل الحساب', s.active ? 'btn-ghost wide' : 'btn-accept wide', async () => {
        const { error: e2 } = await M.rpc('v2_account_toggle', { p_person: s.person, p_active: !s.active }, s.active ? 'إيقاف حساب' : 'تفعيل حساب');
        if (e2) { toast('لم يقع:\n' + errText(e2)); return; }
        toast(s.active ? 'أُوقف الحساب.' : 'فُعِّل الحساب.', true);
        accountsTool(box);
      }));
      box.appendChild(row);
    }
  }

  // ----- بطاقةُ المدرسة -----
  async function schoolCardTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    const { data, error } = await M.rpc('v2_school_card', { p_school: ui.school }, 'بطاقة المدرسة');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const c = data || {};
    const row = el('div', 'ev');
    row.appendChild(el('div', 'name', c.name || '—'));
    row.appendChild(el('div', 'meta', ['المرحلة: ' + (c.stage || '—'), 'الفئة: ' + (c.category || '—'), 'الهيكل: ' + (c.structure || '—'),
      'مسار التقويم: ' + (c.calendar_scope || '—')].join(' · ')));
    row.appendChild(el('div', 'meta', 'الفصول ' + (c.sections ?? '—') + ' · الطلّاب ' + (c.students ?? '—') + ' · المنسوبون ' + (c.staff ?? '—')));
    if (c.test_mode) row.appendChild(el('div', 'notice', 'المدرسةُ في وضع التجربة.'));
    box.appendChild(row);
  }

  // الأبوابُ التي لها أداةٌ هنا بجسورها — وتُقدَّم على التعديل العامّ
  const OWN_TOOLS = {
    class_practices: practicesTool, practice_scopes: scopesTool,
    staff: staffTool, assignments_panel: staffTool, students: studentsTool, guardians: studentsTool,
    accounts: accountsTool, school_card: schoolCardTool,
  };

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
