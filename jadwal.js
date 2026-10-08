// مؤيّد · جدولُ الحصص في لوحة التحكّم — خمسةُ أبواب: الجدول · النصاب · خطّةُ المواد · تخصّصاتُ المعلّمين · التوزيعُ الآليّ.
// v2_timetable_board · v2_slot_check · v2_slot_save · v2_slot_delete
// v2_quota_board · v2_quota_save · v2_plan_save · v2_plan_remove · v2_teacher_subject · v2_posts_list · v2_staff_list
// v2_timetable_suggest · v2_draft_card · v2_draft_apply · v2_draft_cancel · v2_drafts_list
// 🔑 النظامُ يعرض والإنسانُ يقرّر: التضاربُ يُعرض قبل الحفظ ولا يُتجاوز إلا بإقرار، والمقترحُ لا يُثبَّت إلا بكتابة «أقرّ».
// ولا حسابَ هنا: الحملُ والنصابُ والميزانُ كلُّها من القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { ar, arabize, btn, flash, pick } = V;

  const KINDS = [['teaching', 'تدريس'], ['standby', 'انتظار'], ['activity', 'نشاط']];
  const school = () => M.state.school;
  const st = { mode: 'person', person: null, section: null, staff: null };

  async function staff() {
    // القائمةُ لمدرستها — فإن تبدّلت المدرسةُ جُلبت من جديد
    if (st.staff && st.staffSchool === school()) return st.staff;
    st.staffSchool = school();
    const { data, error } = await M.rpc('v2_staff_list', { p_school: school() }, 'قائمة المنسوبين');
    if (error) { flash('bad', errText(error)); return null; }
    st.staff = data || [];
    return st.staff;
  }
  const staffItems = (l) => (l || []).map((p) => [p.person_id, p.name_ar, p.post_ar || p.roles_ar || '']);
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));

  // ================= ١ · جدولُ الحصص =================
  async function timetableTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ جلب الجدول…'));
    const [b, sl] = await Promise.all([
      M.rpc('v2_timetable_board', { p_school: school(), p_person: null, p_section: null, p_weekday: null }, 'جدول الحصص'),
      staff(),
    ]);
    box.textContent = '';
    if (b.error) { errBox(box, b.error); return; }
    const board = b.data || {};
    const slots = board.slots || [];
    const periods = board.periods || [];
    const days = board.days || [];
    // الفصولُ من فصول المدرسة (class_sections) كما يرجعها اللوحُ — لا من الحصص القائمة
    const sections = (board.sections || []).map((c) => [c.id, c.label]);
    if (!st.person && (board.load || []).length) st.person = board.load[0].person_id;
    if (!st.section && sections.length) st.section = sections[0][0];

    const modeBox = el('div', 'rs-pick');
    pick(modeBox, [['person', 'جدولُ معلّم'], ['section', 'جدولُ فصل']], st.mode, (v) => { st.mode = v; timetableTool(box); });
    box.appendChild(modeBox);
    const whoBox = el('div');
    box.appendChild(whoBox);
    if (st.mode === 'person') V.chooser(whoBox, staffItems(sl), st.person, (v) => { st.person = v; timetableTool(box); });
    else V.chooser(whoBox, sections.map(([id, lb]) => [id, lb, '']), st.section, (v) => { st.section = v; timetableTool(box); });

    const mine = slots.filter((x) => (st.mode === 'person' ? x.person_id === st.person : x.section_id === st.section));
    const wrap = el('div', 'rs-tablewrap');
    const t = el('table', 'rs-table rs-grid');
    const hr = el('tr');
    hr.appendChild(el('th', null, ''));
    for (const p of periods) hr.appendChild(el('th', null, p.no_ar || String(p.no)));
    t.appendChild(hr);
    // الأيّامُ من القاعدة {no, label}: الأحدُ ٠ والخميسُ ٤ — والحفظُ يرسل no نفسَه
    days.forEach((d) => {
      const wd = d.no;
      const dname = d.label;
      const tr = el('tr');
      tr.appendChild(el('th', null, dname));
      for (const p of periods) {
        const here = mine.filter((x) => x.weekday === wd && x.period === p.no);
        const td = el('td', 'click' + (here.length ? ' on k-' + here[0].kind : ''));
        td.tabIndex = 0;
        if (here.length) {
          for (const x of here) {
            td.appendChild(el('b', null, x.subject || x.kind_ar));
            td.appendChild(el('div', 'rs-meta', st.mode === 'person' ? (x.section || x.kind_ar) : (x.person || '—')));
          }
          if (here.length > 1) td.appendChild(el('div', 'rs-state-open', 'متضاربة'));
        } else td.appendChild(el('span', 'rs-meta', '＋'));
        const open = () => slotForm(box, wd, dname, p, here[0] || null, sections, sl);
        td.addEventListener('click', open);
        td.addEventListener('keydown', (e) => { if (e.key === 'Enter') open(); });
        tr.appendChild(td);
      }
      t.appendChild(tr);
    });
    wrap.appendChild(t);
    box.appendChild(wrap);

    // الحملُ كما أرجعته القاعدة
    const det = el('details', 'rs-dt');
    det.appendChild(el('summary', null, 'حملُ المعلّمين (' + (board.load || []).length + ')'));
    const lt = el('table', 'rs-table');
    lt.style.minWidth = '0';
    const lh = el('tr');
    for (const h of ['المعلّم', 'تدريس', 'انتظار', 'نشاط', 'المجموع']) lh.appendChild(el('th', null, h));
    lt.appendChild(lh);
    for (const l of board.load || []) {
      const r = el('tr');
      for (const v of [l.person, l.teaching, l.standby, l.activity, l.total]) r.appendChild(el('td', null, String(v == null ? '—' : v)));
      lt.appendChild(r);
    }
    const dd = el('div', 'rs-dtb');
    dd.appendChild(lt);
    det.appendChild(dd);
    box.appendChild(det);
    arabize(box);
  }

  function slotForm(box, wd, dname, p, x, sections, sl) {
    const fields = [
      { key: 'kind', type: 'pick', label: 'نوعُ الحصّة', items: KINDS, value: x ? x.kind : 'teaching' },
      { key: 'section', type: 'choose', label: 'الفصل (للتدريس)', items: sections.map(([id, lb]) => [id, lb, '']), value: x ? x.section_id : (st.mode === 'section' ? st.section : null) },
      { key: 'person', type: 'choose', label: 'المعلّم', items: staffItems(sl), value: x ? x.person_id : (st.mode === 'person' ? st.person : null) },
      { key: 'subject', label: 'المادّة', value: x ? x.subject : null },
      { key: 'room', label: 'المكان (اختياري)', value: x ? x.room : null },
      { key: 'note', label: 'ملاحظة (اختياري)', value: x ? x.note : null },
      { key: 'force', type: 'pick', label: 'إن ظهر تضارب', items: [['no', 'لا تحفظ'], ['yes', 'أُقرّ بالتضارب واحفظ']], value: 'no',
        hint: 'يُفحص التضاربُ قبل الحفظ ويُعرض هنا — ولا يُتجاوز إلا بإقرارك' },
    ];
    const extra = [];
    if (x) {
      extra.push({ text: 'احذف الحصّة', cls: 'rs-btn ghost', onClick: (v) => deleteForm(box, x, v) });
    }
    V.form({
      title: (x ? 'حصّة ' : 'حصّةٌ جديدة · ') + dname + ' · الحصّة ' + (p.no_ar || p.no), what: x ? [x.kind_ar, x.section, x.person].filter(Boolean).join(' · ') : '',
      fields, ok: 'احفظ', extra,
      onOk: async (v) => {
        const args = { p_school: school(), p_slot: x ? x.id : null, p_weekday: wd, p_period: p.no, p_section: v.kind === 'teaching' ? v.section : (v.section || null), p_person: v.person, p_kind: v.kind };
        // ١ · افحص قبل الحفظ، واعرض التضارب
        const chk = await M.rpc('v2_slot_check', args, 'فحص التضارب');
        if (chk.error) return chk.error;
        const conf = (chk.data && chk.data.conflicts) || [];
        if (conf.length && v.force !== 'yes') return 'تضارب: ' + conf.map((c) => c.text).join(' · ') + ' — فإن أردتَه فاختر «أُقرّ بالتضارب واحفظ»';
        // ٢ · احفظ — والقاعدةُ تفحص ثانيةً وترفض إن لم يُقرّ
        const { data, error } = await M.rpc('v2_slot_save', Object.assign({}, args, { p_subject: v.subject, p_room: v.room, p_note: v.note, p_force: v.force === 'yes' }), 'حفظ الحصّة');
        if (error) return error;
        flash('ok', (data && data.mode ? data.mode : 'حُفظت') + ' الحصّة' + (data && data.forced ? ' — مع إقرارك بالتضارب' : ''));
        timetableTool(box);
        return null;
      },
    });
  }

  function deleteForm(box, x) {
    // الحذفُ يطلب سببًا — فيُفتح لوحُه بعد إغلاق لوح الحصّة
    setTimeout(() => V.form({
      title: 'حذفُ الحصّة', what: [x.weekday_ar, 'الحصّة ' + x.period_ar, x.subject, x.section, x.person].filter(Boolean).join(' · '),
      fields: [{ key: 'why', type: 'textarea', label: 'السبب', rows: 2 }],
      ok: 'احذفها',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_slot_delete', { p_slot: x.id, p_reason: v.why }, 'حذف الحصّة');
        if (error) return error;
        flash('ok', 'حُذفت الحصّة');
        timetableTool(box);
        return null;
      },
    }), 0);
    return null;
  }

  // ================= لوحُ النصاب والخطّة والتخصّصات: v2_quota_board =================
  async function quotaBoard(box) {
    box.textContent = '';
    const { data, error } = await M.rpc('v2_quota_board', { p_school: school() }, 'النصاب والخطّة');
    if (error) { errBox(box, error); return null; }
    return data || {};
  }

  // ================= ٢ · النصاب لكلّ صفة =================
  async function quotaTool(box) {
    const q = await quotaBoard(box);
    if (!q) return;
    const list = q.quota || [];
    if (!list.length) box.appendChild(el('p', 'rs-meta', 'لم يُضبط نصابٌ بعد — والاقتراحُ الآليُّ يقف عند ٢٤ حصّةً لمن لا نصابَ له.'));
    for (const r of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, r.post_ar || r.post),
        el('p', null, ['الأدنى ' + (r.min_ar || '—'), 'الأعلى ' + (r.max_ar || '—'), r.standby_max != null ? 'الانتظارُ حتى ' + r.standby_max : null, r.note].filter(Boolean).join(' · ')));
      f.appendChild(btn('عدّل', 'rs-btn soft', () => quotaForm(box, r)));
      box.appendChild(f);
    }
    box.appendChild(btn('أضف نصابًا لصفة', 'rs-btn', () => quotaForm(box, null)));
    arabize(box);
  }

  async function quotaForm(box, r) {
    const { data: posts, error } = await M.rpc('v2_posts_list', undefined, 'الوظائف');
    if (error) { flash('bad', errText(error)); return; }
    V.form({
      title: r ? 'نصابُ ' + (r.post_ar || r.post) : 'نصابٌ لصفة',
      fields: [
        { key: 'post', type: 'choose', label: 'الصفة', items: (posts || []).map((p) => [p.key, p.label, p.kind || '']), value: r ? r.post : null },
        { key: 'min', type: 'number', label: 'الحدُّ الأدنى (اختياري)', value: r ? r.min : null },
        { key: 'max', type: 'number', label: 'الحدُّ الأعلى', value: r ? r.max : null },
        { key: 'sb', type: 'number', label: 'أقصى الانتظار (اختياري)', value: r ? r.standby_max : null },
        { key: 'note', label: 'ملاحظة (اختياري)', value: r ? r.note : null },
      ],
      ok: 'احفظ',
      onOk: async (v) => {
        const { error: e } = await M.rpc('v2_quota_save', { p_school: school(), p_post: v.post, p_min: v.min, p_max: v.max, p_standby_max: v.sb, p_note: v.note }, 'حفظ النصاب');
        if (e) return e;
        flash('ok', 'حُفظ النصاب');
        quotaTool(box);
        return null;
      },
    });
  }

  // ================= ٣ · خطّةُ المواد =================
  async function planTool(box) {
    const q = await quotaBoard(box);
    if (!q) return;
    box.appendChild(el('div', 'rs-note', 'مستخرَجةٌ من الجدول القائم لا من خطّة الوزارة — فصحّحها قبل الاقتراح الآليّ.'));
    const bal = q.balance || {};
    box.appendChild(el('p', 'rs-meta', 'المطلوبُ من الخطّة ' + (bal.planned == null ? '—' : bal.planned) + ' حصّة · والمجدوَلُ تدريسًا ' + (bal.scheduled == null ? '—' : bal.scheduled)));
    const byGrade = new Map();
    for (const r of q.plan || []) { if (!byGrade.has(r.grade)) byGrade.set(r.grade, []); byGrade.get(r.grade).push(r); }
    if (!byGrade.size) box.appendChild(el('p', 'rs-meta', 'لا خطّةَ موادّ بعد.'));
    for (const [g, rows] of byGrade) {
      const det = el('details', 'rs-dt');
      det.appendChild(el('summary', null, 'الصفّ ' + (rows[0].grade_ar || g) + ' — ' + rows.length + ' مادّة'));
      const body = el('div', 'rs-dtb');
      for (const r of rows) {
        const it = btn('', 'rs-item', () => planForm(box, r));
        it.append(el('span', null, r.subject), el('small', null, (r.slots_ar || r.slots) + ' حصص'));
        body.appendChild(it);
      }
      det.appendChild(body);
      box.appendChild(det);
    }
    box.appendChild(btn('أضف مادّةً إلى الخطّة', 'rs-btn', () => planForm(box, null)));
    arabize(box);
  }

  function planForm(box, r) {
    V.form({
      title: r ? 'مادّةٌ في الخطّة — ' + r.subject : 'مادّةٌ جديدة في الخطّة',
      fields: [
        { key: 'grade', type: 'number', label: 'الصفّ (رقمه)', value: r ? r.grade : null },
        { key: 'subject', label: 'المادّة', value: r ? r.subject : null },
        { key: 'slots', type: 'number', label: 'حصصُها في الأسبوع', value: r ? r.slots : null },
        { key: 'ord', type: 'number', label: 'ترتيبُها (اختياري)', value: r ? r.ord : null },
      ],
      ok: 'احفظ',
      extra: r ? [{ text: 'أزِلها من الخطّة', cls: 'rs-btn irrev', onClick: async () => {
        const { error } = await M.rpc('v2_plan_remove', { p_school: school(), p_plan: r.id }, 'إزالة من الخطّة');
        if (error) return error;
        flash('ok', 'أُزيلت ' + r.subject + ' من الخطّة');
        planTool(box);
        return null;
      } }] : [],
      onOk: async (v) => {
        const { error } = await M.rpc('v2_plan_save', { p_school: school(), p_plan: r ? r.id : null, p_grade: v.grade, p_subject: v.subject, p_slots: v.slots, p_ord: v.ord }, 'حفظ الخطّة');
        if (error) return error;
        flash('ok', 'حُفظت الخطّة');
        planTool(box);
        return null;
      },
    });
  }

  // ================= ٤ · تخصّصاتُ المعلّمين =================
  async function subjectsTool(box) {
    const q = await quotaBoard(box);
    if (!q) return;
    const list = (q.teachers || []).filter((t) => (t.subjects || []).length || t.now_teaching);
    const rest = (q.teachers || []).filter((t) => !list.includes(t));
    for (const t of list.concat(rest)) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, t.person),
        el('p', null, ['تدريسٌ الآن ' + (t.now_teaching || 0), 'انتظار ' + (t.now_standby || 0), t.quota_max != null ? 'النصاب ' + t.quota_max : 'لا نصابَ مضبوطًا'].join(' · ')));
      const chips = el('div', 'rs-pick');
      for (const s of t.subjects || []) {
        const c = el('span', s.main ? 'on' : null, s.subject + (s.main ? '' : ' (ثانويّة)'));
        c.setAttribute('role', 'button');
        c.tabIndex = 0;
        c.addEventListener('click', () => subjectForm(box, t, s));
        chips.appendChild(c);
      }
      f.appendChild(chips);
      f.appendChild(btn('أضف تخصّصًا', 'rs-btn soft', () => subjectForm(box, t, null)));
      box.appendChild(f);
    }
    if (!(q.teachers || []).length) box.appendChild(el('p', 'rs-meta', 'لا منسوبين.'));
    arabize(box);
  }

  function subjectForm(box, t, s) {
    V.form({
      title: (s ? 'تخصّصُ ' : 'تخصّصٌ لـ') + t.person, what: s ? s.subject : '',
      fields: [
        { key: 'subject', label: 'المادّة', value: s ? s.subject : null },
        { key: 'main', type: 'pick', label: 'هي', items: [['yes', 'رئيسة'], ['no', 'ثانويّة']], value: s && !s.main ? 'no' : 'yes' },
      ],
      ok: 'احفظ',
      extra: s ? [{ text: 'احذف التخصّص', cls: 'rs-btn irrev', onClick: async () => {
        const { data, error } = await M.rpc('v2_teacher_subject', { p_school: school(), p_person: t.person_id, p_subject: s.subject, p_main: null, p_remove: true }, 'حذف تخصّص');
        if (error) return error;
        flash('ok', ((data && data.mode) || 'حُذفت') + ': ' + s.subject + ' — ' + t.person);
        subjectsTool(box);
        return null;
      } }] : [],
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_teacher_subject', { p_school: school(), p_person: t.person_id, p_subject: v.subject, p_main: v.main === 'yes', p_remove: false }, 'تخصّص المعلّم');
        if (error) return error;
        flash('ok', ((data && data.mode) || 'حُفظت') + ': ' + (v.subject || '') + ' — ' + t.person);
        subjectsTool(box);
        return null;
      },
    });
  }

  // ================= ٥ · التوزيعُ الآليّ =================
  async function draftsTool(box) {
    box.textContent = '';
    box.appendChild(el('div', 'rs-note', 'النظامُ يعرض والإنسانُ يقرّر: المقترحُ لا يمسّ الجدولَ القائم حتى تقرّه بكتابة «أقرّ». والمقترحاتُ محفوظةٌ لا تُمحى.'));
    box.appendChild(btn('اقترح جدولًا', 'rs-btn', () => suggestForm(box)));
    const { data, error } = await M.rpc('v2_drafts_list', { p_school: school() }, 'المقترحات');
    if (error) { errBox(box, error); return; }
    const list = data || [];
    if (!list.length) box.appendChild(el('p', 'rs-meta', 'لا مقترحاتِ بعد.'));
    for (const d of list) {
      const f = el('div', 'rs-file');
      const s = d.stats || {};
      f.append(el('h5', null, (d.state || '') + ' — ' + String(d.made_at || '').slice(0, 10) + (d.made_by ? ' · ' + d.made_by : '')),
        el('p', null, ['وُضعت ' + (s.placed_ar || s.placed || 0), 'تعذّرت ' + (s.unplaced || 0), 'انتظار ' + (s.standby_ar || s.standby || 0), d.applied_at ? 'أُقرّ ' + String(d.applied_at).slice(0, 10) : null, d.note].filter(Boolean).join(' · ')));
      const holder = el('div');
      f.appendChild(btn('افتح المقترح', 'rs-btn soft', () => draftCard(box, d.id, holder)));
      f.appendChild(holder);
      box.appendChild(f);
    }
    arabize(box);
  }

  function suggestForm(box) {
    V.form({
      title: 'اقترح جدولًا من خطّة المواد',
      what: 'يختار المتقنَ الفارغَ وأقلَّهم حملًا، ولا يتجاوز نصابَ أحد، ثمّ يملأ الفراغَ انتظارًا',
      fields: [
        { key: 'keep', type: 'pick', label: 'حصصُ التدريس القائمة', items: [['yes', 'ثبّتها'], ['no', 'وزّع من جديد']], value: 'yes' },
        { key: 'note', label: 'ملاحظة (اختياري)' },
      ],
      ok: 'اقترح',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_timetable_suggest', { p_school: school(), p_keep_fixed: v.keep === 'yes', p_note: v.note }, 'اقتراح جدول');
        if (error) return error;
        const d = data || {};
        flash('ok', 'وُضعت ' + d.placed + ' · تعذّرت ' + d.unplaced + ' · انتظار ' + d.standby + (d.note ? ' — ' + d.note : ''));
        draftsTool(box);
        return null;
      },
    });
  }

  async function draftCard(box, id, holder) {
    holder.textContent = '';
    const [c, b] = await Promise.all([
      M.rpc('v2_draft_card', { p_draft: id }, 'المقترح'),
      M.rpc('v2_timetable_board', { p_school: school(), p_person: null, p_section: null, p_weekday: null }, 'الجدول القائم'),
    ]);
    if (c.error) { errBox(holder, c.error); return; }
    const card = c.data || {};
    const d = card.draft || {};
    const s = d.stats || {};
    const gaps = s.gaps || [];
    if (gaps.length) {
      holder.appendChild(el('div', 'rs-label', 'ما تعذّر (' + gaps.length + ')'));
      const ul = el('ul', 'rs-acts');
      for (const g of gaps) {
        const li = el('li');
        li.append(el('i', 'rs-tick', '○'), el('span', null, [g.section, g.subject].filter(Boolean).join(' — ') + ': ' + (g.why || '')));
        ul.appendChild(li);
      }
      holder.appendChild(ul);
    }
    const lt = el('table', 'rs-table');
    lt.style.minWidth = '0';
    const lh = el('tr');
    for (const h of ['المعلّم', 'تدريس', 'انتظار']) lh.appendChild(el('th', null, h));
    lt.appendChild(lh);
    for (const l of card.load || []) {
      const r = el('tr');
      for (const v of [l.person, l.teaching, l.standby]) r.appendChild(el('td', null, String(v == null ? '—' : v)));
      lt.appendChild(r);
    }
    const ld = el('details', 'rs-dt');
    ld.appendChild(el('summary', null, 'الحملُ في المقترح'));
    const ldb = el('div', 'rs-dtb');
    ldb.appendChild(lt);
    ld.appendChild(ldb);
    holder.appendChild(ld);
    const sd = el('details', 'rs-dt');
    sd.appendChild(el('summary', null, 'خاناتُ المقترح (' + (card.slots || []).length + ') ولمَ وُضعت'));
    const sdb = el('div', 'rs-dtb');
    for (const x of card.slots || []) sdb.appendChild(el('div', null, [x.weekday_ar, 'الحصّة ' + x.period_ar, x.kind_ar, x.section, x.subject, x.person].filter(Boolean).join(' · ') + (x.why ? ' — ' + x.why : '')));
    sd.appendChild(sdb);
    holder.appendChild(sd);
    if (d.state === 'مقترح') {
      const now = b.error ? null : ((b.data && b.data.slots) || []).length;
      const row = el('div', 'rs-row');
      row.append(btn('أقرّ المقترح', 'rs-btn', () => applyForm(box, d, now, (card.slots || []).length)),
        btn('ألغِه', 'rs-btn ghost', () => cancelForm(box, d)));
      holder.appendChild(row);
    }
    arabize(holder);
  }

  // 🔒 لا زرٌّ يُقرّ: حقلُ كتابةٍ يُكتب فيه «أقرّ» حرفيًّا، ومعه عددُ ما سيُستبدل
  function applyForm(box, d, now, next) {
    V.form({
      title: 'إقرارُ المقترح',
      what: 'سيُستبدل جدولُ مدرستك كلُّه: ' + (now == null ? '—' : now) + ' حصّةً قائمة تحلّ محلَّها ' + next + ' حصّةً من المقترح. اكتب «أقرّ» لتأكيده.',
      fields: [{ key: 'confirm', label: 'اكتب: أقرّ' }],
      ok: 'نفّذ الإقرار',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_draft_apply', { p_draft: d.id, p_confirm: v.confirm }, 'إقرار المقترح');
        if (error) return error;
        flash('ok', ((data && data.note) || 'أُقرّ الجدول') + ' · ' + ((data && data.slots) || 0) + ' حصّة');
        draftsTool(box);
        return null;
      },
    });
  }

  function cancelForm(box, d) {
    V.form({
      title: 'إلغاءُ المقترح', fields: [{ key: 'why', type: 'textarea', label: 'السبب', rows: 2 }], ok: 'ألغِه',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_draft_cancel', { p_draft: d.id, p_why: v.why }, 'إلغاء المقترح');
        if (error) return error;
        flash('ok', 'أُلغي المقترح — ويبقى محفوظًا');
        draftsTool(box);
        return null;
      },
    });
  }

  window.MoayadJadwal = { timetableTool, quotaTool, planTool, subjectsTool, draftsTool, ar };
})();
