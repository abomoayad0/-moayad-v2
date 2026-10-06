// مؤيّد · شاشة اللجنة — viewC في المحاكي: اختصاصُها · شواهدُ بانتظار التقدير · الفرص · إحالاتٌ إليك · فرصةٌ آليّة · محاضرُ اللجنة.
// جمعت ما كان في «اللجان» و«التعويض» في شاشةٍ واحدة. والمحاضرُ على المبنيّ: اجتماعٌ ونصابٌ وتصويت — الاستثناءُ الوحيدُ عن المحاكي.
// v2_committees_list · v2_committee_board · v2_committee_duties · v2_committee_seat · v2_committee_unseat
// v2_meetings_list · v2_meeting_call · v2_meeting_card · v2_meeting_attend · v2_meeting_invite · v2_meeting_item · v2_meeting_vote
// v2_meeting_close_item · v2_meeting_carry_over · v2_meeting_minute · v2_meeting_approve · v2_my_committee_tasks · v2_committee_task_done
// v2_merits · v2_opps_list · v2_opp_open · v2_opp_close · v2_opp_card · v2_entry_grade · v2_opp_plan · v2_entry_file · v2_staff_list · v2_day_list
// الشاشةُ لا تقرّر: من يدعو ومن يصوّت والنصابُ والقفلُ والقسمةُ كلُّها في القاعدة، ورفضُها يُعرض بنصّه.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash, pick } = V;

  const BUCKET = 'v2-attachments';
  const P19 = ' — ص١٩';
  const TABS = [['board', 'المجلس'], ['meetings', 'الاجتماعات'], ['open', 'الاجتماعُ المفتوح'], ['minutes', 'المحاضر'], ['mine', 'ما عليّ']];

  const ui = {
    can: {}, committees: [], key: 'guidance', board: null, duties: [], meetings: [], openId: null, card: null,
    tab: 'meetings', mine: [], opps: [], oppId: null, oppCard: null, staff: null, students: null, merits: null,
  };

  const hm = (t) => (t ? String(t).slice(0, 5) : null);
  const day = (t) => (t ? String(t).slice(0, 10) : null);
  // ما يُرسله اللوحُ: خطأُ القاعدة يرجع إليه فيبقى بما كُتب فيه
  const call = async (fn, args, label, okText) => {
    const { data, error } = await M.rpc(fn, args, label);
    if (error) return { error };
    if (okText) flash('ok', typeof okText === 'function' ? okText(data || {}) : okText);
    return { data: data || {} };
  };

  async function staff() {
    if (ui.staff) return ui.staff;
    const { data, error } = await M.rpc('v2_staff_list', { p_school: M.state.school }, 'قائمة المنسوبين');
    if (error) { flash('bad', errText(error)); return null; }
    ui.staff = data || [];
    return ui.staff;
  }
  async function students() {
    if (ui.students) return ui.students;
    const { data, error } = await M.rpc('v2_day_list', { p_school: M.state.school, p_date: M.state.date }, 'قائمة الطلاب');
    if (error) { flash('bad', errText(error)); return null; }
    ui.students = data || [];
    return ui.students;
  }
  const staffItems = (list) => (list || []).map((p) => [p.person_id, p.name_ar, p.post_ar || p.roles_ar || '']);
  const stuItems = (list) => (list || []).map((p) => [p.student_id, p.display_name || p.full_name, p.student_no || '']);

  // ---------- الجلب ----------
  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    ui.can = (M.state.me && M.state.me.can) || {};
    ui.staff = null; ui.students = null;
    $('dutyCard').hidden = !ui.can.committees;
    $('minCard').hidden = !ui.can.committees;
    $('gradeCard').hidden = !ui.can.merit;
    $('oppCard').hidden = !ui.can.merit;
    renderOff();
    const jobs = [];
    if (ui.can.committees) jobs.push(loadCommittees());
    if (ui.can.merit) jobs.push(loadOpps());
    await Promise.all(jobs);
  }

  function renderOff() {
    const box = $('offCards');
    box.textContent = '';
    if (!ui.can.committees && !ui.can.merit) return;
    box.append(V.offCard('إحالاتٌ إليك', 'الإحالةُ للّجنة بحارسها وتقريرُ الموجّه معها'),
      V.offCard('فرصةٌ تُحتسب آليًّا', 'انضباطُ الطالب وعدمُ غيابه بلا عذرٍ خلال الفصل'));
  }

  // ---------- ① اختصاصُها ----------
  async function loadCommittees() {
    const { data, error } = await M.rpc('v2_committees_list', { p_school: M.state.school }, 'قائمة اللجان');
    if (error) { showLoadErr(errText(error)); return; }
    ui.committees = data || [];
    if (!ui.committees.some((c) => c.key === ui.key) && ui.committees.length) ui.key = ui.committees[0].key;
    await loadCommittee();
  }

  function renderCommittees() {
    const items = ui.committees.map((c) => [c.key, c.label]);
    const box = $('committees');
    const go = (k) => { ui.key = k; ui.openId = null; ui.card = null; loadCommittee(); };
    // القصيرُ شرائط، والطويلُ قائمةٌ ببحث
    if (items.length <= 9) { box.className = 'rs-pick'; pick(box, items, ui.key, go); }
    else { box.className = ''; V.chooser(box, items, ui.key, go); }
  }

  async function loadCommittee() {
    renderCommittees();
    const [b, d] = await Promise.all([
      M.rpc('v2_committee_board', { p_school: M.state.school, p_committee: ui.key }, 'مجلس اللجنة'),
      M.rpc('v2_committee_duties', { p_school: M.state.school, p_committee: ui.key }, 'مهامّ اللجنة'),
    ]);
    ui.board = b.error ? null : b.data;
    ui.duties = d.error ? [] : (d.data || []);
    renderDuties(b.error || d.error);
    renderSeatLine();
    await Promise.all([loadMeetings(), loadMine()]);
  }

  function renderSeatLine() {
    const b = ui.board;
    const c = (b && b.committee) || {};
    $('seatLine').hidden = !b;
    $('seatLine').textContent = b && b.my_seat ? 'مقعدُك في «' + (c.label || '') + '»: ' + b.my_seat : 'لستَ عضوًا في «' + (c.label || '') + '».';
  }

  function renderDuties(err) {
    const c = (ui.board && ui.board.committee) || {};
    $('purpose').textContent = c.purpose || '';
    const box = $('duties');
    box.textContent = '';
    if (err) { box.appendChild(el('div', 'notice err', errText(err))); }
    const ul = el('ul', 'rs-acts');
    for (const d of ui.duties) {
      const li = el('li');
      const body = el('span');
      body.style.flex = '1';
      body.appendChild(el('span', null, d.text || ''));
      body.appendChild(el('div', 'rs-meta', [d.cadence, d.last_done ? 'آخرُ تنفيذٍ معتمد ' + d.last_done : 'لم يُنفَّذ في محضرٍ معتمد', 'بنودُه ' + (d.items || 0)].filter(Boolean).join(' · ')));
      li.append(el('i', 'rs-tick' + (d.last_done ? ' ok' : ''), d.last_done ? '✓' : '○'), body, el('small', 'rs-who', d.source || ''));
      ul.appendChild(li);
    }
    if (ui.duties.length) box.appendChild(ul);
    else if (!err) box.appendChild(el('p', 'rs-meta', 'لا مهامَّ مسجّلةً لهذي اللجنة.'));
    if (c.source) box.appendChild(el('div', 'rs-note', 'السند: ' + c.source));
    arabize(box);
    const acts = $('dutyActs');
    acts.textContent = '';
    if (ui.can.merit) acts.appendChild(btn('افتح فرصةً للطلبة', 'rs-btn', openOpp));
  }

  // ---------- ②③ الفرص ----------
  async function loadOpps() {
    const { data, error } = await M.rpc('v2_opps_list', { p_school: M.state.school, p_state: null, p_days: 180 }, 'بنك الفرص');
    ui.opps = error ? [] : (data || []);
    renderOpps(error);
    if (ui.oppId) await loadOppCard();
  }

  function oppLine(o) {
    return [o.when, 'المسجّلون ' + o.joined + (o.capacity ? ' من ' + o.capacity : ''), 'رفعوا ' + o.filed, 'أُقرّ ' + o.verdicted, 'قُدّر ' + o.graded, o.held_by ? 'يقيمها ' + o.held_by : null].filter(Boolean).join(' · ');
  }

  function renderOpps(err) {
    // ② ما أُقرّ ولم يُقدَّر — عدّاداتُه من القاعدة
    const g = $('toGrade');
    g.textContent = '';
    const wait = ui.opps.filter((o) => o.verdicted > o.graded);
    for (const o of wait) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, o.title || o.merit || ''), el('p', null, (o.verdicted - o.graded) + ' بانتظار التقدير · ' + (o.points_note || '') + (o.source ? ' · ' + o.source : '')));
      f.appendChild(btn('قدّر الدرجة', 'rs-btn', () => selectOpp(o.opp)));
      g.appendChild(f);
    }
    if (!wait.length) g.appendChild(el('p', 'rs-meta', 'لا شيءَ بانتظار التقدير.'));
    arabize(g);

    // ③ البنك
    const box = $('opps');
    box.textContent = '';
    if (err) box.appendChild(el('div', 'notice err', errText(err)));
    if (!ui.opps.length && !err) box.appendChild(el('p', 'rs-meta', 'لا فرصَ في المدّة.'));
    for (const o of ui.opps) {
      const f = el('div', 'rs-file');
      f.id = 'opp_' + o.opp;
      const h = el('h5', null, (o.title || o.merit || '') + ' — ');
      h.appendChild(el('b', o.state === 'مفتوحة' ? 'rs-state-done' : null, o.state || ''));
      f.append(h, el('p', null, oppLine(o)));
      if (o.close_why) f.appendChild(el('p', null, 'سببُ الإغلاق: ' + o.close_why));
      if (o.plan_note) f.appendChild(el('p', null, 'اعتُمد مخطّطُها: ' + o.plan_note));
      const open = ui.oppId === o.opp;
      f.appendChild(btn(open ? 'اطوِ ملفَّ الفرصة' : 'ملفُّ الفرصة', 'rs-btn soft', () => (open ? selectOpp(null) : selectOpp(o.opp))));
      if (open) { const d = el('div'); d.id = 'oppBox'; f.appendChild(d); }
      box.appendChild(f);
    }
    arabize(box);
    if (ui.oppId && ui.oppCard) renderOppCard();
  }

  async function selectOpp(id) {
    ui.oppId = id;
    ui.oppCard = null;
    renderOpps();
    if (id) { await loadOppCard(); const f = $('opp_' + id); if (f) f.scrollIntoView({ behavior: 'smooth', block: 'start' }); }
  }

  async function loadOppCard() {
    const { data, error } = await M.rpc('v2_opp_card', { p_opp: ui.oppId }, 'ملفّ الفرصة');
    const box = $('oppBox');
    if (error) { if (box) { box.textContent = ''; box.appendChild(el('div', 'notice err', errText(error))); } return; }
    ui.oppCard = data || {};
    renderOppCard();
  }

  // الشاهد: رابطٌ موقَّتٌ من المخزن — والقراءةُ تحرسها سياسةُ المخزن
  async function openEvidence(path) {
    const { data, error } = await M.sb.storage.from(BUCKET).createSignedUrl(path, 300);
    if (error) { flash('bad', errText(error)); return; }
    window.open(data.signedUrl, '_blank', 'noopener');
  }

  function renderOppCard() {
    const box = $('oppBox');
    if (!box) return;
    box.textContent = '';
    const c = ui.oppCard;
    const o = c.opp || {};
    const m = c.merit || {};
    box.appendChild(el('p', 'rs-meta', [m.group, o.kind, m.points_note, m.source, o.capacity ? 'السعة ' + o.capacity : 'بلا حدّ'].filter(Boolean).join(' · ')));
    const acts = el('div', 'rs-row');
    if (o.state === 'مفتوحة') acts.appendChild(btn('أغلقها — انتهى الوقت', 'rs-btn ghost', closeOpp));
    box.appendChild(acts);
    const members = c.members || [];
    if (!members.length) box.appendChild(el('p', 'rs-meta', 'لم يسجّل فيها أحدٌ بعد.'));
    for (const x of members) {
      const r = el('div', 'rs-file');
      const st = x.graded ? 'قُدّرت ' + x.points + ' درجة' : x.verdict || (x.filed ? 'رفع نموذجَه — بانتظار الإقرار' : 'لم يرفع نموذجَه بعد');
      r.append(el('h5', null, x.name || ''), el('p', null, st));
      if (x.filed) {
        const lg = el('div', 'rs-lgd');
        lg.append(el('i', 'k', 'ما كتبه:'), el('i', null, x.what || ''), el('i', 'k', 'الشاهد:'), el('i', null, x.evidence || '—'));
        r.appendChild(lg);
        if (x.evidence_path) r.appendChild(btn('افتح المرفق', 'rs-btn soft', () => openEvidence(x.evidence_path)));
      }
      if (x.verdict) r.appendChild(el('p', null, 'الإقرار: ' + x.verdict + (x.note ? ' — ' + x.note : '') + (x.by ? ' · ' + x.by : '')));
      if (x.delegated) r.appendChild(el('p', null, 'أُحيل إقرارُها إلى ' + x.delegated));
      const row = el('div', 'rs-row');
      if (x.verdict && !x.graded) row.appendChild(btn('قدّر درجتَه', 'rs-btn', () => grade(x, m)));
      // رفعُ الشاهد نيابةً — والمسارُ من القاعدة (upload_to) لا يُبنى في الشاشة
      if (!x.filed && o.state !== 'مفتوحة' && x.upload_to) row.appendChild(btn('ارفع نموذجَه نيابةً', 'rs-btn soft', () => fileFor(x)));
      r.appendChild(row);
      box.appendChild(r);
    }
    if (o.state !== 'مفتوحة' && !o.plan_note) {
      if (members.some((x) => x.verdict)) box.appendChild(btn('اعتمد مخطّطَ الفرصة', 'rs-btn', plan));
      else box.appendChild(el('div', 'rs-note', 'بانتظار إقرار المشاركات'));
    }
    arabize(box);
  }

  async function openOpp() {
    if (!ui.merits) {
      const { data, error } = await M.rpc('v2_merits', undefined, 'ممارسات السلوك المتميّز');
      if (error) { flash('bad', errText(error)); return; }
      ui.merits = data || [];
    }
    const list = await staff();
    if (!list) return;
    V.form({
      title: 'افتح فرصةً للطلبة',
      fields: [
        { key: 'merit', type: 'choose', label: 'الممارسة', items: ui.merits.map((m) => [m.id, m.text, [m.group, m.points_note, m.source].filter(Boolean).join(' · ')]) },
        { key: 'kind', type: 'pick', label: 'بابُها', items: [['منظَّمة', 'منظَّمة'], ['فرديّة', 'فرديّة'], ['آليّة', 'آليّة']], value: 'منظَّمة' },
        { key: 'title', label: 'عنوانُها (اختياري)' },
        { key: 'when', label: 'موعدُها ومكانُها', hint: 'الإذاعة المدرسية · الأحد' },
        { key: 'cap', type: 'number', label: 'السعة — فارغةٌ بلا حدّ' },
        { key: 'held', type: 'choose', label: 'من يقيمها', items: staffItems(list) },
      ],
      ok: 'افتحها',
      onOk: async (v) => {
        const r = await call('v2_opp_open', {
          p_school: M.state.school, p_merit: v.merit, p_kind: v.kind, p_title: v.title, p_when: v.when, p_capacity: v.cap, p_held_by: v.held,
        }, 'فتح فرصة', (d) => 'فُتحت الفرصة: ' + (d.merit || ''));
        if (r.error) return r.error;
        ui.oppId = r.data.opp || null;
        loadOpps();
        return null;
      },
    });
  }

  function closeOpp() {
    V.form({
      title: 'إغلاقُ الفرصة', what: (ui.oppCard.merit || {}).text,
      fields: [{ key: 'why', type: 'textarea', label: 'سببُ الإغلاق' }],
      ok: 'أغلقها',
      onOk: async (v) => {
        const r = await call('v2_opp_close', { p_opp: ui.oppId, p_why: v.why }, 'إغلاق فرصة', 'أُغلقت الفرصة');
        if (r.error) return r.error;
        loadOpps();
        return null;
      },
    });
  }

  function grade(x, m) {
    V.form({
      title: 'تقديرُ الدرجة', what: x.name + ' — ' + (m.text || '') + (m.points_note ? ' · ' + m.points_note : '') + (m.source ? ' · ' + m.source : ''),
      fields: [
        { key: 'pts', type: 'number', label: 'الدرجة' },
        { key: 'note', type: 'textarea', label: 'توصيةُ اللجنة', hint: 'إلزاميّةٌ لما لم يُذكر في الدليل' },
      ],
      ok: 'قدّرها',
      onOk: async (v) => {
        const r = await call('v2_entry_grade', { p_entry: x.entry, p_points: v.pts, p_note: v.note }, 'تقدير الدرجة', (d) => {
          // القسمةُ كما رجعت من القاعدة
          const s = d['الدرجة'] || {};
          return ['منح', 'تعويض', 'اكتساب', 'مهدور'].map((k) => k + ' ' + (d[k] == null ? '—' : d[k])).join(' · ') +
            ' — الإيجابيُّ ' + s.positive + ' من ٨٠ · المتميّزُ ' + s.merit + ' من ٢٠ · المجموعُ ' + s.total + ' من ١٠٠';
        });
        if (r.error) return r.error;
        loadOpps();
        return null;
      },
    });
  }

  function plan() {
    V.form({
      title: 'اعتمادُ مخطّط الفرصة', what: (ui.oppCard.merit || {}).text,
      fields: [{ key: 'note', type: 'textarea', label: 'توصيةُ اللجنة' }],
      ok: 'اعتمده',
      onOk: async (v) => {
        const r = await call('v2_opp_plan', { p_opp: ui.oppId, p_note: v.note }, 'اعتماد المخطّط', 'اعتُمد مخطّطُ الفرصة');
        if (r.error) return r.error;
        loadOpps();
        return null;
      },
    });
  }

  // نموذجُ المشاركة نيابةً: يُرفع الملفُّ إلى المسار الذي ترجعه القاعدة (upload_to) ثمّ يُمرَّر المسار
  function fileFor(x) {
    V.form({
      title: 'نموذجُ المشاركة — نيابةً', what: x.name,
      fields: [
        { key: 'what', type: 'textarea', label: 'ماذا فعل بالتحديد' },
        { key: 'file', type: 'file', label: 'الشاهدُ المرفق — ملفٌّ فعليّ' },
        { key: 'desc', label: 'وصفُ المرفق' },
      ],
      ok: 'ارفع النموذج',
      onOk: async (v) => {
        if (!v.file) return 'اختر ملفَّ الشاهد.';
        const path = x.upload_to + Date.now() + '-' + v.file.name.replace(/[^\w.-]+/g, '_');
        const up = await M.sb.storage.from(BUCKET).upload(path, v.file, { upsert: false });
        if (up.error) {
          M.logError({ message: up.error.message, fn: 'storage.upload', action: 'رفع الشاهد', params: { path } });
          return up.error;
        }
        const r = await call('v2_entry_file', { p_entry: x.entry, p_what: v.what, p_evidence_path: path, p_evidence_desc: v.desc },
          'نموذج المشاركة', (d) => 'رُفع النموذج' + (d.by ? ' — ' + d.by : ''));
        if (r.error) return r.error;
        loadOpps();
        return null;
      },
    });
  }

  // ---------- ⑥ محاضرُ اللجنة ----------
  function mySeat() {
    const me = M.state.me && M.state.me.person_id;
    for (const s of (ui.board && ui.board.seats) || []) if ((s.holders || []).some((h) => h.person === me)) return s;
    return null;
  }
  const isChair = () => { const s = mySeat(); return !!s && s.role === 'chair'; };
  const isRapporteur = () => { const s = mySeat(); return !!s && s.role === 'rapporteur'; };

  async function loadMeetings() {
    const { data, error } = await M.rpc('v2_meetings_list', { p_school: M.state.school, p_committee: ui.key, p_status: null, p_days: 180 }, 'قائمة الاجتماعات');
    ui.meetings = error ? [] : (data || []);
    ui.meetingsErr = error;
    if (ui.openId) await loadCard(); else renderMin();
  }
  async function loadCard() {
    const { data, error } = await M.rpc('v2_meeting_card', { p_meeting: ui.openId }, 'محضر الاجتماع');
    ui.card = error ? null : data;
    ui.cardErr = error;
    renderMin();
  }
  async function loadMine() {
    const { data, error } = await M.rpc('v2_my_committee_tasks', { p_school: M.state.school }, 'ما عليّ من اللجان');
    ui.mine = error ? [] : (data || []);
    ui.mineErr = error;
    if (ui.tab === 'mine') renderMin();
  }
  // بعد كلّ فعلٍ في الاجتماع: المجلسُ والقائمةُ والمحضرُ من القاعدة
  async function reloadMin() {
    const { data } = await M.rpc('v2_committee_board', { p_school: M.state.school, p_committee: ui.key }, 'مجلس اللجنة');
    if (data) ui.board = data;
    renderSeatLine();
    await Promise.all([loadMeetings(), loadMine()]);
  }

  function renderMin() {
    const n = ui.mine.length;
    pick($('mtabs'), TABS.map(([k, t]) => [k, k === 'mine' && n ? t + ' (' + n + ')' : t]), ui.tab, (k) => { ui.tab = k; renderMin(); });
    const box = $('mbody');
    box.textContent = '';
    if (ui.tab === 'board') renderBoard(box);
    if (ui.tab === 'meetings') renderMeetings(box);
    if (ui.tab === 'open') renderOpen(box, true);
    if (ui.tab === 'minutes') renderMinutes(box);
    if (ui.tab === 'mine') renderMine(box);
    arabize(box);
  }

  // المجلس
  function renderBoard(box) {
    const b = ui.board;
    if (!b) { box.appendChild(el('p', 'rs-meta', 'تعذّر جلب المجلس.')); return; }
    const c = b.committee || {};
    box.appendChild(el('p', 'rs-meta', [c.quorum_ar || (c.quorum == null ? 'لم يُحدَّد نصابٌ بعد' : 'النصاب: ' + c.quorum), c.quorum_note].filter(Boolean).join(' · ')));
    for (const s of (b.seats || []).slice().sort((x, y) => x.ord - y.ord)) {
      const holders = s.holders || [];
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (s.role_ar || '') + ' — ' + holders.length + ' من ' + s.count),
        el('p', null, [s.post ? 'الوظيفة: ' + s.post : null, s.elected ? 'يختاره مديرُ المدرسة' : null, holders.length ? null : 'لم يُشغل بعد'].filter(Boolean).join(' · ')));
      for (const h of holders) {
        const row = el('div', 'rs-row');
        row.append(el('span', null, h.name + (h.since ? ' · منذ ' + h.since : '') + (h.nominated_by ? ' · ' + h.nominated_by : '')),
          btn('أخرِجه', 'rs-btn ghost', () => unseat(h)));
        f.appendChild(row);
      }
      f.appendChild(btn('أجلِس في هذا المقعد', 'rs-btn soft', () => seat(s)));
      box.appendChild(f);
    }
  }

  async function seat(s) {
    const list = await staff();
    if (!list) return;
    // مقعدُ الوظيفة: شاغلوها أوّلًا كما في سجلّ المنسوبين — والقاعدةُ ترفض غيرهم
    const fit = s.post ? list.filter((p) => p.post_ar === s.post || (p.roles_ar || '').includes(s.post)) : list;
    const fields = [{ key: 'who', type: 'choose', label: 'من', items: staffItems(fit.length ? fit : list) }];
    if (s.elected) fields.push({ key: 'nom', label: 'من اختاره', hint: 'قرارُ مدير المدرسة · التاريخ' });
    V.form({
      title: 'إجلاسٌ في مقعد «' + (s.role_ar || '') + '»', what: s.post || '', fields, ok: 'أجلِسه',
      onOk: async (v) => {
        const r = await call('v2_committee_seat', {
          p_school: M.state.school, p_committee: ui.key, p_seat_role: s.role, p_person: v.who,
          p_post_key: s.post_key || null, p_nominated_by: s.elected ? v.nom : null,
        }, 'إجلاس عضو', (d) => 'أُجلس ' + (d.name || '') + ' في المقعد');
        if (r.error) return r.error;
        reloadMin();
        return null;
      },
    });
  }

  function unseat(h) {
    V.form({
      title: 'إخراجٌ من اللجنة', what: h.name, fields: [{ key: 'why', type: 'textarea', label: 'السبب' }], ok: 'أخرِجه',
      onOk: async (v) => {
        const r = await call('v2_committee_unseat', { p_school: M.state.school, p_committee: ui.key, p_person: h.person, p_reason: v.why }, 'إخراج عضو', 'أُخرج من المقعد');
        if (r.error) return r.error;
        reloadMin();
        return null;
      },
    });
  }

  // الاجتماعات
  function meetingRow(m, onOpen) {
    const f = el('div', 'rs-file');
    f.append(el('h5', null, 'الاجتماع ' + m.no + ' · ' + (m.kind || '') + ' — ' + (m.status || '')),
      el('p', null, [m.held_on, hm(m.started), m.place].filter(Boolean).join(' · ')));
    if (m.agenda) f.appendChild(el('p', null, 'جدولُ الأعمال: ' + m.agenda));
    f.appendChild(el('p', null, ['البنود ' + (m.items || 0), m.called_by ? 'دعا إليه ' + m.called_by : null, m.approved_by ? 'اعتمده ' + m.approved_by : null,
      m.quorum_met == null ? null : m.quorum_met ? 'النصابُ مكتمل' : 'النصابُ ناقص'].filter(Boolean).join(' · ')));
    f.appendChild(btn('افتح', 'rs-btn soft', onOpen));
    return f;
  }

  function renderMeetings(box) {
    if (isChair()) box.appendChild(btn('ادعُ إلى اجتماع', 'rs-btn', callMeeting));
    else box.appendChild(el('p', 'rs-meta', 'الدعوةُ لاجتماع اللجنة لرئيسها' + P19));
    if (ui.meetingsErr) box.appendChild(el('div', 'notice err', errText(ui.meetingsErr)));
    if (!ui.meetings.length) { box.appendChild(el('p', 'rs-meta', 'لا اجتماعاتِ في المدّة.')); return; }
    for (const m of ui.meetings) box.appendChild(meetingRow(m, () => openMeeting(m.id, 'open')));
  }

  async function openMeeting(id, tab) {
    ui.openId = id;
    ui.tab = tab;
    await loadCard();
  }

  function callMeeting() {
    V.form({
      title: 'الدعوةُ إلى اجتماع',
      fields: [
        { key: 'kind', type: 'pick', label: 'نوعُه', items: [['شهري', 'شهري'], ['طارئ', 'طارئ']], value: 'شهري' },
        { key: 'on', type: 'date', label: 'التاريخ' },
        { key: 'at', type: 'time', label: 'الساعة' },
        { key: 'place', label: 'المكان' },
        { key: 'agenda', type: 'textarea', label: 'جدولُ الأعمال' },
      ],
      ok: 'ادعُ',
      onOk: async (v) => {
        const r = await call('v2_meeting_call', {
          p_school: M.state.school, p_committee: ui.key, p_kind: v.kind, p_held_on: v.on, p_started: v.at, p_place: v.place, p_agenda: v.agenda,
        }, 'الدعوة إلى اجتماع', (d) => 'دُعي ' + (d.invited || 0) + ' إلى الاجتماع ' + (d.no || ''));
        if (r.error) return r.error;
        ui.openId = r.data.meeting || null;
        ui.tab = 'open';
        reloadMin();
        return null;
      },
    });
  }

  // الاجتماعُ المفتوح — والمحضرُ للقراءة بالدالّة نفسها
  function personOf(a) {
    if (a.person_id) return a.person_id;
    for (const s of (ui.board && ui.board.seats) || []) {
      const h = (s.holders || []).find((x) => x.name === a.name);
      if (h) return h.person;
    }
    return null;
  }

  function renderOpen(box, live) {
    if (!ui.openId) { box.appendChild(el('p', 'rs-meta', 'اختر اجتماعًا من «الاجتماعات».')); return; }
    if (ui.cardErr) { box.appendChild(el('div', 'notice err', errText(ui.cardErr))); return; }
    const c = ui.card;
    if (!c) return;
    const m = c.meeting || {};
    const f = el('div', 'rs-file');
    f.append(el('h5', null, (c.committee || '') + ' — الاجتماع ' + m.meeting_no + ' · ' + (m.kind || '') + ' — ' + (m.status || '')),
      el('p', null, [m.held_on, hm(m.started_at), m.place_ar].filter(Boolean).join(' · ')));
    if (m.agenda_ar) f.appendChild(el('p', null, 'جدولُ الأعمال: ' + m.agenda_ar));
    f.appendChild(el('p', null, [m.quorum_met == null ? null : m.quorum_met ? 'النصابُ مكتمل' : 'النصابُ ناقص', c.quorum_min != null ? 'أدناه ' + c.quorum_min : null,
      m.minutes_at ? 'وُثّق ' + day(m.minutes_at) + (c.minutes_by_name ? ' — ' + c.minutes_by_name : '') : null,
      m.approved_at ? 'اعتُمد ' + day(m.approved_at) + (c.approved_by_name ? ' — ' + c.approved_by_name : '') : null].filter(Boolean).join(' · ')));
    if (m.status === 'معتمد') f.appendChild(el('div', 'rs-note', 'المحضرُ المعتمد لا يُعدَّل — وإن لزم تعديلٌ فاجتماعٌ جديدٌ يشير إليه.'));
    box.appendChild(f);
    const editable = live && m.status !== 'معتمد' && m.status !== 'موثّق' && m.status !== 'ملغًى' && m.status !== 'ملغى';
    const chairOrRap = isChair() || isRapporteur();

    // الحضور
    box.appendChild(el('h4', 'rs-sub', 'الحضور'));
    for (const a of c.attendance || []) {
      const r = el('div', 'rs-file');
      r.append(el('h5', null, a.name + ' — ' + (a.seat_ar && a.seat_ar !== '—' ? a.seat_ar : a.as || '') + (a.who && a.who !== 'منسوب' ? ' (' + a.who + ')' : '') + ' · ' + (a.state || '')));
      if (a.excuse) r.appendChild(el('p', null, 'العذر: ' + a.excuse));
      if (a.no_vote_reason) r.appendChild(el('p', null, a.no_vote_reason));
      const pid = personOf(a);
      if (editable && chairOrRap && a.as === 'عضو' && pid) {
        const p = el('div', 'rs-pick');
        pick(p, ['حاضر', 'عن بُعد', 'غائب', 'معتذر'].map((x) => [x, x]), a.state, (st) => attend(pid, a, st));
        r.appendChild(p);
      }
      box.appendChild(r);
    }
    if (editable) {
      if (!chairOrRap) box.appendChild(el('p', 'rs-meta', 'تسجيلُ الحضور للرئيس أو المقرّر' + P19));
      if (isChair()) box.appendChild(btn('استدعِ من ليس عضوًا', 'rs-btn soft', invite));
    }

    // البنود
    box.appendChild(el('h4', 'rs-sub', 'البنود'));
    const items = c.items || [];
    if (!items.length) box.appendChild(el('p', 'rs-meta', 'لا بنودَ بعد.'));
    const seat = mySeat();
    for (const it of items) {
      const r = el('div', 'rs-file');
      r.append(el('h5', null, it.ord + ' · ' + (it.title || '') + ' (' + (it.kind || '') + ') — ' + (it.outcome || '')));
      if (it.student_name) r.appendChild(el('p', null, 'الطالب: ' + it.student_name));
      const tl = it.tally || {};
      r.appendChild(el('p', null, 'صوّت ' + (it.vote_count || 0) + ' من ' + (it.voters_total || 0) + ' · موافق ' + (tl['موافق'] || 0) + ' · مخالف ' + (tl['مخالف'] || 0) + ' · ممتنع ' + (tl['ممتنع'] || 0)));
      for (const v of it.votes || []) {
        r.appendChild(el('p', null, v.name + ': ' + v.vote + (v.note ? ' — ' + v.note : '')));
        if (v.prev_vote) r.appendChild(el('p', null, 'بدّل صوتَه من «' + v.prev_vote + '»' + (v.change_note ? ' — ' + v.change_note : '') + (v.changed_at ? ' · ' + day(v.changed_at) : '')));
      }
      if (it.body) r.appendChild(el('p', null, 'المناقشة: ' + it.body));
      if (it.decision) r.appendChild(el('p', null, 'القرار: ' + it.decision));
      if (it.recommend) r.appendChild(el('p', null, 'التوصيات: ' + it.recommend + (it.owner_name ? ' · المنفّذ ' + it.owner_name : '') + (it.due ? ' · الموعد ' + it.due : '')));
      if (editable && it.outcome === 'قيد النظر') {
        if (seat) {
          const mine = (it.votes || []).find((x) => x.person_id && x.person_id === (M.state.me && M.state.me.person_id));
          const p = el('div', 'rs-pick');
          pick(p, ['موافق', 'مخالف', 'ممتنع'].map((x) => [x, x]), mine ? mine.vote : null, (v) => vote(it, v, mine));
          r.appendChild(p);
        } else r.appendChild(el('p', null, 'لستَ عضوًا في هذي اللجنة — فلا تصوّت على قراراتها' + P19));
        if (isRapporteur()) r.appendChild(btn('اقفل البند', 'rs-btn soft', () => closeItem(it)));
        else r.appendChild(el('p', 'rs-meta', 'قفلُ البند لمقرّر اللجنة' + P19));
      }
      box.appendChild(r);
    }
    if (editable && chairOrRap) {
      const row = el('div', 'rs-row');
      row.append(btn('أضِف بندًا', 'rs-btn soft', addItem), btn('رحّل القراراتِ غيرَ المنفّذة', 'rs-btn soft', carry));
      box.appendChild(row);
    }

    // التوثيقُ والاعتماد
    if (live && m.status === 'منعقد') {
      if (isRapporteur()) box.appendChild(btn('وثّق المحضر', 'rs-btn big', minute));
      else box.appendChild(el('p', 'rs-meta', 'توثيقُ المحضر لمقرّر اللجنة' + P19));
    }
    if (live && m.status === 'موثّق') {
      if (isChair()) box.appendChild(btn('اعتمد المحضر', 'rs-btn big', approve));
      else box.appendChild(el('p', 'rs-meta', 'اعتمادُ المحضر لرئيس اللجنة' + P19));
    }
  }

  async function attend(pid, a, st) {
    if (st === 'معتذر') {
      V.form({
        title: 'اعتذارٌ عن الحضور', what: a.name, fields: [{ key: 'ex', type: 'textarea', label: 'العذر' }], ok: 'سجّله',
        onOk: async (v) => {
          const r = await call('v2_meeting_attend', { p_meeting: ui.openId, p_person: pid, p_state: st, p_excuse: v.ex }, 'تسجيل الحضور', 'سُجّل: ' + a.name + ' — ' + st);
          if (r.error) return r.error;
          reloadMin();
          return null;
        },
      });
      return;
    }
    // ضغطةٌ واحدة — ولا أثرَ قبل ردّ القاعدة
    flash('wait', 'يُسجَّل… ' + a.name + ' — ' + st);
    const r = await call('v2_meeting_attend', { p_meeting: ui.openId, p_person: pid, p_state: st, p_excuse: null }, 'تسجيل الحضور',
      (d) => 'سُجّل: ' + a.name + ' — ' + st + (d.members != null ? ' · ردّ ' + d.replied + ' من ' + d.members : ''));
    if (r.error) { flash('bad', errText(r.error)); return; }
    reloadMin();
  }

  async function invite() {
    const [sl, stl] = await Promise.all([staff(), students()]);
    if (!sl || !stl) return;
    let kind = 'منسوب';
    const open = () => V.form({
      title: 'استدعاءُ من ليس عضوًا', what: 'يشارك في المناقشة ولا يصوّت على قرارات اللجنة' + P19,
      fields: [
        { key: 'kind', type: 'pick', label: 'من', items: [['منسوب', 'منسوب'], ['طالب', 'طالب']], value: kind, onChange: (x) => { kind = x; open(); } },
        { key: 'who', type: 'choose', label: 'الاسم — من السجلّ', items: kind === 'طالب' ? stuItems(stl) : staffItems(sl) },
        { key: 'note', type: 'textarea', label: 'سببُ الاستدعاء', rows: 2 },
      ],
      ok: 'استدعِ',
      onOk: async (v) => {
        const r = await call('v2_meeting_invite', {
          p_meeting: ui.openId, p_kind: v.kind, p_person: v.kind === 'منسوب' ? v.who : null, p_student: v.kind === 'طالب' ? v.who : null,
          p_guardian: null, p_note: v.note,
        }, 'استدعاء للّجنة', (d) => 'استُدعي' + (d.note ? ' — ' + d.note : ''));
        if (r.error) return r.error;
        reloadMin();
        return null;
      },
    });
    open();
  }

  async function addItem() {
    let kind = 'عام';
    const stl = await students();
    if (!stl) return;
    const open = (keep) => {
      const fields = [
        { key: 'kind', type: 'pick', label: 'نوعُه', items: [['عام', 'عام'], ['طالب', 'طالب'], ['فرصة', 'فرصة'], ['تقرير', 'تقرير']], value: kind, onChange: (x, api) => { const t = api.values().title; kind = x; open(t); } },
        { key: 'title', label: 'عنوانُه', value: keep || null },
      ];
      if (kind === 'طالب') fields.push({ key: 'stu', type: 'choose', label: 'الطالب — من السجلّ', items: stuItems(stl) });
      if (ui.duties.length) fields.push({ key: 'duty', type: 'choose', label: 'من مهامّ اللجنة (اختياري)', items: ui.duties.map((d) => [d.id, d.text, d.cadence || '']) });
      if (kind === 'فرصة' && ui.opps.length) fields.push({ key: 'opp', type: 'choose', label: 'الفرصة', items: ui.opps.map((o) => [o.opp, o.title || o.merit, o.state || '']) });
      V.form({
        title: 'بندٌ في جدول الأعمال', fields, ok: 'أضِف البند',
        onOk: async (v) => {
          const r = await call('v2_meeting_item', {
            p_meeting: ui.openId, p_kind: v.kind, p_title: v.title, p_student: v.kind === 'طالب' ? v.stu : null,
            p_record: null, p_opp: v.kind === 'فرصة' ? (v.opp || null) : null, p_duty: v.duty || null,
          }, 'بند في جدول الأعمال', (d) => 'أُضيف البند ' + (d.ord || ''));
          if (r.error) return r.error;
          reloadMin();
          return null;
        },
      });
    };
    open(null);
  }

  async function carry() {
    flash('wait', 'يُرحَّل…');
    const r = await call('v2_meeting_carry_over', { p_meeting: ui.openId }, 'ترحيل المتابعة', (d) => d.note || 'رُحّل');
    if (r.error) { flash('bad', errText(r.error)); return; }
    reloadMin();
  }

  async function vote(it, v, mine) {
    if (mine && mine.vote === v) { flash('ok', 'صوّتَّ «' + v + '» سلفًا'); return; }
    // تبديلُ الصوت والمخالفةُ يطلبان نصًّا يُثبت في المحضر — وما سواهما ضغطةٌ واحدة
    if (mine || v === 'مخالف') {
      const fields = [];
      if (mine) fields.push({ key: 'change', type: 'textarea', label: 'سببُ التبديل — يُثبت في المحضر', rows: 2 });
      if (v === 'مخالف') fields.push({ key: 'note', type: 'textarea', label: 'رأيُك المخالف — يُثبت في المحضر', rows: 2 });
      V.form({
        title: mine ? 'تبديلُ الصوت من «' + mine.vote + '» إلى «' + v + '»' : 'مخالفةُ القرار', what: it.title || '', fields, ok: 'سجّل صوتي',
        onOk: async (x) => {
          const r = await call('v2_meeting_vote', { p_item: it.id, p_vote: v, p_note: x.note || null, p_change_note: x.change || null }, 'تصويت', 'سُجّل صوتُك: ' + v);
          if (r.error) return r.error;
          reloadMin();
          return null;
        },
      });
      return;
    }
    flash('wait', 'يُسجَّل صوتُك… ' + v);
    const r = await call('v2_meeting_vote', { p_item: it.id, p_vote: v, p_note: null, p_change_note: null }, 'تصويت', 'سُجّل صوتُك: ' + v);
    if (r.error) { flash('bad', errText(r.error)); return; }
    reloadMin();
  }

  async function closeItem(it) {
    const list = await staff();
    if (!list) return;
    V.form({
      title: 'قفلُ البند', what: it.title || '',
      fields: [
        { key: 'body', type: 'textarea', label: 'ما دار من مناقشة' },
        { key: 'decision', type: 'textarea', label: 'القرار', rows: 2 },
        { key: 'rec', type: 'textarea', label: 'التوصياتُ ومن ينفّذها', rows: 2 },
        { key: 'owner', type: 'choose', label: 'المنفّذ (اختياري)', items: staffItems(list) },
        { key: 'due', type: 'date', label: 'الموعد' },
      ],
      ok: 'اقفل البند',
      onOk: async (v) => {
        const r = await call('v2_meeting_close_item', {
          p_item: it.id, p_body: v.body, p_decision: v.decision, p_recommend: v.rec, p_owner: v.owner || null, p_due: v.due,
        }, 'قفل البند', (d) => 'قُفل البند: ' + (d.outcome || '') + ' · موافق ' + (d['موافق'] || 0) + ' · مخالف ' + (d['مخالف'] || 0) + ' · ممتنع ' + (d['ممتنع'] || 0) + (d['رجّح_الرئيس'] ? ' · رجّح الرئيس' : ''));
        if (r.error) return r.error;
        reloadMin();
        return null;
      },
    });
  }

  function minute() {
    V.form({
      title: 'توثيقُ المحضر', fields: [{ key: 'end', type: 'time', label: 'انتهى الاجتماعُ الساعة' }], ok: 'وثّق',
      onOk: async (v) => {
        const r = await call('v2_meeting_minute', { p_meeting: ui.openId, p_ended: v.end }, 'توثيق المحضر',
          (d) => 'وُثّق المحضر' + (d.quorum == null ? '' : d.quorum ? ' · والنصابُ مكتمل' : ' · والنصابُ ناقص'));
        if (r.error) return r.error;
        reloadMin();
        return null;
      },
    });
  }

  async function approve() {
    flash('wait', 'يُعتمد…');
    const r = await call('v2_meeting_approve', { p_meeting: ui.openId }, 'اعتماد المحضر', (d) => 'اعتُمد المحضر · مهامُّه ' + (d.tasks || 0));
    if (r.error) { flash('bad', errText(r.error)); return; }
    reloadMin();
  }

  // المحاضر — الموثّقُ والمعتمد للقراءة
  function renderMinutes(box) {
    const done = ui.meetings.filter((m) => m.status === 'موثّق' || m.status === 'معتمد');
    if (ui.openId && ui.card && done.some((m) => m.id === ui.openId)) {
      box.appendChild(btn('← المحاضرُ كلُّها', 'rs-btn ghost', () => { ui.openId = null; ui.card = null; renderMin(); }));
      renderOpen(box, false);
      return;
    }
    if (!done.length) { box.appendChild(el('p', 'rs-meta', 'لا محاضرَ موثّقةً بعد.')); return; }
    for (const m of done) box.appendChild(meetingRow(m, () => openMeeting(m.id, 'minutes')));
  }

  // ما عليّ — قراراتُ المحاضر المعتمدة المسندةُ إليك
  function renderMine(box) {
    if (ui.mineErr) box.appendChild(el('div', 'notice err', errText(ui.mineErr)));
    if (!ui.mine.length) { box.appendChild(el('p', 'rs-meta', 'لا قرارَ مسندًا إليك لم يُنفَّذ.')); return; }
    for (const t of ui.mine) box.appendChild(V.committeeTask(t, reloadMin));
  }

  M.start({ screen: 'lajna', onChange: () => refresh() });
})();
