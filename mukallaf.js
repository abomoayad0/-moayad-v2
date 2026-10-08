// مؤيّد · ما عليّ — viewK في المحاكي (شاشةُ المكلَّف): لكلّ منسوبٍ ما أُسند إليه وحدَه.
// ① إثباتُ مشاركة طالب: ما أُحيل إليك إقرارُه (v2_entries_pending · delegated_to_me) ⇒ v2_entry_verdict
// ② رأيٌ مطلوبٌ منك: لم يُبنَ في المحرّك
// ③ كُلّفتَ بحصر سلوكيّات طالب: v2_my_census ⇒ v2_census_file بالقوائم (v2_census_list) — سلبيٌّ واحدٌ على الأقلّ والمسبّباتُ إلزاميّة
// ④ ما عليّ من اللجان: v2_my_committee_tasks ⇒ v2_committee_task_done
// ويومي: v2_my_now · v2_my_sections · v2_my_duties · v2_mail_my_tasks — للقراءة كما ترجع
// ترى هذا الجزءَ وحدَه: لا ملفَّ طالبٍ ولا دراسةَ حالة.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    renderOff();
    await Promise.all([loadMine(), loadDelegated(), loadCensus(), loadCommittee()]);
  }

  // ---------- يومي: كلٌّ من جسره كما يرجع — ولا حسابَ هنا ----------
  const hm = (t) => (t ? String(t).slice(0, 5) : '');
  const list = (box, r, empty, line) => {
    box.textContent = '';
    if (r.error) { box.appendChild(el('div', 'notice err', errText(r.error))); return; }
    const rows = r.data || [];
    if (!rows.length) { box.appendChild(el('p', 'rs-meta', empty)); return; }
    const ul = el('ul', 'rs-acts');
    for (const x of rows) { const [main, sub, who, done] = line(x); const li = el('li'); const b = el('span'); b.style.flex = '1'; b.appendChild(el('b', null, main)); if (sub) b.appendChild(el('div', 'rs-meta', sub)); li.append(el('i', 'rs-tick' + (done ? ' ok' : ''), done ? '✓' : '○'), b, el('small', 'rs-who', who || '')); ul.appendChild(li); }
    box.appendChild(ul);
    V.arabize(box);
  };
  async function loadMine() {
    const [now, sec, dut, mail] = await Promise.all([
      M.rpc('v2_my_now', { p_school: M.state.school }, 'الآن'),
      M.rpc('v2_my_sections', { p_date: M.state.date || null }, 'حصصي اليوم'),
      M.rpc('v2_my_duties', { p_school: M.state.school }, 'مناوبتي'),
      M.rpc('v2_mail_my_tasks', { p_school: M.state.school }, 'ما عليّ من الوارد'),
    ]);
    list($('now'), now, 'لا حصّةَ عليك الآن.', (x) => ['الحصّة ' + x.period_no + ' · ' + (x.section_label || ''), [x.subject_ar, x.room_ar, x.students_n != null ? x.students_n + ' طالبًا' : null].filter(Boolean).join(' · '), hm(x.starts_at) + ' — ' + hm(x.ends_at) + (x.state ? ' · ' + x.state : ''), false]);
    list($('sections'), sec, 'لا حصصَ لك اليوم.', (x) => ['الحصّة ' + x.period_no + ' · ' + (x.class_ar || ''), [x.subject_ar, 'رُصد ' + x.recorded_n + ' من ' + x.students_n].filter(Boolean).join(' · '), hm(x.starts_at) + ' — ' + hm(x.ends_at) + (x.state ? ' · ' + x.state : ''), x.is_done]);
    list($('duties'), dut, 'لا مناوبةَ لك.', (x) => [(x.weekday_ar || '') + ' · ' + (x.zone_ar || ''), [x.segment, x.kind].filter(Boolean).join(' · '), '', false]);
    list($('mail'), mail, 'لا شيءَ عليك من الوارد.', (x) => ['وارد ' + (x.serial_no || '') + ' · ' + (x.subject_ar || ''), x.text_ar || '', (x.due_h || '') + (x.is_late ? ' · متأخّر' : ''), false]);
  }

  async function loadDelegated() {
    const { data, error } = await M.rpc('v2_entries_pending', { p_school: M.state.school }, 'ما أُحيل إليك');
    const box = $('dlg');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    // ما أُحيل إليك وحدَه — لا ما تقيمه ولا ما يراه المالك
    const mine = (data || []).filter((x) => x.delegated_to_me === true);
    if (!mine.length) { box.appendChild(el('p', 'rs-meta', 'لم يُحَل إليك إقرارُ مشاركة.')); return; }
    for (const x of mine) box.appendChild(V.verdictCard(x, { onDone: loadDelegated }));
    V.arabize(box);
  }

  async function loadCensus() {
    const { data, error } = await M.rpc('v2_my_census', { p_school: M.state.school }, 'ما كُلّفتَ بحصره');
    const box = $('census');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const list = data || [];
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لم تُكلَّف بحصر سلوكيّات طالب.')); return; }
    for (const c of list) {
      const f = el('div', 'rs-file');
      f.append(el('h5', null, (c.student || '') + (c.problem ? ' — ' + c.problem : '')),
        el('p', null, ['كلّفك ' + (c.by || '—'), 'المدّة ' + (c.days_ar || ''), 'يُسلَّم ' + (c.due || '—'), c.state].filter(Boolean).join(' · ')));
      if (c.late) f.lastChild.className = 'rs-state-open';
      if (c.returned_why) f.appendChild(el('p', null, 'أُعيد إليك: ' + c.returned_why));
      f.appendChild(V.btn('اكتب الحصر', 'rs-btn', () => fileCensus(c)));
      box.appendChild(f);
    }
    V.arabize(box);
  }

  // الحصرُ من قوائم المدرسة بأيقوناتها: لمسةٌ تشرح والثانيةُ تختار — والمسبّباتُ بكلامه، وتحتها بنكُ العبارات لفريق المدرسة
  let lists = null;
  async function fileCensus(c) {
    if (!lists || lists.school !== M.state.school) {
      const { data, error } = await M.rpc('v2_census_list', { p_school: M.state.school }, 'قوائم الحصر');
      if (error) { V.flash('bad', errText(error)); return; }
      lists = { school: M.state.school, negative: (data && data.negative) || [], positive: (data && data.positive) || [] };
    }
    V.form({
      title: 'حصرُ سلوكيّات الطالب', what: (c.student || '') + (c.problem ? ' — ' + c.problem : ''),
      fields: [
        { key: 'neg', type: 'icons', label: 'السلوكيّاتُ السلبيّة', items: lists.negative },
        { key: 'pos', type: 'icons', label: 'السلوكيّاتُ الإيجابيّة', items: lists.positive },
        { key: 'causes', type: 'textarea', label: 'المسبّبات', bank: { key: 'cause' } },
        { key: 'sug', type: 'textarea', label: 'مقترحُك (اختياري)', rows: 2, bank: { key: 'limit' } },
      ],
      ok: 'سلّم الحصر',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_census_file', { p_census: c.census, p_neg: v.neg, p_pos: v.pos, p_causes: v.causes, p_suggestion: v.sug }, 'تسليم الحصر');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'سُلّم الحصر');
        loadCensus();
        return null;
      },
    });
  }

  async function loadCommittee() {
    const { data, error } = await M.rpc('v2_my_committee_tasks', { p_school: M.state.school }, 'ما عليّ من اللجان');
    const box = $('ctasks');
    box.textContent = '';
    if (error) { box.appendChild(el('div', 'notice err', errText(error))); return; }
    const list = data || [];
    if (!list.length) { box.appendChild(el('p', 'rs-meta', 'لا قرارَ مسندًا إليك لم يُنفَّذ.')); return; }
    for (const t of list) box.appendChild(V.committeeTask(t, loadCommittee));
  }

  function renderOff() {
    const box = $('offCards');
    box.textContent = '';
    box.append(V.offCard('رأيٌ مطلوبٌ منك', 'رأيُ المعلّم في خطّة تعديل السلوك — نموذج ٣ · القسمُ السادس'));
  }

  M.start({ screen: 'mukallaf', onChange: () => refresh() });
})();
