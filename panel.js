// مؤيّد · لوحة التحكّم — أبوابُ الإعداد كما فهرستها القاعدة.
// v2_settings_catalog · v2_setting_rows · v2_setting_update · v2_committee_board · v2_committee_seat_count
// v2_staff_board · v2_staff_save · v2_posts_list · v2_assign_add · v2_assign_end · v2_students_board · v2_student_save · v2_enrolment_end
// v2_enrol_reasons · v2_guardians_of · v2_guardian_save · v2_accounts_board · v2_account_toggle · v2_portal_toggle · v2_school_card
// v2_practices(p_school,…) · v2_practices_hidden · v2_practice_save · v2_practice_state · v2_practice_scopes · v2_scope_upsert · v2_committee_rules · v2_committee_rules_get
// v2_brand_card · v2_brand_save · v2_stamp_save · v2_signature_save · v2_calendar_board · v2_year_save · v2_term_save
// v2_structure_board · v2_structure_set · v2_exceptions_board · v2_exception_add · v2_exception_kinds · v2_reference(p_key)
// واليومُ الدراسيّ: yawm.js (v2_breaks · v2_break_save · v2_break_remove · v2_day_plan · v2_day_build)
// والإنابة: inaba.js (v2_delegations_board · v2_delegate_add · v2_delegate_revoke) · وسطرُ الإنابة في الرأس: v2_my_acting
// وجدولُ الحصص: jadwal.js (v2_timetable_board · v2_slot_* · v2_quota_* · v2_plan_* · v2_teacher_subject · v2_timetable_suggest · v2_draft_*)
// v2_brand_upload_path · v2_committees_list · v2_committee_create · v2_committee_close · v2_committee_duties · v2_committee_duty_save
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
    if (!r.editable && REF_TOOLS[r.key]) {
      // مرجعٌ مقفل: يُقرأ من جسره ولا زرَّ تعديلٍ عليه البتّة
      s.appendChild(toggle('اعرض', REF_TOOLS[r.key]));
    } else if (r.editable && (r.own_bridge || OWN_TOOLS[r.key])) {
      // الباب الحسّاس له جسره الخاصّ بحرّاسه — لا يُعدَّل من التعديل العامّ
      s.appendChild(el('div', 'meta nocan', 'يُدار من جسره الخاصّ' + (r.bridge_ar ? ': ' + r.bridge_ar : '') + ' — لا من التعديل العامّ.'));
      const tool = OWN_TOOLS[r.key];
      if (tool) s.appendChild(toggle('افتح', tool));
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
      // أداةٌ مع التعديل العامّ لا بدلَه (لوحةُ اليوم مع توقيتات اليوم)
      if (EXTRA_TOOLS[r.key]) s.appendChild(toggle(EXTRA_TOOLS[r.key][0], EXTRA_TOOLS[r.key][1]));
    }
    return s;
  }

  // زرٌّ يفتح أداةَ الباب ويطويها
  function toggle(label, tool) {
    const wrap = document.createDocumentFragment();
    const b = el('button', 'btn-ghost wide', label);
    b.type = 'button';
    const box = el('div', 'prows');
    box.hidden = true;
    b.addEventListener('click', () => {
      box.hidden = !box.hidden;
      b.textContent = box.hidden ? label : 'أغلق';
      if (!box.hidden) tool(box);
    });
    wrap.append(b, box);
    return wrap;
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
      // نصُّ النصاب (quorum_ar) كما يرجعه المجلس — لا يُحسب هنا
      row.appendChild(el('div', 'meta', ruleText({ quorum_ar: c.quorum_ar, quorum_mode: c.quorum_mode, quorum_min: c.quorum, allow_remote: c.allow_remote, tie_rule: c.tie_rule })));
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
    return 'النصاب: ' + (r.quorum_ar || '—') + (r.quorum_mode === 'fixed' && r.quorum_min != null ? ' (' + r.quorum_min + ')' : '') +
      ' · الردُّ عن بُعد: ' + (r.allow_remote ? 'مقبول' : 'غيرُ مقبول') +
      ' · التعادل: ' + (r.tie_rule === 'رئيس' ? 'يُرجَّح جانبُ الرئيس' : 'يُؤجَّل البند');
  }

  // النصابُ والردُّ عن بُعدٍ وحكمُ التعادل في نداءٍ واحد — والنموذجُ يُملأ من القاعدة قبل عرضه
  async function setQuorum(c) {
    const { data: r, error: e0 } = await M.rpc('v2_committee_rules_get', { p_school: ui.school, p_committee: c.key }, 'قراءة قواعد اللجنة');
    if (e0) { toast('تعذّرت قراءة القواعد:\n' + errText(e0)); return; }
    $('qWhat').textContent = c.label || c.key;
    $('qNow').textContent = ruleText(r) + ' · أعضاؤها الآن ' + (r.seated ?? r.members ?? '—') + (r.seat_count != null ? ' · سعةُ مقعد العضو ' + r.seat_count : '');
    $('qMode').value = r.quorum_mode || 'majority';
    $('qMin').value = r.quorum_mode === 'fixed' && r.quorum_min != null ? r.quorum_min : '';
    $('qMin').disabled = $('qMode').value !== 'fixed';
    $('qRemote').value = r.allow_remote ? 'yes' : 'no';
    $('qTie').value = r.tie_rule || 'رئيس';
    $('qNote').value = '';
    if (await ask($('quorumDlg')) !== 'ok') return;
    const mode = $('qMode').value;
    const v = $('qMin').value.trim();
    // العددُ يُرسل مع «الثابت» وحدَه، وفوق النصف يحسبه القاعدةُ من الأعضاء
    const { data, error } = await M.rpc('v2_committee_rules', {
      p_school: ui.school, p_committee: c.key,
      p_quorum: mode === 'fixed' && v !== '' ? Number(v) : null,
      p_allow_remote: $('qRemote').value === 'yes', p_tie_rule: $('qTie').value,
      p_note: $('qNote').value.trim() || null, p_quorum_mode: mode,
    }, 'ضبط قواعد اللجنة');
    if (error) { toast('لم تُضبط القواعد:\n' + errText(error)); return; }
    toast('ضُبطت قواعد ' + (c.label || c.key) + (data ? ':\n' + ruleText(data) : '.'), true);
    loadCommittees();
  }

  $('qMode').addEventListener('change', () => { $('qMin').disabled = $('qMode').value !== 'fixed'; });

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
  // أسبابُ إنهاء القيد تُقرأ من القاعدة (v2_enrol_reasons): المفتاحُ إنجليزيّ والعرضُ عربيّ
  const base = { posts: null, reasons: null, staffQ: '', stuQ: '', stuGrade: '', stuSection: '' };

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
    const un = rows.filter((x) => x.unassigned).length;
    box.appendChild(el('div', 'meta', rows.length + ' منسوبًا — منهم ' + un + ' بلا تكليفٍ في المجمّع'));
    for (const p of rows) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', p.name), el('span', 'badge ' + (p.has_account ? 'b-present' : 'b-absent'), p.has_account ? 'له حساب' : 'بلا حساب'));
      row.appendChild(top);
      if (p.unassigned) row.appendChild(el('span', 'badge b-late', 'بلا تكليف — أسنِد له تكليفًا ليعمل'));
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
    if (!base.reasons) {
      const { data: rr, error: er } = await M.rpc('v2_enrol_reasons', undefined, 'أسباب إنهاء القيد');
      if (er) { toast('تعذّر جلب أسباب الإنهاء:\n' + errText(er)); return; }
      base.reasons = rr || [];
    }
    const rs = $('eeReason');
    rs.textContent = '';
    for (const r of base.reasons) rs.appendChild(new Option(r.label, r.key));
    $('eeNote').value = '';
    if (await ask($('enrolEndDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_enrolment_end', { p_school: ui.school, p_student: st.student, p_reason: rs.value, p_note: val('eeNote') }, 'إنهاء قيد');
    if (error) { toast('لم يُنهَ القيد:\n' + errText(error)); return; }
    toast(((data && data.reason) ? 'السبب: ' + data.reason + '\n' : '') + ((data && data.note) || 'أُنهي القيد.'), true);
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

  // ---------- أبوابُ الإكمال: الهويّةُ البصريّة · التقويم · الهيكل · الاستثناءات · المراجعُ الأربعة ----------
  // الحرّاسُ كلُّها في القاعدة، والشاشةُ تعرض رفضَها بنصّه. ولا زرَّ حذفٍ على ختمٍ ولا توقيعٍ ولا استثناء.
  const BUCKET = 'v2-attachments';
  const POS_AR = { right: 'يمين', left: 'يسار', center: 'وسط' };
  const day = (d) => (d ? String(d).slice(0, 10) : '—');

  // المسارُ من القاعدة (v2_brand_upload_path) لا يُبنى هنا · تُرفع الصورةُ إليه ثمّ يُمرَّر — ورفضُ أيٍّ منهما يُعرض بنصّه ولا يُحفظ شيء
  async function uploadImage(file, kind) {
    const ext = (file.name.split('.').pop() || 'png').toLowerCase();
    const { data: pd, error: pe } = await M.rpc('v2_brand_upload_path', { p_school: ui.school, p_kind: kind, p_ext: ext }, 'مسار رفع الصورة');
    if (pe) { toast('لم تُرفع الصورة — ولم يُحفظ شيء:\n' + errText(pe)); return null; }
    const path = pd && pd.path;
    const up = await M.sb.storage.from(BUCKET).upload(path, file, { upsert: false });
    if (up.error) {
      M.logError({ message: up.error.message, fn: 'storage.upload', action: 'رفع صورة ' + kind, params: { path } });
      toast('لم تُرفع الصورة — ولم يُحفظ شيء:\n' + up.error.message);
      return null;
    }
    return path;
  }

  // ----- الهويّةُ البصريّة -----
  async function brandTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    const { data, error } = await M.rpc('v2_brand_card', { p_school: ui.school }, 'الهويّة البصريّة');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const c = data || {};
    const b = c.brand || {};
    if (c.note) box.appendChild(el('div', 'meta', c.note));
    const row = el('div', 'ev');
    row.appendChild(el('div', 'name', 'الشعارُ والألوان'));
    row.appendChild(el('div', 'meta', 'الشعار: ' + (b.logo_path || 'لم يُرفع') + ' · موضعُه: ' + (POS_AR[b.logo_position] || b.logo_position || '—') +
      ' · شعارُ الوزارة: ' + (b.show_ministry_logo === false ? 'لا يظهر' : 'يظهر')));
    const sw = el('div', 'meta swatches');
    for (const [lbl, v] of [['الأساسيّ', b.primary_color], ['الثانويّ', b.accent_color]]) {
      const chip = el('span', 'swatch', lbl + ' ' + (v || '—'));
      if (v) chip.style.setProperty('--sw', v);
      sw.appendChild(chip);
    }
    row.appendChild(sw);
    row.appendChild(el('div', 'meta', 'الترويسة: ' + (b.header_ar || '—')));
    row.appendChild(el('div', 'meta', 'التذييل: ' + (b.footer_ar || '—')));
    row.appendChild(btn('عدّل الهويّة', 'btn-ghost wide', () => editBrand(b, box)));
    box.appendChild(row);

    const st = el('div', 'ev');
    st.appendChild(el('div', 'name', 'ختمُ المدرسة'));
    st.appendChild(c.stamp ? el('div', 'meta', c.stamp.image + ' · يسري من ' + day(c.stamp.from) + (c.stamp.to ? ' إلى ' + day(c.stamp.to) : ''))
      : el('div', 'meta', 'لا ختمَ نافذ'));
    if (c.stamp_next) st.appendChild(el('div', 'meta', 'القادم: ' + c.stamp_next.image + ' · يسري من ' + day(c.stamp_next.from)));
    // السابقُ لا يُحذف — يُعرض بتاريخ انتهائه
    pastLines(st, c.stamps_past);
    st.appendChild(btn('ختمٌ جديد', 'btn-ghost wide', () => newImage('stamp', box)));
    box.appendChild(st);

    const sg = el('div', 'ev');
    sg.appendChild(el('div', 'name', 'التواقيع النافذة'));
    const sigs = c.signatures || [];
    if (!sigs.length) sg.appendChild(el('div', 'meta', 'لا توقيعَ نافذ'));
    for (const s of sigs) sg.appendChild(el('div', 'meta', (s.name || '—') + ' · ' + s.image + ' · يسري من ' + day(s.from) + (s.to ? ' إلى ' + day(s.to) : '')));
    pastLines(sg, c.signatures_past);
    sg.appendChild(el('div', 'meta', 'التوقيعُ شخصيّ: يرفعه صاحبُه أو المديرُ وحدَهما.'));
    sg.appendChild(btn('توقيعٌ جديد', 'btn-ghost wide', () => newImage('signature', box)));
    box.appendChild(sg);
  }
  function pastLines(box, past) {
    if (!Array.isArray(past) || !past.length) return;
    for (const p of past) box.appendChild(el('div', 'meta', 'سابق: ' + (p.name ? p.name + ' · ' : '') + p.image + ' · ' + day(p.from) + ' — انتهى ' + day(p.to)));
  }

  async function editBrand(b, box) {
    $('bdWhat').textContent = 'تظهر في كلّ نموذجٍ يُطبع.';
    $('bdLogo').value = '';
    $('bdPos').value = b.logo_position || 'right';
    $('bdMinistry').checked = b.show_ministry_logo !== false;
    // حقلُ اللون لا يكون فارغًا — فيُرسل اللونُ إن غُيّر وحده، وإلا بقي ما كان
    const colors = { bdPrimary: b.primary_color || '#000000', bdAccent: b.accent_color || '#000000' };
    for (const id in colors) $(id).value = colors[id];
    $('bdHeader').value = b.header_ar || '';
    $('bdFooter').value = b.footer_ar || '';
    for (const k of ['logo_path', 'header_ar', 'footer_ar']) $('bdClear_' + k).checked = false;
    if (await ask($('brandDlg')) !== 'ok') return;
    const changed = (id) => ($(id).value.toLowerCase() === colors[id].toLowerCase() ? null : $(id).value.toUpperCase());
    let logo = null;
    const f = $('bdLogo').files[0];
    if (f) { logo = await uploadImage(f, 'logo'); if (!logo) return; }
    const clear = ['logo_path', 'header_ar', 'footer_ar'].filter((k) => $('bdClear_' + k).checked);
    const { error } = await M.rpc('v2_brand_save', {
      p_school: ui.school, p_logo_path: logo, p_logo_position: $('bdPos').value, p_show_ministry: $('bdMinistry').checked,
      p_primary: changed('bdPrimary'), p_accent: changed('bdAccent'),
      p_header: val('bdHeader'), p_footer: val('bdFooter'), p_clear: clear.length ? clear : null,
    }, 'حفظ الهويّة البصريّة');
    if (error) { toast('لم تُحفظ الهويّة:\n' + errText(error)); return; }
    toast('حُفظت الهويّةُ البصريّة.', true);
    brandTool(box);
  }

  async function newImage(kind, box) {
    const isSig = kind === 'signature';
    $('imTitle').textContent = isSig ? 'توقيعٌ جديد' : 'ختمٌ جديد';
    $('imWhat').textContent = isSig ? 'التوقيعُ شخصيّ: يرفعه صاحبُه بنفسه، أو المدير.' : 'ختمُ المدرسة — للمدير وحدَه. ولا ختمان بتاريخٍ واحد.';
    $('imPersonBox').hidden = !isSig;
    $('imFile').value = '';
    $('imFrom').value = '';
    if (isSig) {
      const sel = $('imPerson');
      sel.textContent = '';
      const { data } = await M.rpc('v2_staff_board', { p_school: ui.school, p_q: null }, 'منسوبو المدرسة');
      const mine = (data || []).filter((p) => (p.posts || []).some((a) => a.school_id === ui.school));
      const me = (M.state.me || {}).person_id;
      for (const p of mine) sel.appendChild(new Option(p.name + (p.person === me ? ' (أنت)' : ''), p.person, p.person === me, p.person === me));
    }
    if (await ask($('imgDlg')) !== 'ok') return;
    const f = $('imFile').files[0];
    if (!f) { toast('اختر الصورة.'); return; }
    const path = await uploadImage(f, isSig ? 'sign' : 'stamp');
    if (!path) return;
    const { data, error } = isSig
      ? await M.rpc('v2_signature_save', { p_school: ui.school, p_person: $('imPerson').value, p_image_ref: path, p_valid_from: val('imFrom') }, 'حفظ توقيع')
      : await M.rpc('v2_stamp_save', { p_school: ui.school, p_image_ref: path, p_valid_from: val('imFrom') }, 'حفظ ختم');
    if (error) { toast('لم يُحفظ:\n' + errText(error)); return; }
    toast((isSig ? 'حُفظ التوقيع.' : 'حُفظ الختم.') + (data && data.note ? '\n' + data.note : ''), true);
    brandTool(box);
  }

  // ----- التقويمُ الدراسيّ والفصول -----
  // السنةُ الجاريةُ والفصلُ الجاري واحدٌ لا أكثر: تضبطه القاعدة، والشاشةُ ترسل الاختيارَ وحدَه
  async function calendarTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    const { data, error } = await M.rpc('v2_calendar_board', { p_school: ui.school }, 'التقويم الدراسي');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const c = data || {};
    const sc = c.scope || {};
    box.appendChild(el('div', 'meta', 'مسارُ التقويم: ' + (sc.label || '—') + (sc.regions ? ' — ' + sc.regions : '') + (sc.source ? ' · السند: ' + sc.source : '')));
    box.appendChild(btn('سنةٌ دراسيّةٌ جديدة', 'btn-accept wide', () => editYear(null, box)));
    const years = c.years || [];
    if (!years.length) box.appendChild(el('div', 'notice', 'لا سنةَ دراسيّة — ولا يُقيَّد طالبٌ حتى تؤسَّس.'));
    for (const y of years) {
      const closed = y.status === 'closed';
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', y.name),
        el('span', 'badge ' + (closed ? 'b-absent' : y.current ? 'b-present' : 'b-permitted'), closed ? 'مقفلة' + (y.closed_on ? ' ' + day(y.closed_on) : '') : y.current ? 'الجارية' : 'مفتوحة'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', day(y.starts) + ' — ' + day(y.ends) + ' · طلّابُها ' + (y.students ?? 0)));
      for (const t of (y.terms || [])) {
        const line = el('div', 'prow');
        line.appendChild(el('div', 'meta', 'الفصل ' + t.no + ': ' + day(t.starts) + ' — ' + day(t.ends) + (t.current ? ' · الجاري' : '')));
        if (!closed) line.appendChild(btn('عدّل الفصل', 'btn-ghost wide', () => editTerm(y, t, box)));
        row.appendChild(line);
      }
      if (closed) row.appendChild(el('div', 'meta nocan', 'سنةٌ مقفلةٌ لا تُعدَّل.'));
      else {
        const acts = el('div', 'acts two');
        acts.append(btn('عدّل السنة', null, () => editYear(y, box)), btn('فصلٌ جديد', null, () => editTerm(y, null, box)));
        row.appendChild(acts);
      }
      box.appendChild(row);
    }
  }

  async function editYear(y, box) {
    $('yrWhat').textContent = y ? y.name : 'سنةٌ جديدة';
    $('yrName').value = y ? y.name : '';
    $('yrStarts').value = y ? day(y.starts) : '';
    $('yrEnds').value = y ? day(y.ends) : '';
    $('yrCurrent').checked = !!(y && y.current);
    if (await ask($('yearDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_year_save', {
      p_school: ui.school, p_year: y ? y.year : null, p_name: val('yrName'), p_starts: val('yrStarts'), p_ends: val('yrEnds'), p_current: $('yrCurrent').checked,
    }, 'حفظ سنة دراسية');
    if (error) { toast('لم تُحفظ السنة:\n' + errText(error)); return; }
    toast('حُفظت السنة.', true);
    calendarTool(box);
  }

  async function editTerm(y, t, box) {
    $('tmWhat').textContent = y.name + ' (' + day(y.starts) + ' — ' + day(y.ends) + ')' + (t ? ' · الفصل ' + t.no : ' · فصلٌ جديد');
    $('tmNo').value = String(t ? t.no : ((y.terms || []).length + 1 > 3 ? 3 : (y.terms || []).length + 1));
    $('tmStarts').value = t ? day(t.starts) : '';
    $('tmEnds').value = t ? day(t.ends) : '';
    $('tmCurrent').checked = !!(t && t.current);
    if (await ask($('termDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_term_save', {
      p_school: ui.school, p_year: y.year, p_term: t ? t.term : null, p_number: Number($('tmNo').value),
      p_starts: val('tmStarts'), p_ends: val('tmEnds'), p_current: $('tmCurrent').checked,
    }, 'حفظ فصل دراسي');
    if (error) { toast('لم يُحفظ الفصل:\n' + errText(error)); return; }
    toast('حُفظ الفصل.', true);
    calendarTool(box);
  }

  // ----- الهيكلُ التنظيميّ: يُختار من الدليل ولا يُخترع -----
  async function structureTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    const { data, error } = await M.rpc('v2_structure_board', { p_school: ui.school }, 'الهيكل التنظيمي');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const c = data || {};
    if (c.note) box.appendChild(el('div', 'meta', c.note));
    const cur = c.current;
    box.appendChild(cur ? el('div', 'notice', 'النافذ: ' + cur.label + ' · وكلاؤه ' + (cur.deputies ?? '—') + (cur.source ? ' · السند: ' + cur.source : ''))
      : el('div', 'notice err', 'لم يُختر لمدرستك هيكلٌ بعد.'));
    const outside = c.outside || [];
    if (outside.length) box.appendChild(el('div', 'meta', (cur ? 'تكاليفُ خارجَ الهيكل النافذ: ' : 'تكاليفُ مدرستك القائمة: ') + outside.map((o) => o.label).join(' · ')));
    box.appendChild(el('h3', 'grp', 'الهياكلُ في الدليل التنظيميّ — اختيارُ المدير وحدَه'));
    for (const st of (c.all || [])) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      const isCur = cur && cur.code === st.code;
      const orph = Number(st.orphans) || 0;
      top.append(el('div', 'name', st.label), el('span', 'badge ' + (isCur ? 'b-present' : orph ? 'b-late' : 'b-permitted'), isCur ? 'النافذ' : orph ? 'يترك ' + orph + ' تكليفًا خارجَه' : 'يسع تكاليفَ مدرستك'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', st.posts + ' وظيفة · وكلاؤه ' + (st.deputies ?? '—') + (st.source ? ' · السند: ' + st.source : '')));
      if (!isCur) row.appendChild(btn('اعتمد هذا الهيكل', 'btn-ghost wide', () => setStructure(st, box)));
      box.appendChild(row);
    }
    const posts = c.posts || [];
    if (posts.length) {
      box.appendChild(el('h3', 'grp', 'وظائفُ الهيكل النافذ'));
      for (const p of posts) {
        box.appendChild(el('div', 'meta', p.label + (p.parent_ar ? ' ← يتبع ' + p.parent_ar : '') + ' · ' + (Number(p.filled) > 0 ? 'يشغلها ' + p.filled : 'شاغرة')));
      }
    }
  }

  async function setStructure(st, box) {
    if (!window.confirm('اعتمادُ «' + st.label + '» هيكلًا لمدرستك؟\nولا يُعتمد إن ترك تكليفًا قائمًا خارجه.')) return;
    const { data, error } = await M.rpc('v2_structure_set', { p_school: ui.school, p_code: st.code }, 'تغيير الهيكل التنظيمي');
    if (error) { toast('لم يُعتمد الهيكل:\n' + errText(error)); return; }
    toast('اعتُمد «' + st.label + '»' + (data && data.posts != null ? ' — وظائفه ' + data.posts : '') + '.', true);
    structureTool(box);
  }

  // ----- سجلُّ الاستثناءات: يُقيَّد ولا يُمحى ولا يُعدَّل -----
  // أنواعُه من القاعدة (v2_exception_kinds) — لا تُكتب هنا
  const exc = { kinds: null };
  async function excKinds() {
    if (exc.kinds) return exc.kinds;
    const { data, error } = await M.rpc('v2_exception_kinds', undefined, 'أنواع الاستثناء');
    if (error) { toast('تعذّر جلب أنواع الاستثناء:\n' + errText(error)); return []; }
    exc.kinds = data || [];
    return exc.kinds;
  }

  async function exceptionsTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    box.appendChild(el('div', 'meta', 'حيث تخالف المدرسةُ النظامَ بقرارٍ مكتوب. يقيّده المديرُ وحدَه، ولا يُمحى ولا يُعدَّل.'));
    box.appendChild(btn('قيّد استثناءً', 'btn-accept wide', () => addException(box)));
    const { data, error } = await M.rpc('v2_exceptions_board', { p_school: ui.school }, 'سجل الاستثناءات');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    const ar = Object.fromEntries((await excKinds()).map((k) => [k.key, k.label]));
    box.appendChild(el('div', 'meta', rows.length ? rows.length + ' استثناءً — الأحدثُ أوّلًا' : 'لا استثناءَ مقيَّد.'));
    for (const x of rows) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', (ar[x.rule_kind] || x.rule_kind) + (x.rule_ref ? ' · ' + x.rule_ref : '')),
        el('span', 'badge b-late', String(x.decided_at || '').slice(0, 16).replace('T', ' ')));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', 'النظام: ' + x.system_says));
      row.appendChild(el('div', 'meta', 'والمدرسة: ' + x.school_does));
      row.appendChild(el('div', 'detail', 'السبب: ' + x.reason));
      row.appendChild(el('div', 'meta', 'قرّره: ' + (x.decided_by || '—') + (x.source ? ' · السند: ' + x.source : '')));
      box.appendChild(row);
    }
  }

  async function addException(box) {
    const sel = $('exKind');
    if (!sel.options.length) for (const k of await excKinds()) sel.appendChild(new Option(k.label, k.key));
    for (const id of ['exRef', 'exSays', 'exDoes', 'exReason', 'exSource']) $(id).value = '';
    if (await ask($('excDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_exception_add', {
      p_school: ui.school, p_rule_kind: sel.value, p_rule_ref: val('exRef'), p_system_says: val('exSays'),
      p_school_does: val('exDoes'), p_reason: val('exReason'), p_source: val('exSource'),
    }, 'تقييد استثناء');
    if (error) { toast('لم يُقيَّد:\n' + errText(error)); return; }
    toast((data && data.note) || 'قُيّد الاستثناء.', true);
    exceptionsTool(box);
  }

  // ----- لجانُ المدرسة: السبعُ الوزاريّةُ تُقرأ، ولجنةُ المدرسة يُنشئها المديرُ ويوقفها ولا تُحذف -----
  async function committeesTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    box.appendChild(btn('أنشئ لجنةً مدرسيّة', 'btn-accept wide', () => createCommittee(box)));
    const { data, error } = await M.rpc('v2_committees_list', { p_school: ui.school }, 'لجان المدرسة');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    for (const c of (data || [])) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', c.label), el('span', 'badge ' + (c.mine ? 'b-late' : 'b-permitted'), c.mine ? 'لجنةُ المدرسة' : 'وزاريّة'));
      row.appendChild(top);
      if (c.purpose) row.appendChild(el('div', 'meta', c.purpose));
      row.appendChild(el('div', 'meta', 'أعضاء ' + c.members + ' · مهامّ ' + c.duties + ' · اجتماعات ' + c.meetings +
        (Number(c.open_tasks) ? ' · قراراتٌ لم تُنفَّذ ' + c.open_tasks : '')));
      if (c.source) row.appendChild(el('div', 'meta', 'السند: ' + c.source));
      if (c.mine) row.appendChild(btn('أوقف اللجنة', 'btn-ghost wide', () => closeCommittee(c, box)));
      else row.appendChild(el('div', 'meta nocan', 'بنصّ الدليل — لا تُنشأ ولا تُوقف.'));
      box.appendChild(row);
    }
  }

  async function createCommittee(box) {
    const posts = await loadPosts();
    for (const id of ['cmChair', 'cmRap']) {
      const sel = $(id);
      sel.textContent = '';
      for (const p of posts) sel.appendChild(new Option(p.label, p.key));
    }
    if (posts.some((p) => p.key === 'principal')) $('cmChair').value = 'principal';
    if (posts.some((p) => p.key === 'counselor')) $('cmRap').value = 'counselor';
    $('cmLabel').value = ''; $('cmPurpose').value = ''; $('cmMembers').value = '3'; $('cmElected').checked = false;
    if (await ask($('commDlg')) !== 'ok') return;
    // المقاعد: رئيسٌ ومقرّرٌ بوظيفتيهما، وأعضاءٌ بعددهم — والقاعدةُ ترفض لجنةً بلا رئيسٍ أو مقرّر
    const seats = [
      { seat_role: 'chair', post_key: $('cmChair').value, seat_count: 1, ord: 1 },
      { seat_role: 'rapporteur', post_key: $('cmRap').value, seat_count: 1, ord: 2 },
      { seat_role: 'member', seat_count: num('cmMembers') || 1, is_elected: $('cmElected').checked, ord: 3 },
    ];
    const { data, error } = await M.rpc('v2_committee_create', {
      p_school: ui.school, p_key: null, p_label: val('cmLabel'), p_purpose: val('cmPurpose'), p_seats: seats,
    }, 'إنشاء لجنة');
    if (error) { toast('لم تُنشأ اللجنة:\n' + errText(error)); return; }
    toast('أُنشئت اللجنة — مقاعدُها ' + (data && data.seats) + '.', true);
    committeesTool(box);
  }

  async function closeCommittee(c, box) {
    $('ccWhat').textContent = c.label;
    $('ccReason').value = '';
    if (await ask($('commCloseDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_committee_close', { p_school: ui.school, p_committee: c.key, p_reason: val('ccReason') }, 'إيقاف لجنة');
    if (error) { toast('لم تُوقف اللجنة:\n' + errText(error)); return; }
    toast((data && data.note) || 'أُوقفت اللجنة.', true);
    committeesTool(box);
  }

  // ----- مهامُّ اللجان: ما نصّ عليه الدليلُ يُقرأ، وما أضافته المدرسةُ يُعدَّل -----
  const duty = { committee: '' };
  async function dutiesTool(box) {
    box.textContent = '';
    if (noSchool(box)) return;
    const { data: list, error: e0 } = await M.rpc('v2_committees_list', { p_school: ui.school }, 'لجان المدرسة');
    if (e0) { box.appendChild(el('div', 'notice err', errText(e0))); return; }
    const sel = document.createElement('select');
    for (const c of (list || [])) sel.appendChild(new Option(c.label + ' (' + c.duties + ')', c.key));
    if (!duty.committee && list && list.length) duty.committee = list[0].key;
    sel.value = duty.committee;
    sel.addEventListener('change', () => { duty.committee = sel.value; dutiesTool(box); });
    const bar = el('div', 'prow');
    bar.appendChild(sel);
    box.appendChild(bar);
    if (!duty.committee) return;
    const label = ((list || []).find((c) => c.key === duty.committee) || {}).label || duty.committee;
    box.appendChild(btn('أضف مهمّةً لمدرستك', 'btn-accept wide', () => editDuty(null, label, box)));
    const { data, error } = await M.rpc('v2_committee_duties', { p_school: ui.school, p_committee: duty.committee }, 'مهامّ اللجنة');
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const rows = data || [];
    if (!rows.length) box.appendChild(el('div', 'meta', 'لا مهامَّ مسجَّلة لهذي اللجنة.'));
    for (const d of rows) {
      const row = el('div', 'ev');
      const top = el('div', 'row1');
      top.append(el('div', 'name', (d.ord != null ? d.ord + '. ' : '') + d.text), el('span', 'badge ' + (d.mine ? 'b-late' : 'b-permitted'), d.mine ? 'أضافتها مدرستُك' : 'بنصّ الدليل'));
      row.appendChild(top);
      row.appendChild(el('div', 'meta', 'الدوريّة: ' + (d.cadence || '—') + (d.source ? ' · السند: ' + d.source : '') +
        (Number(d.done_this_term) ? ' · بنودٌ معتمدةٌ تشبهها: ' + d.done_this_term : '')));
      if (d.mine) row.appendChild(btn('عدّلها', 'btn-ghost wide', () => editDuty(d, label, box)));
      else row.appendChild(el('div', 'meta nocan', '🔒 تُقرأ ولا تُعدَّل.'));
      box.appendChild(row);
    }
  }

  async function editDuty(d, label, box) {
    $('duWhat').textContent = label + (d ? '' : ' — مهمّةٌ جديدة');
    $('duText').value = d ? d.text : '';
    $('duCadence').value = d && d.cadence ? d.cadence : '';
    $('duOrd').value = d && d.ord != null ? d.ord : '';
    if (await ask($('dutyDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_committee_duty_save', {
      p_school: ui.school, p_committee: duty.committee, p_duty: d ? d.id : null,
      p_text: val('duText'), p_cadence: val('duCadence'), p_ord: num('duOrd'),
    }, 'حفظ مهمّة لجنة');
    if (error) { toast('لم تُحفظ المهمّة:\n' + errText(error)); return; }
    toast('المهمّة ' + ((data && data.mode) || 'حُفظت') + '.', true);
    dutiesTool(box);
  }

  // ----- المراجعُ الأربعة: تُقرأ ولا تُعدَّل -----
  function refTool(key) {
    return async (box) => {
      box.textContent = '';
      const { data, error } = await M.rpc('v2_reference', { p_key: key }, 'مرجع');
      if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
      const r = data || {};
      box.appendChild(el('div', 'meta', '🔒 ' + (r.label || '') + ' — للقراءة' + (r.source ? ' · السند: ' + r.source : '')));
      if (r.note) box.appendChild(el('div', 'meta', r.note));
      (REF_RENDER[key] || (() => {}))(box, r);
    };
  }
  const REF_RENDER = {
    absence_ladder(box, r) {
      let cur = null; let row = null;
      for (const i of (r.items || [])) {
        if (i.ladder !== cur) { cur = i.ladder; row = el('div', 'ev'); row.appendChild(el('div', 'name', 'السلّم ' + cur)); box.appendChild(row); }
        row.appendChild(el('div', 'meta', i.ord + '. ' + i.text + (i.owner ? ' — ' + i.owner : '') + (i.evidence ? ' · الإثبات: ' + i.evidence : '')));
      }
    },
    absence_excuses(box, r) {
      for (const e of (r.items || [])) {
        const row = el('div', 'ev');
        const top = el('div', 'row1');
        top.appendChild(el('div', 'name', e.no + '. ' + e.text));
        if (e.school_discretion) top.appendChild(el('span', 'badge b-late', 'تقديرُ المدرسة'));
        row.appendChild(top);
        if (e.proof) row.appendChild(el('div', 'meta', 'الإثبات: ' + e.proof));
        if (e.school_discretion) row.appendChild(el('div', 'meta', 'تقرّره لجنةُ التوجيه.'));
        if (e.source) row.appendChild(el('div', 'meta', 'السند: ' + e.source));
        box.appendChild(row);
      }
    },
    violence_types(box, r) {
      for (const v of (r.items || [])) {
        const row = el('div', 'ev');
        row.appendChild(el('div', 'name', v.label + ' · ' + v.family));
        if (v.definition) row.appendChild(el('div', 'meta', v.definition));
        if (v.source) row.appendChild(el('div', 'meta', 'السند: ' + v.source));
        box.appendChild(row);
      }
    },
    grading(box, r) {
      const subj = r.subjects || [];
      for (const m of (r.models || []).slice().sort((a, b) => a.model_no - b.model_no)) {
        const row = el('div', 'ev');
        row.appendChild(el('div', 'name', 'النموذج ' + m.model_no + ': ' + m.title_ar + ' · ' + m.kind + ' · من ' + m.total));
        const comps = Array.isArray(m.components) ? m.components : [];
        if (comps.length) row.appendChild(el('div', 'meta', comps.map((x) => x.n + ' ' + x.d).join(' · ')));
        const ss = subj.filter((s) => s.model_no === m.model_no);
        if (ss.length) row.appendChild(el('div', 'meta', 'موادّه: ' + ss.map((s) => s.subject_ar + ' (' + s.stages_ar + ')').join(' · ')));
        if (m.retake_note) row.appendChild(el('div', 'meta', 'الدورُ الثاني: ' + m.retake_note));
        for (const n of (m.notes_ar || [])) row.appendChild(el('div', 'meta', n));
        if (m.source_page) row.appendChild(el('div', 'meta', 'السند: ' + (m.source_doc || '') + ' ' + m.source_page));
        box.appendChild(row);
      }
    },
  };
  const REF_TOOLS = Object.fromEntries(['absence_ladder', 'absence_excuses', 'violence_types', 'grading'].map((k) => [k, refTool(k)]));

  // الأبوابُ التي لها أداةٌ هنا بجسورها — وتُقدَّم على التعديل العامّ
  // أدواتٌ تُضاف إلى التعديل العامّ لبابها: [نصُّ الزرّ، الأداة]
  const EXTRA_TOOLS = {
    day_settings: ['لوحةُ اليوم', (b) => window.MoayadYawm.dayPlanTool(b)],
  };
  const OWN_TOOLS = {
    class_practices: practicesTool, practice_scopes: scopesTool,
    staff: staffTool, assignments_panel: staffTool, students: studentsTool, guardians: studentsTool,
    accounts: accountsTool, school_card: schoolCardTool,
    branding: brandTool, calendar: calendarTool, structure: structureTool, exceptions: exceptionsTool,
    committees_school: committeesTool, committee_duties: dutiesTool,
    // جدولُ الحصص وأبوابُه الأربعة — أدواتُها في jadwal.js
    timetable: (b) => window.MoayadJadwal.timetableTool(b),
    teaching_quota: (b) => window.MoayadJadwal.quotaTool(b),
    subject_plan: (b) => window.MoayadJadwal.planTool(b),
    teacher_subjects: (b) => window.MoayadJadwal.subjectsTool(b),
    timetable_drafts: (b) => window.MoayadJadwal.draftsTool(b),
    // فتراتُ اليوم — yawm.js
    break_slots: (b) => window.MoayadYawm.breaksTool(b),
    // الإنابةُ في الصفات — inaba.js
    delegations: (b) => window.MoayadInaba.delegationsTool(b),
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
    M.state.school = ui.school;
    M.renderActing(ui.school);
    $('panelView').hidden = false;
    await loadCatalog();
  }

  (async () => {
    const { data } = await M.sb.auth.getSession();
    if (!data.session) { location.replace('./'); return; }
    await enter();
  })();
})();
