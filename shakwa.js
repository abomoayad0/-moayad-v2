// مؤيّد · الشكوى والبلاغ ومحضرُ ضبطِ الواقعة — تكاليفُ ٢١ و٢٢ بأمرِ ٢٣ (window.MoayadShakwa)
// ① صفحةُ الطالب: v2_complaint_file (بلوحةِ الرسم ← p_strokes) · v2_my_complaints — ولا خيارَ «على معلّم» فيها
// ② شاشةُ الوكيل: v2_complaints_board · v2_complaint_escalate_stale و v2_complaint_teacher_timeout مرّةً في اليوم
//    v2_complaint_read بفعلٍ من المستخدم وحدَه (كلُّ فتحةٍ تُسجَّل) · first_call · show_accused · statement · party_add
//    ask_teacher · set_period · suggest (لا يُختارُ الأوّلُ آليًّا) ومعه البحثُ في الدليل (v2_problems) · classify
//    close بأربعةِ مخارج · staff_decide بخمسة (الإيذاءُ منفصلٌ أحمر) · perjury بعدَ الإقفالِ ولا على المشتكى عليه
// ③ المحضر (من سجلّ الطالب): v2_minute_needed ومعه السند دائمًا · v2_minute_build حلقةً حتى يُعتمد
//    v2_minute_witness_add · v2_minute_seizure_add · v2_minute_read · والتوقيعُ بـ v2_form_sign ومعه «امتنعَ عن التوقيع»
// ④ المعلّمُ الشاهد: v2_my_complaint_asks (بلا تفصيل) · teacher_sign ثمّ teacher_read ثمّ teacher_answer
// ⑤ لوحةُ التحكّم: v2_complaint_hints · v2_complaint_hint_set (تعطيلٌ لا حذف) · v2_staff_complaints_of في صفحة المنسوب
// ⑥ لوحةُ تحكّمِ الشكوى (تكليف ٢٤): v2_complaint_settings · v2_complaint_setting_set · والأرقامُ بـ v2_rule_set
//    وأسماءُ الطالب من v2_my_people · ونوعُ المشتكى عليه وعدّادُ الجلسات من القراءة · وسجلُّ المحضر سجلّ_اللائحة
// 🔴 الأقوالُ سرّ: لا تُعرضُ إلّا في شاشةِ الوكيلِ وعندَ الشاهدِ بعدَ توقيعِه · واسمُ المبلِّغِ لا يُعرضُ للمشتكى عليه
// ورسائلُ الردِّ تُعرضُ كما جاءت · والتواريخُ والأرقامُ بلفظِ القاعدة
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash, typed } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));
  const roleKey = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };

  // نصوصُ التعهّد كما في التكليف ٢١
  // نصُّ التعهّد من v2_my_pledge وحدَه (تكليف ٢٥) — ولا نصَّ ثابتًا في الشاشة: ما يُعرَض هو ما يُحفظ مع التوقيع
  async function pledge(kind, party) {
    const { data, error } = await M.rpc('v2_my_pledge', { p_kind: kind, p_party: party || null }, 'نصّ التعهّد');
    return error ? { error } : { text: data };
  }
  const STAFF_LINE = 'الشكوى على معلّمٍ أو منسوبٍ تُقدَّمُ عندَ وكيلِ شؤونِ الطلّابِ نفسِه';
  const KINDS = [['complaint', 'شكوى'], ['report', 'بلاغ']];
  const KIND_WHY = {
    complaint: '«وقعَ عليّ» ← تُخبَرُ بنتيجتها',
    report: '«رأيتُ ولا شأنَ لي» ← اسمُك لا يظهرُ لأحدٍ أبدًا، وتُخبَرُ بالوصولِ لا بالنتيجة',
  };
  const label = (k) => String(k).replace(/_/g, ' ');

  // ما يرجعُ من الباب بمفاتيحه كما هي: كلُّ نصٍّ سطرٌ «المفتاح: القيمة» — والسطرُ الذي فيه 🔴 أحمر
  function said(data, keys) {
    const box = el('div', 'rs-said');
    const d = data || {};
    for (const k of keys || Object.keys(d)) {
      const v = d[k];
      if (v == null || v === '' || typeof v === 'object') continue;
      const t = typeof v === 'boolean' ? (v ? '✓' : '—') : String(v);
      const p = el('div', /🔴/.test(t) ? 'rs-red' : null);
      p.append(el('b', null, label(k) + ': '), document.createTextNode(t));
      box.appendChild(p);
    }
    arabize(box);
    return box;
  }
  // جدولُ مفتاحٍ وقيمة — td.kv-k كي لا يُخفى على الهاتف
  function kv(d, keys, raw) {
    const w = el('div', 'rs-tablewrap');
    const t = el('table', 'rs-table');
    for (const k of keys) {
      const v = d[k];
      if (v == null || v === '') continue;
      const tr = el('tr');
      const td = el('td');
      td.appendChild((raw || []).includes(k) ? typed(v, 'span') : document.createTextNode(String(v)));
      tr.append(el('td', 'kv-k', label(k)), td);
      t.appendChild(tr);
    }
    w.appendChild(t);
    return w;
  }
  const yes = (v) => v === true || v === 'true';

  // ---------- منتقي الطلّاب (v2_students_find) — واحدٌ أو أكثر ----------
  function studentFinder(multi) {
    const w = el('div');
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث بالاسم أو الرقم';
    const chips = el('div', 'rs-chips');
    const list = el('div', 'rs-list');
    const sel = new Map();
    let seq = 0; let tm = null;
    const drawChips = () => {
      chips.textContent = '';
      for (const [id, name] of sel) {
        const s = el('span', null, name);
        const x = el('button', null, '✕'); x.type = 'button'; x.setAttribute('aria-label', 'أزل');
        x.addEventListener('click', () => { sel.delete(id); drawChips(); });
        s.appendChild(x); chips.appendChild(s);
      }
    };
    const go = async () => {
      const t = q.value.trim(); const my = ++seq;
      if (t.length < 2) { list.textContent = ''; return; }
      const { data, error } = await M.rpc('v2_students_find', { p_text: t, p_in_grade: null, p_in_section: null, p_max: 20, p_of_school: school() }, 'البحث عن طالب');
      if (my !== seq) return;
      list.textContent = '';
      if (error) { errBox(list, error); return; }
      for (const x of (data && data.rows) || []) {
        const name = x.name || x.full_name || '';
        const b = btn('', 'rs-item', () => { if (!multi) sel.clear(); sel.set(x.student, name); drawChips(); q.value = ''; list.textContent = ''; });
        b.append(el('b', null, name), el('small', null, [x.class_ar, x.student_no].filter(Boolean).join(' · ')));
        list.appendChild(b);
      }
      arabize(list);
    };
    q.addEventListener('input', () => { clearTimeout(tm); tm = setTimeout(go, 250); });
    w.append(chips, q, list);
    return { node: w, ids: () => [...sel.keys()], one: () => [...sel.keys()][0] || null };
  }
  // منتقي المنسوبين (v2_staff_list) — واحدٌ أو أكثر
  let staffCache = null;
  async function staffList() {
    if (staffCache && staffCache.school === school()) return staffCache;
    const { data, error } = await M.rpc('v2_staff_list', { p_school: school() }, 'قائمة المنسوبين');
    staffCache = { school: school(), rows: data || [], error };
    return staffCache;
  }
  function staffPicker(st, multi) {
    const w = el('div');
    if (st.error) { errBox(w, st.error); return { node: w, ids: () => [], one: () => null }; }
    const chips = el('div', 'rs-chips');
    const box = el('div');
    const sel = new Map();
    const drawChips = () => {
      chips.textContent = '';
      for (const [id, name] of sel) {
        const s = el('span', null, name);
        const x = el('button', null, '✕'); x.type = 'button'; x.setAttribute('aria-label', 'أزل');
        x.addEventListener('click', () => { sel.delete(id); drawChips(); });
        s.appendChild(x); chips.appendChild(s);
      }
    };
    const items = st.rows.map((p) => [p.person_id, p.name_ar, p.post_ar || p.roles_ar || '']);
    V.chooser(box, items, null, (v) => { const it = items.find((x) => x[0] === v); if (!multi) sel.clear(); if (it) sel.set(v, it[1]); drawChips(); });
    w.append(chips, box);
    return { node: w, ids: () => [...sel.keys()], one: () => [...sel.keys()][0] || null };
  }
  const nodeField = (key, lbl, node, show) => {
    const w = el('div');
    if (lbl) w.appendChild(el('div', 'rs-label', lbl));
    w.appendChild(node);
    return { key, type: 'node', node: w, show };
  };

  // ======================= ① صفحةُ الطالب =======================
  function studentCard(box, preview) {
    box.textContent = '';
    for (const [k, t] of KINDS) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, t), el('p', null, KIND_WHY[k]));
      box.appendChild(f);
    }
    box.appendChild(el('div', 'rs-note', STAFF_LINE));
    const b = btn('اكتبْ شكوى أو بلاغًا', 'rs-btn big', () => studentForm(box));
    if (preview) { b.disabled = true; b.title = 'معاينة — الشكوى للطالب من حسابه'; }
    box.appendChild(b);
    const mine = el('div');
    box.appendChild(mine);
    if (!preview) myList(mine);
    arabize(box);
  }

  // أسماءُ الزملاءِ والمنسوبين للطالب (v2_my_people: نوع · معرّف · الاسم · بيان) — ومداها من لوحة التحكّم
  function peoplePicker(rows, multi) {
    const w = el('div');
    const chips = el('div', 'rs-chips');
    const box = el('div');
    const sel = new Map();
    const drawChips = () => {
      chips.textContent = '';
      for (const [id, name] of sel) {
        const s = el('span', null, name);
        const x = el('button', null, '✕'); x.type = 'button'; x.setAttribute('aria-label', 'أزل');
        x.addEventListener('click', () => { sel.delete(id); drawChips(); });
        s.appendChild(x); chips.appendChild(s);
      }
    };
    const items = rows.map((r) => [r['معرّف'], r['الاسم'], r['بيان'] || '']);
    V.chooser(box, items, null, (v) => { const it = items.find((x) => x[0] === v); if (!multi) sel.clear(); if (it) sel.set(v, it[1]); drawChips(); });
    w.append(chips, box);
    return { node: w, ids: () => [...sel.keys()] };
  }

  async function studentForm(box) {
    // لا طرفَ بعد — فالشكوى لم تُقدَّم · ولا توقيعَ بلا نصّ
    const pl = await pledge('statement');
    if (pl.error) { flash('bad', errText(pl.error)); return; }
    const ppl = await M.rpc('v2_my_people', undefined, 'أسماءُ الزملاء والمنسوبين');
    const rows = ppl.data || [];
    const mates = rows.filter((r) => r['نوع'] === 'زميل');
    const staff = rows.filter((r) => r['نوع'] === 'معلّم');
    const acc = peoplePicker(mates, true);
    const wS = peoplePicker(mates, true);
    const wT = peoplePicker(staff, true);
    const who = ppl.error
      ? [{ key: 'who', type: 'node', node: el('div', 'notice err', errText(ppl.error)) }]
      : [nodeField('acc', 'المشتكى عليه (من الطلّاب)', acc.node), nodeField('ws', 'الشهودُ من الطلّاب', wS.node), nodeField('wt', 'الشهودُ من المعلّمين والمنسوبين', wT.node)];
    const arr = (x) => (x.ids().length ? x.ids() : null);
    V.form({
      title: 'شكوى أو بلاغ',
      what: STAFF_LINE,
      fields: [
        { key: 'kind', type: 'pick', label: 'النوع', items: KINDS, value: 'complaint' },
        { key: 'why', type: 'node', node: el('p', 'rs-meta', KIND_WHY.complaint), show: (v) => v.kind !== 'report' },
        { key: 'why2', type: 'node', node: el('p', 'rs-meta', KIND_WHY.report), show: (v) => v.kind === 'report' },
        { key: 'body', type: 'textarea', label: 'ما جرى', rows: 5 },
        { key: 'on', type: 'date', label: 'تاريخُ الواقعة' },
        { key: 'at', type: 'time', label: 'الساعة' },
        { key: 'place', label: 'المكان' },
        ...who,
        { key: 'sign', type: 'sign', label: pl.text },
      ],
      ok: 'أرسِلْ',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_file', {
          p_body: v.body, p_on: v.on, p_at: v.at, p_place: v.place, p_kind: v.kind || 'complaint', p_against: 'student',
          p_accused_students: ppl.error ? null : arr(acc), p_witness_students: ppl.error ? null : arr(wS), p_witness_teachers: ppl.error ? null : arr(wT),
          p_strokes: v.sign,
        }, 'تقديم شكوى');
        if (error) return error;
        flash('ok', (data && data['البيان']) || '');
        studentCard(box, false);
        return null;
      },
    });
  }

  async function myList(box) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_my_complaints', undefined, 'شكاواي');
    if (error) { errBox(box, error); return; }
    const rows = data || [];
    if (!rows.length) return;
    box.appendChild(el('h4', 'rs-sub', 'ما قدّمتُه'));
    for (const r of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [r['المرجع'], r['النوع']].filter(Boolean).join(' · ')));
      f.appendChild(kv(r, ['وقعت', 'الساعة', 'المكان', 'ما_كتبتُه', 'إفادتي', 'الحال', 'قُدّمت'], ['ما_كتبتُه', 'إفادتي']));
      box.appendChild(f);
    }
    arabize(box);
  }

  // ======================= ② شاشةُ الوكيل =======================
  const B = { all: false, host: null };
  // الحالُ بلفظ القاعدة (complaint_status_ar): ما يُعمل فيه · والمحفوظةُ لا تُقفَل ولا يُرصد فيها زور
  const OPEN_STATES = ['وصلت — لم تُفتَح بعد', 'التحقيقُ جارٍ'];
  const SHELVED = 'حُفظت بالبتِّ الأوّل';
  const UNDECIDED = '🔴 لم يُبتَّ بعد';

  // مرّةً في اليوم عند فتح اللوحة: الرفعُ والمهلة — وما رجع منهما يُعرض كما هو
  async function daily(note) {
    const key = 'moayad.cmp.daily.' + school() + '.' + new Date().toISOString().slice(0, 10);
    try { if (localStorage.getItem(key)) return; } catch (_) { /* بلا تخزين: يُستدعى */ }
    const [a, b] = await Promise.all([
      M.rpc('v2_complaint_escalate_stale', { p_school: school() }, 'رفعُ ما بات بلا بتّ'),
      M.rpc('v2_complaint_teacher_timeout', { p_school: school() }, 'مهلةُ الشاهد المعلّم'),
    ]);
    for (const r of [a, b]) note.appendChild(el('p', 'rs-meta', r.error ? errText(r.error) : ((r.data && r.data['البيان']) || '')));
    if (!a.error && !b.error) { try { localStorage.setItem(key, '1'); } catch (_) { /* لا شيء */ } }
    arabize(note);
  }

  function deputy(host, opts) {
    B.host = host;
    host.textContent = '';
    const note = el('div');
    const tools = el('div', 'rs-row');
    const fil = el('div', 'rs-pick');
    const list = el('div');
    const cs = el('div');
    cs.id = 'cmpCase';
    host.append(note, fil, tools, list, cs);
    V.pick(fil, [['open', 'ما لم يُقفَل'], ['all', 'الكلّ']], B.all ? 'all' : 'open', (v) => { B.all = v === 'all'; boardList(list, cs); });
    tools.appendChild(btn('سجّلْ شكوى عن طالب', 'rs-btn soft', () => fileForDeputy(list, cs)));
    daily(note);
    boardList(list, cs);
  }

  async function boardList(list, cs) {
    list.textContent = '';
    list.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_complaints_board', { p_school: school(), p_all: B.all }, 'لوحة الشكاوى');
    list.textContent = '';
    if (error) { errBox(list, error); return; }
    const rows = (data || []).slice();
    // «لم يُبتَّ بعد» أوّلُ ما يُرى — والباقي بترتيبه كما رجع
    rows.sort((a, b) => (b['البتّ_الأوّل'] === UNDECIDED) - (a['البتّ_الأوّل'] === UNDECIDED));
    if (!rows.length) { list.appendChild(el('p', 'rs-empty', 'لا شكاوى.')); return; }
    for (const r of rows) {
      const f = el('div', 'rs-file' + (yes(r['متأخّرة']) ? ' rs-red' : ''));
      f.appendChild(el('h5', null, [r['المرجع'], r['النوع'], r['الحال']].filter(Boolean).join(' · ')));
      if (r['البتّ_الأوّل'] === UNDECIDED) f.appendChild(el('p', 'rs-big rs-red', UNDECIDED));
      f.appendChild(kv(r, ['صاحبها', 'المشتكى_عليه', 'وقعت', 'الساعة', 'المكان', 'البتّ_الأوّل', 'مهلة_الإقفال', 'الأقوال', 'وصلت']));
      const row = el('div', 'rs-row');
      // «ينتظر» زرُّ الإجراءِ التالي — يفتح الشكوى (والفتحُ يُسجَّل)
      row.appendChild(btn(r['ينتظر'] || 'افتحها', 'rs-btn', () => openCase(cs, r)));
      f.appendChild(row);
      list.appendChild(f);
    }
    arabize(list);
  }

  const reload = (cs, r) => { const list = cs.previousElementSibling; boardList(list, cs); openCase(cs, r); };

  async function openCase(cs, row) {
    const id = row['رقم'];
    cs.textContent = '';
    const card = el('div', 'rs-card');
    cs.appendChild(card);
    const h3 = el('h3', null, [row['المرجع'], row['النوع']].filter(Boolean).join(' · '));
    const st = el('p', 'rs-meta', row['الحال'] || '');
    const top = el('div');
    card.append(h3, st, top);
    const body = el('div');
    card.appendChild(body);
    body.appendChild(el('p', 'rs-meta', 'جارٍ فتحُ الشكوى…'));
    cs.scrollIntoView({ behavior: 'smooth', block: 'start' });
    const { data, error } = await M.rpc('v2_complaint_read', { p_complaint: id }, 'قراءة الشكوى');
    body.textContent = '';
    if (error) errBox(body, error);
    const d = data || {};
    // الحالُ والبتُّ من القراءة إن رجعت — وإلّا فمن صفِّ اللوحة
    if (d['الحال']) st.textContent = d['الحال'];
    const now = d['الحال'] || row['الحال'];
    const open = OPEN_STATES.includes(now);
    const closed = !open && now !== SHELVED;
    // البتُّ الأوّل: زرّان كبيران في أعلى الصفحة — والحفظُ بسببٍ مكتوب
    if ((d['البتّ_الأوّل'] || row['البتّ_الأوّل']) === UNDECIDED) {
      const r2 = el('div', 'rs-row');
      r2.append(btn('افتحِ التحقيق', 'rs-btn big', () => firstCall(cs, row, 'open', null, false)),
        btn('احفظْها', 'rs-btn big soft', () => V.form({
          title: 'احفظْها', what: row['المرجع'],
          fields: [{ key: 'why', type: 'textarea', label: 'السبب' }], ok: 'احفظْها',
          onOk: async (v) => firstCall(cs, row, 'shelve', v.why, true),
        })));
      top.appendChild(r2);
    }
    // نوعُ المشتكى عليه من القراءة (على_منسوب) — فيظهر بابُه وحدَه · وإن لم يرجع ظهر البابان
    const staffCase = typeof d['على_منسوب'] === 'boolean' ? d['على_منسوب'] : null;
    if (staffCase && d['جلسات_هذي_السنة']) top.appendChild(el('p', 'rs-big', label('جلسات_هذي_السنة') + ': ' + d['جلسات_هذي_السنة']));
    if (!error) {
      body.appendChild(kv(d, ['المشتكى_عليه_نوع', 'صاحبها', 'كتبها', 'وقعت', 'الساعة', 'المكان', 'الحصّة', 'البتّ_الأوّل', 'مهلة_الإقفال', 'التصنيف', 'ما_جرى'], ['ما_جرى']));
      if (/^⚠/.test(d['الحصّة'] || '')) body.appendChild(btn('اضبطِ الحصّة', 'rs-btn', () => periodForm(cs, row)));
      parties(body, cs, row, d, open, closed);
      statements(body, d);
    }
    if (open && staffCase !== true) classifyBox(card, cs, row);
    if (open) closeBox(card, cs, row, staffCase);
    arabize(card);
  }

  async function firstCall(cs, row, decision, why, inForm) {
    const { data, error } = await M.rpc('v2_complaint_first_call', { p_complaint: row['رقم'], p_decision: decision, p_why: why || null }, 'البتّ الأوّل');
    if (error) { if (inForm) return error; flash('bad', errText(error)); return null; }
    flash('ok', (data && data['البيان']) || '');
    reload(cs, Object.assign({}, row, { 'البتّ_الأوّل': (data && data['البتّ']) || '' }));
    return null;
  }

  async function periodForm(cs, row) {
    const { data, error } = await M.rpc('v2_periods', { p_school: school() }, 'حصص المدرسة');
    if (error) { flash('bad', errText(error)); return; }
    V.form({
      title: 'اضبطِ الحصّة', what: row['المرجع'],
      fields: [{ key: 'p', type: 'pick', label: 'الحصّة', items: (data || []).map((p) => [p.no, p.no_ar || String(p.no)]) }],
      ok: 'احفظ',
      onOk: async (v) => {
        const r = await M.rpc('v2_complaint_set_period', { p_complaint: row['رقم'], p_period: v.p }, 'ضبط حصّة الواقعة');
        if (r.error) return r.error;
        flash('ok', [r.data && r.data['الشكوى'], r.data && r.data['الحصّة']].filter(Boolean).join(' · '));
        openCase(cs, row);
        return null;
      },
    });
  }

  // الأطرافُ وأفعالُ كلٍّ بدوره (الدورُ بلفظ القاعدة)
  function parties(body, cs, row, d, open, closed) {
    const list = d['الأطراف'] || [];
    body.appendChild(el('h4', 'rs-sub', 'الأطراف'));
    for (const p of list) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [p['الاسم'], p['الدور']].filter(Boolean).join(' · ')));
      f.appendChild(el('p', null, [['أدلى', p['أدلى']], ['عُرضت عليه', p['عُرضت_عليه']], ['سُئل', p['سُئل']]]
        .filter(([, v]) => v != null).map(([k, v]) => k + ' ' + (yes(v) ? '✓' : '—')).join(' · ')));
      if (p['جوابه']) f.appendChild(el('p', null, p['جوابه']));
      const acts = el('div', 'rs-row');
      const teacher = p['الدور'] === 'شاهد — معلّم';
      const accused = p['الدور'] === 'مشتكًى عليه';
      if (open && accused) acts.appendChild(btn('اعرضْ عليه ما قيل', 'rs-btn soft', () => showAccused(p)));
      if (open && !teacher && !yes(p['أدلى'])) acts.appendChild(btn('دوِّنْ إفادتَه', 'rs-btn', () => statementForm(cs, row, p)));
      if (open && teacher && !yes(p['سُئل'])) acts.appendChild(btn('اسألِ المعلّم', 'rs-btn', () => askTeacher(cs, row, p)));
      // شهادةُ الزور: بعدَ الإقفال وحدَه · ولا تظهر على المشتكى عليه
      if (closed && !accused) acts.appendChild(btn('شهادةُ زور', 'rs-btn ghost', () => perjuryForm(p)));
      if (acts.children.length) f.appendChild(acts);
      body.appendChild(f);
    }
    if (open) body.appendChild(btn('أضفْ طرفًا', 'rs-btn soft', () => partyForm(cs, row)));
  }

  function statements(body, d) {
    const list = d['الأقوال'] || [];
    body.appendChild(el('h4', 'rs-sub', 'الأقوال'));
    if (d['تنبيه']) body.appendChild(el('div', 'rs-note', d['تنبيه']));
    if (!list.length) { body.appendChild(el('p', 'rs-empty', 'لا أقوالَ بعد.')); return; }
    for (const s of list) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [s['القائل'], s['صفته']].filter(Boolean).join(' · ')));
      f.appendChild(typed(s['قوله'] || '', 'div', 'rs-said'));
      f.appendChild(el('p', null, [s['التعهّد'], s['وقّع'] != null ? 'وقّع ' + (yes(s['وقّع']) ? '✓' : '—') : null, s['متى'], s['دوّنها']].filter(Boolean).join(' · ')));
      body.appendChild(f);
    }
  }

  // الورقةُ المعروضةُ على المشتكى عليه — بلا أسماءِ شهود (من الباب) · وتُطبع كما هي
  async function showAccused(p) {
    const { data, error } = await M.rpc('v2_complaint_show_accused', { p_party: p['طرف'] }, 'العرض على المشتكى عليه');
    if (error) { flash('bad', errText(error)); return; }
    const sheet = (data && data['الورقة']) || '';
    const print = () => {
      const w = window.open('', '_blank');
      if (!w) return;
      w.document.write('<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><title>' + (data['الشكوى'] || '') +
        '</title><style>body{font-family:"IBM Plex Sans Arabic",sans-serif;padding:32px;line-height:2;white-space:pre-line;font-size:16px}</style></head><body></body></html>');
      w.document.body.textContent = sheet;
      w.document.close(); w.focus(); w.print();
    };
    V.form({
      title: 'الورقةُ المعروضة', what: [data['الشكوى'], p['الاسم']].filter(Boolean).join(' · '),
      fields: [{ key: 's', type: 'node', node: typed(sheet, 'div', 'rs-said') }, { key: 'n', type: 'node', node: el('p', 'rs-meta', data['ملاحظة'] || '') }],
      ok: 'اطبعْها', onOk: async () => { print(); return null; },
    });
  }

  // تعهّدُ الإفادة عند الوكيل: من v2_my_pledge بلا طرف (المدرسةُ من صفته) — فالطرفُ لا يُفتح إلّا لصاحبه
  async function statementForm(cs, row, p) {
    const pl = await pledge('statement');
    if (pl.error) { flash('bad', errText(pl.error)); return; }
    V.form({
      title: 'إفادةُ ' + (p['الاسم'] || ''), what: [row['المرجع'], p['الدور']].filter(Boolean).join(' · '),
      fields: [{ key: 'body', type: 'textarea', label: 'قولُه', rows: 5 }, { key: 'sign', type: 'sign', label: pl.text }],
      ok: 'سجِّلْها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_statement', { p_party: p['طرف'], p_body: v.body, p_strokes: v.sign }, 'تدوين إفادة');
        if (error) return error;
        flash('ok', [data && data['الإفادة'], data && data['بقي']].filter(Boolean).join(' · '));
        reload(cs, row);
        return null;
      },
    });
  }

  async function askTeacher(cs, row, p) {
    const { data, error } = await M.rpc('v2_complaint_ask_teacher', { p_party: p['طرف'] }, 'سؤال المعلّم الشاهد');
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', (data && (data['البيان'] || data['سُئل'])) || 'سُئل المعلّم');
    reload(cs, row);
  }

  async function partyForm(cs, row) {
    const st = await staffList();
    const stu = studentFinder(false);
    const per = staffPicker(st, false);
    V.form({
      title: 'أضفْ طرفًا', what: row['المرجع'],
      fields: [
        { key: 'role', type: 'pick', label: 'الدور', value: 'witness_student',
          items: [['accused', 'مشتكًى عليه'], ['witness_student', 'شاهد — طالب'], ['witness_teacher', 'شاهد — معلّم'], ['affected', 'متضرِّر']] },
        nodeField('s', 'الطالب', stu.node, (v) => v.role !== 'witness_teacher'),
        nodeField('p', 'المنسوب', per.node, (v) => v.role === 'witness_teacher' || v.role === 'accused'),
      ],
      ok: 'أضفْه',
      onOk: async (v) => {
        const useP = v.role === 'witness_teacher' || (v.role === 'accused' && !stu.one());
        const { data, error } = await M.rpc('v2_complaint_party_add', {
          p_complaint: row['رقم'], p_role: v.role, p_student: useP ? null : stu.one(), p_person: useP ? per.one() : null,
        }, 'إضافة طرف');
        if (error) return error;
        flash('ok', [data && data['الشكوى'], data && data['أُضيف']].filter(Boolean).join(' · '));
        reload(cs, row);
        return null;
      },
    });
  }

  function perjuryForm(p) {
    V.form({
      title: 'شهادةُ زور', what: [p['الاسم'], p['الدور']].filter(Boolean).join(' · '),
      fields: [{ key: 'note', type: 'textarea', label: 'ما ثبتَ به تعمُّدُ الكذب' }],
      ok: 'سجِّلْها', okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_perjury', { p_party: p['طرف'], p_note: v.note }, 'شهادة الزور');
        if (error) return error;
        flash('ok', Object.values(data || {}).filter((x) => typeof x === 'string').join(' · '));
        return null;
      },
    });
  }

  // ---------- التصنيف: ثلاثةُ مرشّحين أو لا شيء — ولا يُختارُ الأوّلُ آليًّا · والبحثُ في الدليل دائمًا ----------
  const MATCH = (m) => (/^قويّة/.test(m || '') ? 'm-strong' : /^متوسّطة/.test(m || '') ? 'm-mid' : 'm-weak');
  function classifyBox(card, cs, row) {
    const sec = el('details', 'rs-dt');
    sec.appendChild(el('summary', null, 'التصنيف'));
    const body = el('div', 'rs-dtb');
    sec.appendChild(body);
    const cands = el('div');
    const search = el('div');
    // «أو ابحثْ في الـ… بنفسك» — والعددُ عددُ بنودِ مدرستِك كما يرجع من v2_problems
    const gb = btn('أو ابحثْ في الدليلِ بنفسك', 'rs-btn soft', () => guideSearch(search, cs, row));
    body.append(btn('اقترحِ البند', 'rs-btn', () => suggest(cands, cs, row)), cands, gb, search);
    card.appendChild(sec);
    loadGuide().then((g) => { if (g && g.items.length) gb.textContent = 'أو ابحثْ في الـ' + V.ar(g.items.length) + ' بنفسك'; });
  }
  async function suggest(box, cs, row) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_complaint_suggest', { p_complaint: row['رقم'] }, 'اقتراح البند');
    if (error) { errBox(box, error); return; }
    const rows = data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'لا مرشّح — ابحثْ في الدليلِ بنفسك')); return; }
    for (const c of rows) {
      const f = el('div', 'rs-cand ' + MATCH(c['المطابقة']));
      f.append(el('p', 'rs-meta', [c['الدرجة'], c['رقم_البند'], c['الصفحة'], c['المادّة']].filter(Boolean).join(' · ')),
        el('b', null, c['النصّ'] || ''), el('p', 'rs-meta', c['المطابقة'] || ''));
      f.appendChild(btn('اعتمدْ هذا البند', 'rs-btn soft', () => classify(cs, row, c['بند'])));
      box.appendChild(f);
    }
    arabize(box);
  }
  let guide = null;
  async function loadGuide() {
    if (guide && guide.school === school()) return guide;
    const { data, error } = await M.rpc('v2_problems', { p_school: school(), p_degree: null }, 'بنود الدليل');
    if (error) return { error };
    guide = { school: school(), items: (data && data.items) || [], note: data && data.note_ar };
    return guide;
  }
  async function guideSearch(box, cs, row) {
    box.textContent = '';
    const g = await loadGuide();
    if (g.error) { errBox(box, g.error); return; }
    if (guide.note) box.appendChild(el('p', 'rs-meta', guide.note));
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث بالدرجة أو النصّ';
    const list = el('div');
    const draw = () => {
      list.textContent = '';
      const t = q.value.trim();
      let n = 0;
      for (const p of guide.items) {
        if (t && !((p.text || '') + ' ' + (p.degree_ar || '')).includes(t)) continue;
        if (++n > 30) break;
        const f = el('div', 'rs-cand');
        f.append(el('p', 'rs-meta', [p.degree_ar, p.page_ar].filter(Boolean).join(' · ')), el('b', null, p.text || ''));
        f.appendChild(btn('اعتمدْه', 'rs-btn soft', () => classify(cs, row, p.id)));
        list.appendChild(f);
      }
      if (!n) list.appendChild(el('p', 'rs-empty', 'لا نتائج.'));
      arabize(list);
    };
    q.addEventListener('input', draw);
    box.append(q, list);
    draw();
  }
  async function classify(cs, row, problem) {
    const { data, error } = await M.rpc('v2_complaint_classify', { p_complaint: row['رقم'], p_problem: problem }, 'تأكيد التصنيف');
    if (error) { flash('bad', errText(error)); return; }
    flash('ok', [data && data['الشكوى'], data && data['التصنيف']].filter(Boolean).join(' · '));
    reload(cs, row);
  }

  // ---------- الإقفال: على طالبٍ بأربعة مخارج · وعلى منسوبٍ بخمسةِ أزرارٍ مرتّبة ----------
  const OUTCOMES = [['recorded', 'ثبتت'], ['not_proven', 'لم تثبت'], ['honest_mistake', 'خطأٌ غيرُ مقصود'], ['false_deliberate', 'كاذبةٌ متعمِّدة']];
  function closeBox(card, cs, row, staffCase) {
    const out = el('div');
    // الطالب
    const s1 = el('details', 'rs-dt');
    s1.appendChild(el('summary', null, 'الإقفالُ — والمشتكى عليه طالب'));
    const b1 = el('div', 'rs-dtb rs-row');
    for (const [k, t] of OUTCOMES) b1.appendChild(btn(t, 'rs-btn' + (k === 'false_deliberate' ? ' ghost' : ' soft'), () => closeForm(cs, row, k, t, out)));
    s1.appendChild(b1);
    // المنسوب
    const s2 = el('details', 'rs-dt');
    s2.appendChild(el('summary', null, 'البتُّ — والمشتكى عليه منسوب'));
    const b2 = el('div', 'rs-dtb');
    const r2 = el('div', 'rs-row');
    r2.append(btn('لا أساسَ لها', 'rs-btn soft', () => staffForm(cs, row, 'no_basis', 'لا أساسَ لها', out)),
      btn('⭐ جلستُ معه وعولجت', 'rs-btn pri', () => staffForm(cs, row, 'met_and_fixed', 'جلستُ معه وعولجت', out)),
      btn('أرفعُها للمدير', 'rs-btn soft', () => staffForm(cs, row, 'to_principal', 'أرفعُها للمدير', out)));
    if (roleKey() === 'principal') r2.appendChild(btn('رُفعت لإدارةِ التعليم', 'rs-btn soft', () => staffForm(cs, row, 'to_education_dept', 'رُفعت لإدارةِ التعليم', out)));
    const harm = el('div', 'rs-harmbox');
    harm.appendChild(btn('🔴 بلاغُ إيذاء', 'rs-btn rs-harm', () => staffForm(cs, row, 'harm_report', 'بلاغُ إيذاء', out)));
    b2.append(r2, harm);
    s2.appendChild(b2);
    if (staffCase !== true) card.appendChild(s1);
    if (staffCase !== false) card.appendChild(s2);
    if (staffCase != null) (staffCase ? s2 : s1).open = true;
    card.appendChild(out);
  }

  function closeForm(cs, row, outcome, title, out) {
    V.form({
      title, what: row['المرجع'],
      fields: [{ key: 'note', type: 'textarea', label: outcome === 'false_deliberate' ? 'البيان' : 'البيان (اختياريّ)' }],
      ok: title, okCls: 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_close', { p_complaint: row['رقم'], p_outcome: outcome, p_note: v.note }, 'إقفال الشكوى');
        if (error) return error;
        closedResult(cs, row, data, out);
        return null;
      },
    });
  }
  function closedResult(cs, row, data, out) {
    boardList(cs.previousElementSibling, cs);
    const d = data || {};
    const keep = el('div');
    keep.appendChild(said(d, ['الشكوى', 'المخرج', 'رُصد_على']));
    const b = el('div', 'rs-said', d['البيان'] || '');
    keep.appendChild(b);
    // تنبيهُ المحضر زرٌّ يفتحه — والسجلُّ برقمه إن رجع
    if (/محضرَ ضبطِ واقعة/.test(d['البيان'] || '')) {
      const rec = d['سجلّ_اللائحة'] || null;
      if (rec) {
        const pan = el('div');
        keep.append(btn('افتحْ محضرَ ضبطِ الواقعة', 'rs-btn', () => minute(pan, rec, d['طالب'] || null)), pan);
      } else {
        const w = el('span', 'rs-off-act');
        const x = btn('افتحْ محضرَ ضبطِ الواقعة', 'rs-btn soft'); x.disabled = true;
        w.append(x, el('small', null, 'لم يُرجِعِ البابُ رقمَ السجلّ — والمحضرُ في سجلِّ الطالب'));
        keep.appendChild(w);
      }
    }
    openCase(cs, row).then(() => { const c = cs.firstChild; if (c) c.insertBefore(keep, c.children[2] || null); arabize(keep); });
    out.textContent = '';
  }

  function staffForm(cs, row, outcome, title, out) {
    V.form({
      title, what: row['المرجع'],
      fields: [{ key: 'note', type: 'textarea', label: outcome === 'met_and_fixed' ? 'ماذا دار وما اتُّفق' : outcome === 'no_basis' ? 'البيان (اختياريّ)' : 'البيان', rows: 4 }],
      ok: title, okCls: outcome === 'harm_report' ? 'rs-btn rs-harm' : 'rs-btn irrev',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_staff_decide', { p_complaint: row['رقم'], p_outcome: outcome, p_note: v.note }, 'البتّ في الشكوى على منسوب');
        if (error) return error;
        const d = data || {};
        const keep = el('div');
        // عدّادُ الجلسات بارزٌ في الرأس · والبيانُ كاملًا (والأحمرُ لا يُخفى) · والصادرُ ورابطُه
        if (d['جلسات_هذي_السنة']) keep.appendChild(el('p', 'rs-big', label('جلسات_هذي_السنة') + ': ' + d['جلسات_هذي_السنة']));
        keep.appendChild(said(d, ['الشكوى', 'المنسوب', 'المخرج']));
        keep.appendChild(el('div', 'rs-said' + (/🔴/.test(d['البيان'] || '') ? ' rs-red' : ''), String(d['البيان'] || '').replace(/\*\*/g, '')));
        if (d['الصادر'] && d['الصادر'] !== '—') {
          const r = el('div', 'rs-row');
          const a = el('a', 'rs-btn soft', 'الصادر: ' + d['الصادر']);
          a.href = 'barid.html';
          r.appendChild(a); keep.appendChild(r);
        }
        boardList(cs.previousElementSibling, cs);
        cs.textContent = '';
        const c = el('div', 'rs-card');
        c.append(el('h3', null, row['المرجع'] || ''), keep);
        cs.appendChild(c);
        arabize(c);
        return null;
      },
    });
  }

  // ---------- تسجيلُ شكوى عن طالب (الوكيل) — ومنها الشكوى على منسوب ----------
  async function fileForDeputy(list, cs) {
    const st = await staffList();
    const owner = studentFinder(false);
    const acc = studentFinder(true);
    const accP = staffPicker(st, false);
    const wS = studentFinder(true);
    const wT = staffPicker(st, true);
    V.form({
      title: 'شكوى عن طالب', what: 'يُستدعى الطالبُ بعدَها ليُدليَ بإفادتِه ويوقّع',
      fields: [
        nodeField('o', 'صاحبُ الشكوى', owner.node),
        { key: 'kind', type: 'pick', label: 'النوع', items: KINDS, value: 'complaint' },
        { key: 'against', type: 'pick', label: 'المشتكى عليه', items: [['student', 'طالب'], ['staff', 'منسوب'], ['deputy', 'الوكيل']], value: 'student' },
        nodeField('a', 'الطلّابُ المشتكى عليهم', acc.node, (v) => v.against === 'student'),
        nodeField('ap', 'المنسوب', accP.node, (v) => v.against === 'staff'),
        { key: 'body', type: 'textarea', label: 'ما جرى', rows: 5 },
        { key: 'on', type: 'date', label: 'تاريخُ الواقعة' },
        { key: 'at', type: 'time', label: 'الساعة' },
        { key: 'place', label: 'المكان' },
        nodeField('ws', 'الشهودُ من الطلّاب', wS.node),
        nodeField('wt', 'الشهودُ من المعلّمين', wT.node),
      ],
      ok: 'سجِّلْها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_file', {
          p_body: v.body, p_on: v.on, p_at: v.at, p_place: v.place, p_kind: v.kind || 'complaint', p_against: v.against || 'student',
          p_accused_students: v.against === 'student' && acc.ids().length ? acc.ids() : null,
          p_accused_person: v.against === 'staff' ? accP.one() : null,
          p_witness_students: wS.ids().length ? wS.ids() : null, p_witness_teachers: wT.ids().length ? wT.ids() : null,
          p_student: owner.one(), p_strokes: null,
        }, 'تسجيل شكوى عن طالب');
        if (error) return error;
        flash('ok', [data && data['البيان'], data && data['إفادتك']].filter(Boolean).join(' — '));
        boardList(list, cs);
        return null;
      },
    });
  }

  // ======================= ③ محضرُ ضبطِ الواقعة (سجلُّ الطالب) =======================
  // يُستدعى لكلّ رصدةٍ في السجلّ: السندُ دائمًا، والزرُّ إن «يلزمُ_محضر»
  async function minuteHook(box, record, student) {
    const { data, error } = await M.rpc('v2_minute_needed', { p_record: record }, 'أيلزمُ محضر');
    if (error) { box.appendChild(el('div', 'rs-meta', errText(error))); return; }
    const d = data || {};
    if (d['السند']) box.appendChild(el('div', 'rs-meta', d['السند']));
    if (yes(d['يلزمُ_محضر']) || d['المحضر']) {
      const pan = el('div');
      box.append(btn('محضرُ ضبطِ الواقعة', 'rs-btn', () => minute(pan, record, student)), pan);
    }
    arabize(box);
  }

  // الحلقة: build ← ما ينقص ← يُملأ ← build ثانيةً حتى يُعتمد
  const FILL = { 'الساعة': 'at', 'وصف الواقعة': 'what', 'الإجراءات المتخذة': 'actions' };
  async function minute(pan, record, student, args) {
    pan.textContent = '';
    pan.appendChild(el('p', 'rs-meta', 'جارٍ…'));
    const { data, error } = await M.rpc('v2_minute_build', Object.assign({ p_record: record, p_what: null, p_at: null, p_actions: null }, args || {}), 'محضر ضبط الواقعة');
    pan.textContent = '';
    if (error) { errBox(pan, error); return; }
    const d = data || {};
    const c = el('div', 'rs-file');
    c.appendChild(el('h5', null, d['النموذج'] || ''));
    c.appendChild(el('p', 'rs-big', d['الحال'] || ''));
    const need = Array.isArray(d['يلزمُه']) ? d['يلزمُه'] : [];
    if (need.length) c.appendChild(el('div', 'rs-note', label('يلزمُه') + ': ' + need.join(' · ')));
    if (d['التوقيع']) c.appendChild(el('p', 'rs-meta', d['التوقيع']));
    const acts = el('div', 'rs-row');
    const fill = need.filter((n) => FILL[n]);
    if (fill.length) acts.appendChild(btn('أكمِلْ ما ينقص', 'rs-btn', () => V.form({
      title: 'محضرُ ضبطِ الواقعة', what: fill.join(' · '),
      fields: fill.map((n) => ({ key: FILL[n], label: n, type: FILL[n] === 'at' ? 'time' : 'textarea' })),
      ok: 'احفظ',
      onOk: async (v) => { minute(pan, record, student, { p_what: v.what || null, p_at: v.at || null, p_actions: v.actions || null }); return null; },
    })));
    acts.append(btn('أضفْ شاهدًا', 'rs-btn soft', () => witnessForm(pan, record, student)),
      btn('أضفْ مضبوطًا', 'rs-btn soft', () => seizureForm(pan, record, student)),
      btn('اعرضِ المحضر', 'rs-btn soft', () => minuteRead(pan, record, student)));
    c.appendChild(acts);
    pan.appendChild(c);
    arabize(pan);
  }
  function witnessForm(pan, record, student) {
    V.form({
      title: 'شاهدُ المحضر', what: 'سبعةٌ أكثرُه',
      fields: [{ key: 'name', label: 'الاسم' }, { key: 'job', label: 'الوظيفة' }, { key: 'work', label: 'العملُ المُسند' }],
      ok: 'أضفْه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_minute_witness_add', { p_record: record, p_name: v.name, p_job: v.job, p_work: v.work }, 'شاهد المحضر');
        if (error) return error;
        flash('ok', [data && data['الشاهد'], data && data['ترتيبه']].filter(Boolean).join(' · '));
        minute(pan, record, student);
        return null;
      },
    });
  }
  function seizureForm(pan, record, student) {
    V.form({
      title: 'المضبوطات', what: 'صور · مقاطع فيديو · محادثات · أخرى',
      fields: [
        { key: 'kind', type: 'pick', label: 'النوع', items: [['صور', 'صور'], ['مقاطع فيديو', 'مقاطع فيديو'], ['محادثات', 'محادثات'], ['أخرى', 'أخرى']] },
        { key: 'other', label: 'اكتبِ النوع', show: (v) => v.kind === 'أخرى' },
        { key: 'desc', type: 'textarea', label: 'الوصف' },
        { key: 'legal', type: 'pick', label: 'مسألةٌ نظاميّة', items: [['no', 'لا'], ['yes', 'نعم']], value: 'no' },
      ],
      ok: 'سجِّلْه',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_minute_seizure_add', {
          p_record: record, p_kind: v.kind, p_description: v.desc, p_is_legal: v.legal === 'yes', p_kind_other: v.kind === 'أخرى' ? v.other : null, p_ref: null,
        }, 'المضبوطات');
        if (error) return error;
        const t = (data && data['تنبيه']) || '';
        flash(/🔴/.test(t) ? 'bad' : 'ok', [data && data['المضبوط'], t].filter(Boolean).join(' — '));
        minute(pan, record, student);
        return null;
      },
    });
  }
  async function minuteRead(pan, record, student) {
    const { data, error } = await M.rpc('v2_minute_read', { p_record: record }, 'قراءة المحضر');
    if (error) { flash('bad', errText(error)); return; }
    const d = data || {};
    const c = el('div', 'rs-file');
    c.appendChild(el('h5', null, [d['النموذج'], d['الحال']].filter(Boolean).join(' — ')));
    const rows = (title, list, keys, raw) => {
      if (!list || !list.length) return;
      c.appendChild(el('div', 'rs-label', title));
      for (const x of list) {
        const p = el('div', 'rs-meta' + (yes(x['مسألةٌ نظاميّة']) ? ' rs-red' : ''));
        p.appendChild(V.line('span', null, keys.map((k) => {
          const v = x[k];
          if (v == null || v === '') return null;
          if (typeof v === 'boolean') return label(k) + ' ' + (v ? '✓' : '—');
          return (raw || []).includes(k) ? typed(v) : String(v);
        })));
        c.appendChild(p);
      }
    };
    rows('الشهود', d['الشهود'], ['ت', 'الاسم', 'الوظيفة', 'العملُ المُسند', 'وقّع'], ['الاسم', 'الوظيفة', 'العملُ المُسند']);
    rows('المضبوطات', d['المضبوطات'], ['النوع', 'الوصف', 'مسألةٌ نظاميّة', 'أُتلف'], ['الوصف']);
    rows('التوقيعات', d['التوقيعات'], ['الموقّع', 'وقّع', 'امتنع', 'السبب'], ['السبب']);
    const wait = Array.isArray(d['ينتظر']) ? d['ينتظر'] : [];
    if (wait.length) {
      c.appendChild(el('div', 'rs-label', label('ينتظر')));
      for (const s of wait) {
        const r = el('div', 'rs-row');
        r.append(el('span', null, s),
          btn('وقّع', 'rs-btn soft', () => sign(pan, record, student, d['المحضر'], s, true, null)),
          btn('امتنعَ عن التوقيع', 'rs-btn ghost', () => V.form({
            title: 'امتنعَ عن التوقيع', what: s,
            fields: [{ key: 'why', type: 'textarea', label: 'السبب' }], ok: 'وثِّقِ الامتناع',
            onOk: async (v) => sign(pan, record, student, d['المحضر'], s, false, v.why),
          })));
        c.appendChild(r);
      }
    }
    // الطباعةُ من النموذج نفسِه (form.html) — بعناوينِ خاناته من القاعدة
    // والطالبُ من الإقفال (طالب) أو من سجلِّه — وبه تُطبع
    if (student) {
      const a = el('a', 'rs-btn soft', 'اطبعِ المحضر');
      a.href = 'form.html?form=11&student=' + encodeURIComponent(student) + '&ref=' + encodeURIComponent(record);
      a.target = '_blank'; a.rel = 'noopener';
      c.appendChild(a);
    }
    pan.appendChild(c);
    arabize(c);
  }
  async function sign(pan, record, student, entry, signer, signed, why) {
    const { data, error } = await M.rpc('v2_form_sign', { p_entry: entry, p_signer: signer, p_signed: signed, p_refuse_reason: signed ? null : why }, signed ? 'التوقيع على المحضر' : 'الامتناع عن التوقيع');
    if (error) { if (!signed) return error; flash('bad', errText(error)); return null; }
    flash('ok', (data && (data.note || data.msg || data['البيان'])) || signer);
    pan.textContent = '';
    minuteRead(pan, record, student);
    return null;
  }

  // ======================= ④ المعلّمُ الشاهد =======================
  async function teacherAsks(box) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_my_complaint_asks', undefined, 'ما سُئلتُ عنه شاهدًا');
    if (error) { errBox(box, error); return; }
    const rows = data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'لا شيءَ ينتظرك.')); return; }
    for (const r of rows) {
      // الصندوق بلا تفصيل: لا شيءَ من الواقعة ولا من الأقوال قبلَ التوقيع
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, r['المرجع'] || ''));
      f.appendChild(kv(r, ['وقعت', 'الساعة', 'المكان', 'مهلة_الجواب', 'المطلوب']));
      const pan = el('div');
      const row = el('div', 'rs-row');
      if (!yes(r['وقّعتُ_السرّيّة'])) row.appendChild(btn('وقّعْ تعهّدَ السرّيّة', 'rs-btn', () => secrecyForm(box, r, pan)));
      else row.appendChild(btn('اقرأْها وأجبْ', 'rs-btn', () => teacherRead(box, r, pan)));
      f.append(row, pan);
      box.appendChild(f);
    }
    arabize(box);
  }
  async function secrecyForm(box, r, pan) {
    const pl = await pledge('secrecy', r['طرف']);
    if (pl.error) { flash('bad', errText(pl.error)); return; }
    V.form({
      title: 'تعهّدُ السرّيّة', what: r['المرجع'],
      fields: [{ key: 'sign', type: 'sign', label: pl.text }],
      ok: 'وقّعْ',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_teacher_sign', { p_party: r['طرف'], p_strokes: v.sign }, 'تعهّد السرّيّة');
        if (error) return error;
        flash('ok', Object.values(data || {}).filter((x) => typeof x === 'string').join(' · '));
        teacherRead(box, Object.assign({}, r, { 'وقّعتُ_السرّيّة': true }), pan);
        return null;
      },
    });
  }
  const ANS_NOTE = {
    deny: 'النفيُ شهادةٌ على الواقعة',
    absent: 'وعدمُ الحضورِ يُسقِطُ من سمّاك شاهدًا',
  };
  async function teacherRead(box, r, pan) {
    pan.textContent = '';
    const { data, error } = await M.rpc('v2_complaint_teacher_read', { p_party: r['طرف'] }, 'قراءة الشاهد');
    if (error) { errBox(pan, error); return; }
    const d = data || {};
    if (d['لماذا_أنت']) pan.appendChild(el('p', 'rs-big', d['لماذا_أنت']));
    pan.appendChild(kv(d, ['وقعت', 'الساعة', 'المكان', 'ما_جرى'], ['ما_جرى']));
    const said2 = d['الأقوال'] || [];
    if (said2.length) {
      pan.appendChild(el('div', 'rs-label', 'الأقوال'));
      for (const s of said2) {
        const f = el('div', 'rs-file');
        f.appendChild(el('h5', null, [s['القائل'], s['صفته']].filter(Boolean).join(' · ')));
        f.appendChild(typed(s['قوله'] || '', 'div', 'rs-said'));
        pan.appendChild(f);
      }
    }
    if (d['تنبيه']) pan.appendChild(el('div', 'rs-note', d['تنبيه']));
    // الجوابُ أربعةُ أزرار — نصوصُها من الباب (الرمز — النصّ)
    const ans = el('div', 'rs-ans');
    for (const a of Array.isArray(d['جوابك']) ? d['جوابك'] : []) {
      const i = String(a).indexOf(' — ');
      const code = i > 0 ? String(a).slice(0, i).trim() : String(a);
      const text = i > 0 ? String(a).slice(i + 3) : String(a);
      const b = btn('', 'rs-btn soft', () => answerForm(box, r, code, text));
      b.appendChild(el('span', null, text));
      if (ANS_NOTE[code]) b.appendChild(el('small', null, ANS_NOTE[code]));
      ans.appendChild(b);
    }
    pan.appendChild(ans);
    arabize(pan);
  }
  function answerForm(box, r, code, text) {
    V.form({
      title: text, what: r['المرجع'],
      fields: [{ key: 'note', type: 'textarea', label: code === 'knows' ? 'روايتُك' : 'ملاحظة (اختياريّة)', rows: 4 }],
      ok: 'أرسِلْ جوابي',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_complaint_teacher_answer', { p_party: r['طرف'], p_answer: code, p_note: v.note }, 'جواب الشاهد');
        if (error) return error;
        flash('ok', Object.values(data || {}).filter((x) => typeof x === 'string').join(' · '));
        teacherAsks(box);
        return null;
      },
    });
  }

  // ======================= ⑤ لوحةُ التحكّم =======================
  async function hintsTool(box) {
    box.textContent = '';
    box.appendChild(el('div', 'rs-note', 'كلّما أقررتَ كلمةً أصابَ النظامُ أكثر — والدفترُ يبدأُ فارغًا عمدًا'));
    const [h, p] = await Promise.all([
      M.rpc('v2_complaint_hints', { p_school: school() }, 'الكلمات الدالّة'),
      M.rpc('v2_problems', { p_school: school(), p_degree: null }, 'بنود الدليل'),
    ]);
    const items = (p.data && p.data.items) || [];
    // الربط: كلمة + بندٌ يُبحث عنه بالدرجة والنصّ + زرّ
    const add = el('div', 'rs-file');
    const lw = el('label', null, 'الكلمة'); const w = el('input'); w.type = 'text'; w.id = 'hintWord'; lw.htmlFor = w.id;
    const q = el('input'); q.type = 'search'; q.placeholder = 'ابحث في البنود بالدرجة أو النصّ';
    const list = el('div');
    let chosen = null;
    const draw = () => {
      list.textContent = '';
      const t = q.value.trim();
      if (!t) return;
      let n = 0;
      for (const x of items) {
        if (!((x.text || '') + ' ' + (x.degree_ar || '')).includes(t)) continue;
        if (++n > 25) break;
        const b = btn('', 'rs-item' + (chosen === x.id ? ' on' : ''), () => { chosen = x.id; draw(); });
        b.append(el('span', null, x.text || ''), el('small', null, [x.degree_ar, x.page_ar].filter(Boolean).join(' · ')));
        list.appendChild(b);
      }
      if (!n) list.appendChild(el('p', 'rs-empty', 'لا نتائج.'));
      arabize(list);
    };
    q.addEventListener('input', draw);
    const go = btn('اربطْ', 'rs-btn', async () => {
      const { data, error } = await M.rpc('v2_complaint_hint_set', { p_school: school(), p_word: w.value.trim(), p_problem: chosen, p_on: true }, 'إقرار كلمة');
      if (error) { flash('bad', errText(error)); return; }
      flash('ok', [data && data['الكلمة'], data && data['تدلّ_على'], data && data['الحال']].filter(Boolean).join(' · '));
      hintsTool(box);
    });
    if (p.error) errBox(add, p.error);
    add.append(lw, w, q, list, go);
    box.appendChild(add);
    if (h.error) { errBox(box, h.error); return; }
    const rows = h.data || [];
    // البابُ الفارغُ صحيح: الدفترُ يبدأ فارغًا عمدًا
    if (!rows.length) { box.appendChild(el('p', 'rs-empty', 'ما في كلماتٍ مُقرّةٍ بعد.')); arabize(box); return; }
    for (const r of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [r['الكلمة'], r['الحال']].filter(Boolean).join(' · ')));
      f.appendChild(el('p', null, [r['الدرجة'], r['رقم_البند'], r['النصّ']].filter(Boolean).join(' · ')));
      // البابُ يطلب رقمَ البند — يُعرف بنصّه ودرجتِه من بنود الدليل، فإن لم يتعيّن بقي الزرُّ معطّلًا
      // التعطيلُ لا الحذف — بـ «بند» كما يرجع من v2_complaint_hints
      const on = !/معطّل|موقوف/.test(r['الحال'] || '');
      f.appendChild(btn(on ? 'عطِّلْها' : 'فعِّلْها', 'rs-btn soft', async () => {
        const { data, error } = await M.rpc('v2_complaint_hint_set', { p_school: school(), p_word: r['الكلمة'], p_problem: r['بند'], p_on: !on }, on ? 'تعطيل كلمة' : 'تفعيل كلمة');
        if (error) { flash('bad', errText(error)); return; }
        flash('ok', [data && data['الكلمة'], data && data['الحال']].filter(Boolean).join(' · '));
        hintsTool(box);
      }));
      box.appendChild(f);
    }
    arabize(box);
  }

  // ======================= لوحةُ تحكّمِ الشكوى (تكليف ٢٤) =======================
  // v2_complaint_settings بأقسامه الخمسة بترتيبها · المفاتيحُ والنصوصُ بـ v2_complaint_setting_set (القيمةُ نصٌّ دائمًا)
  // والأرقامُ ببابها القائم v2_rule_set — ومع كلِّ رقمٍ سندُه وعلّتُه · ومع كلِّ مفتاحٍ بيانُه · والتنبيهُ بعدَ الحفظ بارز
  const SCOPES = [['section', 'فصلُه'], ['school', 'مدرستُه'], ['complex', 'المجمّع']];
  const latin = (v) => String(v == null ? '' : v).replace(/[٠-٩]/g, (d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d));
  async function settingsTool(box) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_complaint_settings', { p_school: school() }, 'لوحة الشكوى');
    if (error) { errBox(box, error); return; }
    const d = data || {};
    box.appendChild(el('p', 'rs-meta', [d['المدرسة'], d['آخرُ_ضبط'] ? label('آخرُ_ضبط') + ': ' + d['آخرُ_ضبط'] : null].filter(Boolean).join(' · ')));
    const after = (f, r) => {
      // ما رجع من الحفظ — والتنبيهُ بارزٌ أحمرُ لا يُبتلَع
      const t = r && r['تنبيه'];
      if (t) f.appendChild(el('div', 'rs-said rs-red', t));
      flash(t ? 'bad' : 'ok', [r && (r['البيان'] || r['الحال'] || r.msg || r.note), t].filter(Boolean).join(' — ') || 'حُفظ');
    };
    const sec = (title) => { box.appendChild(el('h4', 'rs-sub', title)); };

    // أ · الأرقام
    sec(label('الأرقام'));
    for (const n of d['الأرقام'] || []) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, n['العنوان'] || n['مفتاح']));
      f.appendChild(kv(n, ['القيمة', 'الوحدة', 'الأدنى', 'الأعلى', 'السند', 'العلّة']));
      const b = btn('عدّلْه', 'rs-btn soft', () => V.form({
        title: n['العنوان'], what: [n['السند'], n['العلّة']].filter(Boolean).join(' — '),
        fields: [{ key: 'v', type: 'number', label: label('القيمة') + (n['الوحدة'] ? ' (' + n['الوحدة'] + ')' : ''), value: latin(n['القيمة']) },
          { key: 'why', type: 'textarea', label: 'السبب' }],
        ok: 'احفظ',
        onOk: async (v) => {
          const r = await M.rpc('v2_rule_set', { p_school: school(), p_key: n['مفتاح'], p_value: v.v, p_why: v.why }, 'ضبط رقم');
          if (r.error) return r.error;
          settingsTool(box).then(() => flash('ok', Object.values(r.data || {}).filter((x) => typeof x === 'string').join(' · ') || 'حُفظ'));
          return null;
        },
      }));
      // يُعدَّل = false ⇒ رقمٌ لا تملكه المدرسة: مقفل
      if (n['يُعدَّل'] === false) { b.disabled = true; b.title = 'لا تملكُ المدرسةُ تغييرَه'; }
      f.appendChild(b);
      box.appendChild(f);
    }

    // ب · المفاتيح
    sec(label('المفاتيح'));
    for (const k of d['المفاتيح'] || []) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, k['العنوان'] || k['مفتاح']));
      if (k['البيان']) f.appendChild(el('p', /⚠|🔴/.test(k['البيان']) ? 'rs-red' : null, k['البيان']));
      const items = k['مفتاح'] === 'names_scope' ? SCOPES : [['true', 'نعم'], ['false', 'لا']];
      let val = String(k['القيمة']);
      const pk = el('div', 'rs-pick');
      V.pick(pk, items, val, (v) => { val = v; });
      const save = btn('احفظ', 'rs-btn soft', async () => {
        const { data: r, error: e } = await M.rpc('v2_complaint_setting_set', { p_school: school(), p_key: k['مفتاح'], p_value: val }, 'ضبط الشكوى');
        if (e) { flash('bad', errText(e)); return; }
        after(f, r);
      });
      f.append(pk, save);
      box.appendChild(f);
    }

    // ج · نصوصُ التعهّد — وإفراغُه يردُّه إلى البيتيّ
    sec(label('نصوصُ_التعهّد'));
    for (const t of d['نصوصُ_التعهّد'] || []) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, t['العنوان'] || t['مفتاح']));
      f.appendChild(el('p', 'rs-meta', t['بيدِ_المدرسة'] ? 'كتبَتْه المدرسة' : 'النصُّ البيتيّ'));
      if (t['البيان']) f.appendChild(el('p', null, t['البيان']));
      const ta = el('textarea'); ta.rows = 3; ta.value = t['القيمة'] || ''; ta.setAttribute('aria-label', t['العنوان'] || '');
      const put = async (v) => {
        const { data: r, error: e } = await M.rpc('v2_complaint_setting_set', { p_school: school(), p_key: t['مفتاح'], p_value: v }, 'نصّ التعهّد');
        if (e) { flash('bad', errText(e)); return; }
        after(f, r);
        settingsTool(box);
      };
      const row = el('div', 'rs-row');
      row.append(btn('احفظ', 'rs-btn soft', () => put(ta.value.trim())), btn('أعِدْه كما كان', 'rs-btn ghost', () => put('')));
      f.append(ta, row);
      box.appendChild(f);
    }

    // د · الكلماتُ الدالّة — بابُها القائم
    sec(label('الكلماتُ_الدالّة'));
    const hb = el('div');
    box.appendChild(hb);
    hintsTool(hb);

    // هـ · أوزانُ البندين — تُضبط من لوحةِ أوزان الممارسات نفسِها
    sec(label('أوزانُ_البندين'));
    const w = d['أوزانُ_البندين'] || {};
    const wf = el('div', 'rs-file');
    // الرمزُ لاتينيٌّ كما هو (data-raw) · والوزنُ كما رجع
    for (const code of ['cmp_false', 'cmp_perjury']) wf.appendChild(V.line('p', null, [typed(code), w[code] == null ? '—' : String(w[code])], ': '));
    if (w['البيان']) wf.appendChild(el('p', null, w['البيان']));
    // لوحةُ أوزان الممارسات نفسُها (تكليف ٢٦) — تُفتح هنا على السالبة والبحثُ بالرمز
    const wb = el('div');
    wf.append(btn('لوحةُ أوزانِ الممارسات', 'rs-btn soft', () => window.MoayadAwzan.tool(wb, { polarity: 'negative', q: 'cmp_' })), wb);
    box.appendChild(wf);
    arabize(box);
  }

  // تاريخُ الشكاوى على منسوب — في صفحتِه عندَ المدير · والبابُ يردُّ غيرَه برسالتِه
  async function staffOf(box, person) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_staff_complaints_of', { p_person: person }, 'الشكاوى على منسوب');
    if (error) { errBox(box, error); return; }
    const rows = data || [];
    if (!rows.length) { box.appendChild(el('div', 'meta', 'لا شكاوى عليه.')); return; }
    for (const r of rows) {
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, [r['المرجع'], r['الحال']].filter(Boolean).join(' · ')));
      f.appendChild(kv(r, ['وقعت', 'المكان', 'المخرج', 'جلسة', 'الصادر']));
      if (r['البيان']) f.appendChild(el('div', 'rs-said' + (/🔴/.test(r['البيان']) ? ' rs-red' : ''), String(r['البيان']).replace(/\*\*/g, '')));
      box.appendChild(f);
    }
    arabize(box);
  }

  window.MoayadShakwa = { studentCard, deputy, minuteHook, teacherAsks, hintsTool, settingsTool, staffOf, signPad: V.signPad };
})();
