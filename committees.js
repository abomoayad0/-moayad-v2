// مؤيّد · اللجان — مجلسُ اللجنة · الاجتماعات · اجتماعٌ مفتوح · المحاضر.
// v2_committee_board · v2_committee_seat · v2_committee_unseat · v2_meetings_list · v2_meeting_call
// v2_meeting_attend · v2_meeting_invite · v2_meeting_item · v2_meeting_vote · v2_meeting_close_item
// v2_meeting_minute · v2_meeting_approve · v2_meeting_card
// الشاشة لا تقرّر شيئاً: من يدعو ومن يصوّت والنصاب والقفل كلّها في القاعدة، ورفضُها يُعرض بنصّه.
// وما يُعرض من أزرار يُقرأ من مقعد الداخل في القاعدة (holders[].person مع v2_me.person_id).
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, toast, errText, showLoadErr } = M;
  M.state.screen = 'committees';

  const KEYS = ['guidance', 'admin', 'achievement', 'excellence', 'fund', 'safety', 'sped'];
  const STATUS_CLS = { 'مدعوّ إليه': 'st-called', 'منعقد': 'st-held', 'موثّق': 'st-minuted', 'معتمد': 'st-approved', 'ملغى': 'st-cancel', 'ملغًى': 'st-cancel' };
  const P19 = ' — ص١٩';

  const ui = {
    me: null, school: null, key: 'guidance', labels: {}, board: null, meetings: [],
    openId: null, card: null, staff: null, students: null, tab: 'board', minutesOpen: false,
  };

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }
  function btn(cls, text, fn) {
    const b = el('button', cls, text);
    b.type = 'button';
    b.addEventListener('click', fn);
    return b;
  }

  // مقعدي في اللجنة — من شاغلي المقاعد كما أرجعتهم القاعدة
  function mySeat() {
    const me = ui.me && ui.me.person_id;
    for (const s of (ui.board && ui.board.seats) || []) {
      if ((s.holders || []).some((h) => h.person === me)) return s;
    }
    return null;
  }
  const isChair = () => { const s = mySeat(); return !!s && s.role === 'chair'; };
  const isRapporteur = () => { const s = mySeat(); return !!s && s.role === 'rapporteur'; };

  // ---------- الجلب ----------
  async function loadBoard() {
    showLoadErr('');
    const { data, error } = await M.rpc('v2_committee_board', { p_school: ui.school, p_committee: ui.key }, 'مجلس اللجنة');
    if (error) { showLoadErr(errText(error)); ui.board = null; renderAll(); return; }
    ui.board = data;
    renderSeatLine();
    await loadMeetings();
  }

  async function loadMeetings() {
    const { data, error } = await M.rpc('v2_meetings_list',
      { p_school: ui.school, p_committee: ui.key, p_status: null, p_days: 180 }, 'قائمة الاجتماعات');
    ui.meetings = error ? [] : (data || []);
    ui.meetingsErr = error ? errText(error) : '';
    if (ui.openId) await loadCard(); else renderAll();
  }

  async function loadCard() {
    const { data, error } = await M.rpc('v2_meeting_card', { p_meeting: ui.openId }, 'محضر الاجتماع');
    ui.card = error ? null : data;
    ui.cardErr = error ? errText(error) : '';
    renderAll();
  }

  async function staff() {
    if (ui.staff) return ui.staff;
    const { data, error } = await M.rpc('v2_staff_list', { p_school: ui.school }, 'قائمة المنسوبين');
    if (error) { toast('تعذّر جلب المنسوبين:\n' + errText(error)); return null; }
    ui.staff = data || [];
    return ui.staff;
  }
  async function students() {
    if (ui.students) return ui.students;
    const today = new Date().toISOString().slice(0, 10);
    const { data, error } = await M.rpc('v2_day_list', { p_school: ui.school, p_date: today }, 'قائمة الطلاب');
    if (error) { toast('تعذّر جلب الطلاب:\n' + errText(error)); return null; }
    ui.students = data || [];
    return ui.students;
  }

  // ---------- العرض ----------
  function renderSeatLine() {
    const b = ui.board;
    const label = (b && b.committee && b.committee.label) || ui.labels[ui.key] || ui.key;
    $('seatLine').textContent = b && b.my_seat
      ? 'وصفتك في «' + label + '»: ' + b.my_seat
      : 'لست عضواً في «' + label + '».';
  }

  function renderAll() {
    renderSeatLine();
    renderBoard();
    renderMeetings();
    renderOpen();
    renderMinutes();
    for (const t of ['board', 'meetings', 'open', 'minutes']) $('t_' + t).hidden = ui.tab !== t;
    for (const b of document.querySelectorAll('#tabs button')) b.setAttribute('aria-pressed', String(b.dataset.tab === ui.tab));
  }

  // ١ · مجلس اللجنة
  function renderBoard() {
    const box = $('t_board');
    box.textContent = '';
    const b = ui.board;
    if (!b) return;
    const c = b.committee || {};
    if (c.purpose) box.appendChild(el('p', 'hint', c.purpose));
    box.appendChild(el('div', 'meta', c.quorum == null ? 'لم يُحدَّد نصابٌ بعد' : 'النصاب: ' + c.quorum));
    if (c.quorum_note) box.appendChild(el('div', 'meta', c.quorum_note));
    for (const s of (b.seats || []).slice().sort((x, y) => x.ord - y.ord)) {
      const holders = s.holders || [];
      const card = el('div', 'ev seat' + (holders.length === 0 ? ' empty-seat' : ''));
      const top = el('div', 'row1');
      top.append(el('div', 'name', s.role_ar || ''), el('span', 'badge ' + (holders.length < s.count ? 'b-absent' : 'b-permitted'), holders.length + ' من ' + s.count));
      card.appendChild(top);
      if (s.post) card.appendChild(el('div', 'meta', 'الوظيفة: ' + s.post));
      if (s.elected) card.appendChild(el('div', 'meta', 'يختاره مديرُ المدرسة'));
      if (holders.length === 0) card.appendChild(el('div', 'detail red', 'لم يُشغل بعد'));
      for (const h of holders) {
        const line = el('div', 'holder');
        line.appendChild(el('span', null, h.name + (h.since ? ' · منذ ' + h.since : '') + (h.nominated_by ? ' · ' + h.nominated_by : '')));
        line.appendChild(btn('rowdel', 'أخرِجه', () => unseat(h)));
        card.appendChild(line);
      }
      card.appendChild(btn('btn-ghost wide', 'أجلِس في هذا المقعد', () => seat(s)));
      box.appendChild(card);
    }
    if (c.source) box.appendChild(el('div', 'meta src', 'السند: ' + c.source));
  }

  async function seat(s) {
    const list = await staff();
    if (!list) return;
    $('seatTitle').textContent = 'إجلاس في مقعد «' + (s.role_ar || '') + '»' + (s.post ? ' — ' + s.post : '');
    const sel = $('seatPerson');
    sel.textContent = '';
    // مقعد الوظيفة: شاغلها أوّلاً كما في سجلّ المنسوبين — والقاعدة ترفض غيره
    const fit = s.post ? list.filter((p) => p.post_ar === s.post || (p.roles_ar || '').includes(s.post)) : list;
    for (const p of (fit.length ? fit : list)) {
      const o = document.createElement('option');
      o.value = p.person_id;
      o.textContent = p.name_ar + (p.post_ar ? ' — ' + p.post_ar : '');
      sel.appendChild(o);
    }
    $('seatNomBox').hidden = !s.elected;
    $('seatNom').value = '';
    if (await ask($('seatDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_committee_seat', {
      p_school: ui.school, p_committee: ui.key, p_seat_role: s.role, p_person: sel.value,
      p_post_key: s.post_key || null, p_nominated_by: s.elected ? ($('seatNom').value.trim() || null) : null,
    }, 'إجلاس عضو');
    if (error) { toast('لم يُجلَس:\n' + errText(error)); return; }
    toast('أُجلس في المقعد.', true);
    loadBoard();
  }

  async function reason(title, what, label) {
    $('reasonTitle').textContent = title;
    $('reasonWhat').textContent = what;
    $('reasonLabel').textContent = label || 'السبب — إلزامي';
    $('reasonText').value = '';
    $('reasonOk').disabled = true;
    if (await ask($('reasonDlg')) !== 'ok') return null;
    return $('reasonText').value.trim();
  }

  async function unseat(h) {
    const r = await reason('إخراج من اللجنة', h.name);
    if (r == null) return;
    const { error } = await M.rpc('v2_committee_unseat', { p_school: ui.school, p_committee: ui.key, p_person: h.person, p_reason: r }, 'إخراج عضو');
    if (error) { toast('لم يُخرَج:\n' + errText(error)); return; }
    toast('أُخرج من المقعد.', true);
    loadBoard();
  }

  // ٢ · الاجتماعات
  function meetingRow(m, onOpen) {
    const r = el('div', 'ev meeting ' + (STATUS_CLS[m.status] || ''));
    const top = el('div', 'row1');
    top.append(el('div', 'name', 'الاجتماع ' + m.no + ' · ' + (m.kind || '')), el('span', 'badge mstatus', m.status || ''));
    r.appendChild(top);
    r.appendChild(el('div', 'meta', [m.held_on, m.started && String(m.started).slice(0, 5), m.place].filter(Boolean).join(' · ')));
    if (m.agenda) r.appendChild(el('div', 'meta', 'جدول الأعمال: ' + m.agenda));
    r.appendChild(el('div', 'meta', 'البنود: ' + (m.items == null ? 0 : m.items) + (m.called_by ? ' · دعا إليه: ' + m.called_by : '') + (m.approved_by ? ' · اعتمده: ' + m.approved_by : '')));
    if (m.quorum_met != null) r.appendChild(el('div', 'meta', m.quorum_met ? 'النصاب مكتمل' : 'النصاب ناقص'));
    r.appendChild(btn('btn-ghost wide', 'افتح', onOpen));
    return r;
  }

  function renderMeetings() {
    const box = $('t_meetings');
    box.textContent = '';
    if (!ui.board) return;
    if (isChair()) box.appendChild(btn('btn-main', 'ادعُ إلى اجتماع', call));
    else box.appendChild(el('p', 'hint nocan', 'الدعوةُ لاجتماع اللجنة لرئيسها' + P19));
    if (ui.meetingsErr) box.appendChild(el('div', 'notice err', ui.meetingsErr));
    if (!ui.meetings.length) { box.appendChild(el('div', 'empty', 'لا اجتماعات في المدة.')); return; }
    for (const m of ui.meetings) box.appendChild(meetingRow(m, () => openMeeting(m.id, 'open')));
  }

  async function openMeeting(id, tab) {
    ui.openId = id;
    ui.tab = tab;
    ui.minutesOpen = tab === 'minutes';
    await loadCard();
  }

  async function call() {
    $('callOn').value = '';
    $('callAt').value = '';
    $('callPlace').value = '';
    $('callAgenda').value = '';
    $('callOk').disabled = true;
    if (await ask($('callDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_meeting_call', {
      p_school: ui.school, p_committee: ui.key, p_kind: $('callKind').value,
      p_held_on: $('callOn').value || null, p_started: $('callAt').value || null,
      p_place: $('callPlace').value.trim() || null, p_agenda: $('callAgenda').value.trim(),
    }, 'الدعوة إلى اجتماع');
    if (error) { toast('لم تقع الدعوة:\n' + errText(error)); return; }
    toast('دُعي ' + ((data && data.invited) || 0) + ' أعضاء إلى الاجتماع ' + ((data && data.no) || '') + '.', true);
    ui.openId = data && data.meeting;
    ui.tab = 'open';
    await loadMeetings();
  }

  // ٣ · اجتماعٌ مفتوح
  function personOf(a) {
    if (a.person_id) return a.person_id;
    // لا يُرجع المحضر معرّف الحاضر بعد — فيُقرأ من شاغلي المقاعد بالاسم نفسه
    for (const s of (ui.board && ui.board.seats) || []) {
      const h = (s.holders || []).find((x) => x.name === a.name);
      if (h) return h.person;
    }
    return null;
  }

  function cardView(box, live) {
    const c = ui.card;
    const m = c.meeting || {};
    const head = el('div', 'ev meeting ' + (STATUS_CLS[m.status] || ''));
    const top = el('div', 'row1');
    top.append(el('div', 'name', (c.committee || '') + ' — الاجتماع ' + m.meeting_no + ' · ' + (m.kind || '')), el('span', 'badge mstatus', m.status || ''));
    head.appendChild(top);
    head.appendChild(el('div', 'meta', [m.held_on, m.started_at && String(m.started_at).slice(0, 5), m.place_ar].filter(Boolean).join(' · ')));
    if (m.agenda_ar) head.appendChild(el('div', 'meta', 'جدول الأعمال: ' + m.agenda_ar));
    if (m.quorum_met != null) head.appendChild(el('div', 'meta', m.quorum_met ? 'النصاب مكتمل' : 'النصاب ناقص'));
    if (m.minutes_at) head.appendChild(el('div', 'meta', 'وُثّق في ' + String(m.minutes_at).slice(0, 10) + (m.ended_at ? ' · انتهى ' + String(m.ended_at).slice(0, 5) : '')));
    if (m.approved_at) head.appendChild(el('div', 'meta', 'اعتُمد في ' + String(m.approved_at).slice(0, 10)));
    if (m.status === 'معتمد') head.appendChild(el('div', 'detail', 'المحضرُ المعتمد لا يُعدَّل — وإن لزم تعديلٌ فاجتماعٌ جديدٌ يشير إليه.'));
    box.appendChild(head);
    const editable = live && m.status !== 'معتمد' && m.status !== 'موثّق';

    // الحضور
    box.appendChild(el('h3', 'grp', 'الحضور'));
    for (const a of c.attendance || []) {
      const r = el('div', 'ev att');
      const t = el('div', 'row1');
      t.append(el('div', 'name', a.name + ' — ' + (a.seat_ar && a.seat_ar !== '—' ? a.seat_ar : a.as) + (a.who && a.who !== 'منسوب' ? ' (' + a.who + ')' : '')), el('span', 'badge', a.state || ''));
      r.appendChild(t);
      if (a.excuse) r.appendChild(el('div', 'meta', 'العذر: ' + a.excuse));
      if (a.no_vote_reason) r.appendChild(el('div', 'novote', a.no_vote_reason));
      if (editable && a.as === 'عضو') {
        const pid = personOf(a);
        if (pid) {
          const acts = el('div', 'acts three');
          for (const st of ['حاضر', 'غائب', 'معتذر']) {
            const b = btn(a.state === st ? 'on' : '', st, () => attend(pid, a, st));
            acts.appendChild(b);
          }
          r.appendChild(acts);
        }
      }
      box.appendChild(r);
    }
    if (editable) {
      if (isChair()) box.appendChild(btn('btn-ghost wide', 'استدعِ من ليس عضواً', invite));
      else box.appendChild(el('p', 'hint nocan', 'استدعاءُ من ليس عضواً لرئيس اللجنة' + P19));
    }

    // البنود
    box.appendChild(el('h3', 'grp', 'البنود'));
    const items = c.items || [];
    if (!items.length) box.appendChild(el('div', 'empty', 'لا بنود بعد.'));
    const seat = mySeat();
    for (const it of items) {
      const r = el('div', 'ev item');
      const t = el('div', 'row1');
      t.append(el('div', 'name', it.ord + ' · ' + (it.title || '') + ' (' + (it.kind || '') + ')'), el('span', 'badge', it.outcome || ''));
      r.appendChild(t);
      const tl = it.tally || {};
      r.appendChild(el('div', 'meta', 'صوّت ' + (it.vote_count || 0) + ' من ' + (it.voters_total || 0) +
        ' · موافق ' + (tl['موافق'] || 0) + ' · مخالف ' + (tl['مخالف'] || 0) + ' · ممتنع ' + (tl['ممتنع'] || 0)));
      for (const v of it.votes || []) r.appendChild(el('div', 'vote', v.name + ': ' + v.vote + (v.note ? ' — ' + v.note : '')));
      if (it.body) r.appendChild(el('div', 'detail', 'المناقشة: ' + it.body));
      if (it.decision) r.appendChild(el('div', 'detail', 'القرار: ' + it.decision));
      if (it.recommend) r.appendChild(el('div', 'detail', 'التوصيات: ' + it.recommend + (it.due ? ' · الموعد ' + it.due : '')));
      const open = editable && it.outcome === 'قيد النظر';
      if (open) {
        if (seat) {
          const acts = el('div', 'acts three');
          for (const v of ['موافق', 'مخالف', 'ممتنع']) acts.appendChild(btn('', v, () => vote(it, v)));
          r.appendChild(acts);
        } else {
          r.appendChild(el('div', 'novote', 'لست عضواً في هذه اللجنة — فلا تصوّت على قراراتها' + P19));
        }
        if (isRapporteur()) r.appendChild(btn('btn-ghost wide', 'اقفل البند', () => closeItem(it)));
        else r.appendChild(el('p', 'hint nocan', 'قفلُ البند لمقرّر اللجنة' + P19));
      }
      box.appendChild(r);
    }
    if (editable) box.appendChild(btn('btn-ghost wide', 'أضِف بنداً', addItem));

    // التوثيق والاعتماد
    if (live && m.status === 'منعقد') {
      if (isRapporteur()) box.appendChild(btn('btn-main', 'وثّق المحضر', minute));
      else box.appendChild(el('p', 'hint nocan', 'توثيقُ المحضر لمقرّر اللجنة' + P19));
    }
    if (live && m.status === 'موثّق') {
      if (isChair()) box.appendChild(btn('btn-main', 'اعتمد المحضر', approve));
      else box.appendChild(el('p', 'hint nocan', 'اعتمادُ المحضر لرئيس اللجنة' + P19));
    }
  }

  function renderOpen() {
    const box = $('t_open');
    box.textContent = '';
    if (!ui.openId) { box.appendChild(el('div', 'empty', 'اختر اجتماعاً من «الاجتماعات».')); return; }
    if (ui.cardErr) { box.appendChild(el('div', 'notice err', ui.cardErr)); return; }
    if (ui.card) cardView(box, true);
  }

  async function attend(pid, a, st) {
    let excuse = null;
    if (st === 'معتذر') {
      excuse = await reason('اعتذار عن الحضور', a.name, 'العذر — إلزامي');
      if (excuse == null) return;
    }
    const { error } = await M.rpc('v2_meeting_attend', { p_meeting: ui.openId, p_person: pid, p_state: st, p_excuse: excuse }, 'تسجيل الحضور');
    if (error) { toast('لم يُسجَّل:\n' + errText(error)); return; }
    await loadMeetings();
  }

  async function invite() {
    const fill = async () => {
      const sel = $('invWho');
      sel.textContent = '';
      const kind = $('invKind').value;
      const list = kind === 'طالب' ? await students() : await staff();
      for (const p of list || []) {
        const o = document.createElement('option');
        if (kind === 'طالب') { o.value = p.student_id; o.textContent = (p.display_name || p.full_name) + ' — ' + p.student_no; }
        else { o.value = p.person_id; o.textContent = p.name_ar + (p.post_ar ? ' — ' + p.post_ar : ''); }
        sel.appendChild(o);
      }
    };
    $('invKind').onchange = fill;
    $('invNote').value = '';
    await fill();
    if (await ask($('inviteDlg')) !== 'ok') return;
    const kind = $('invKind').value;
    const who = $('invWho').value;
    const { data, error } = await M.rpc('v2_meeting_invite', {
      p_meeting: ui.openId, p_kind: kind, p_person: kind === 'منسوب' ? who : null,
      p_student: kind === 'طالب' ? who : null, p_guardian: null, p_note: $('invNote').value.trim() || null,
    }, 'استدعاء للّجنة');
    if (error) { toast('لم يُستدعَ:\n' + errText(error)); return; }
    toast('استُدعي.' + (data && data.note ? '\n' + data.note : ''), true);
    await loadMeetings();
  }

  async function addItem() {
    $('itemTitle').value = '';
    $('itemKind').value = 'عام';
    $('itemStuBox').hidden = true;
    $('itemKind').onchange = async () => {
      const isStu = $('itemKind').value === 'طالب';
      $('itemStuBox').hidden = !isStu;
      if (isStu) {
        const sel = $('itemStu');
        if (!sel.options.length) {
          for (const p of (await students()) || []) {
            const o = document.createElement('option');
            o.value = p.student_id;
            o.textContent = (p.display_name || p.full_name) + ' — ' + p.student_no;
            sel.appendChild(o);
          }
        }
      }
    };
    if (await ask($('itemDlg')) !== 'ok') return;
    const kind = $('itemKind').value;
    const { error } = await M.rpc('v2_meeting_item', {
      p_meeting: ui.openId, p_kind: kind, p_title: $('itemTitle').value.trim() || null,
      p_student: kind === 'طالب' ? $('itemStu').value : null, p_record: null, p_opp: null,
    }, 'بند في جدول الأعمال');
    if (error) { toast('لم يُضَف البند:\n' + errText(error)); return; }
    toast('أُضيف البند.', true);
    await loadMeetings();
  }

  async function vote(it, v) {
    let note = null;
    if (v === 'مخالف') {
      note = await reason('مخالفة القرار', it.title || '', 'رأيك المخالف — يُثبت في المحضر');
      if (note == null) return;
    }
    const { error } = await M.rpc('v2_meeting_vote', { p_item: it.id, p_vote: v, p_note: note }, 'تصويت');
    if (error) { toast('لم يُسجَّل صوتك:\n' + errText(error)); return; }
    toast('سُجّل صوتك: ' + v, true);
    await loadMeetings();
  }

  async function closeItem(it) {
    $('closeWhat').textContent = it.title || '';
    for (const id of ['closeBody', 'closeDecision', 'closeRec', 'closeDue']) $(id).value = '';
    const sel = $('closeOwner');
    sel.textContent = '';
    const none = document.createElement('option');
    none.value = '';
    none.textContent = '—';
    sel.appendChild(none);
    for (const p of (await staff()) || []) {
      const o = document.createElement('option');
      o.value = p.person_id;
      o.textContent = p.name_ar;
      sel.appendChild(o);
    }
    $('closeOk').disabled = true;
    if (await ask($('closeDlg')) !== 'ok') return;
    const { data, error } = await M.rpc('v2_meeting_close_item', {
      p_item: it.id, p_body: $('closeBody').value.trim(), p_decision: $('closeDecision').value.trim(),
      p_recommend: $('closeRec').value.trim() || null, p_owner: sel.value || null, p_due: $('closeDue').value || null,
    }, 'قفل البند');
    if (error) { toast('لم يُقفل البند:\n' + errText(error)); return; }
    toast('قُفل البند: ' + ((data && data.outcome) || ''), true);
    await loadMeetings();
  }

  async function minute() {
    $('minuteEnd').value = '';
    if (await ask($('minuteDlg')) !== 'ok') return;
    const { error } = await M.rpc('v2_meeting_minute', { p_meeting: ui.openId, p_ended: $('minuteEnd').value || null }, 'توثيق المحضر');
    if (error) { toast('لم يُوثَّق:\n' + errText(error)); return; }
    toast('وُثّق المحضر.', true);
    await loadMeetings();
  }

  async function approve() {
    const { error } = await M.rpc('v2_meeting_approve', { p_meeting: ui.openId }, 'اعتماد المحضر');
    if (error) { toast('لم يُعتمد:\n' + errText(error)); return; }
    toast('اعتُمد المحضر.', true);
    await loadMeetings();
  }

  // ٤ · المحاضر — الموثّق والمعتمد، للقراءة
  function renderMinutes() {
    const box = $('t_minutes');
    box.textContent = '';
    const done = ui.meetings.filter((m) => m.status === 'موثّق' || m.status === 'معتمد');
    if (ui.minutesOpen && ui.openId && ui.card && done.some((m) => m.id === ui.openId)) {
      box.appendChild(btn('btn-ghost wide', '← المحاضر كلّها', () => { ui.minutesOpen = false; renderAll(); }));
      cardView(box, false);
      return;
    }
    if (!done.length) { box.appendChild(el('div', 'empty', 'لا محاضر موثّقة بعد.')); return; }
    for (const m of done) box.appendChild(meetingRow(m, () => openMeeting(m.id, 'minutes')));
  }

  // ---------- الأحداث ----------
  for (const b of document.querySelectorAll('#tabs button')) {
    b.addEventListener('click', () => { ui.tab = b.dataset.tab; ui.minutesOpen = false; renderAll(); });
  }
  $('committee').addEventListener('change', () => {
    ui.key = $('committee').value;
    ui.openId = null;
    ui.card = null;
    loadBoard();
  });
  $('reasonText').addEventListener('input', () => { $('reasonOk').disabled = $('reasonText').value.trim() === ''; });
  $('callAgenda').addEventListener('input', () => { $('callOk').disabled = $('callAgenda').value.trim() === ''; });
  const closeReady = () => { $('closeOk').disabled = !$('closeBody').value.trim() || !$('closeDecision').value.trim(); };
  $('closeBody').addEventListener('input', closeReady);
  $('closeDecision').addEventListener('input', closeReady);
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  // ---------- الدخول ----------
  async function enter() {
    let me;
    try { await M.defaultRole(); me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    ui.me = me;
    M.state.me = me;
    M.renderHeader(me, async (r) => { const m = await M.actAs(r); if (m) { ui.staff = null; ui.students = null; enter(); } });
    M.renderNav(me, 'committees');
    if (!me) { M.gate('حسابك غير مسند إلى منسوب في مؤيّد.'); return; }
    const cur = (me.roles || []).find((r) => r.is_current === true && r.school_id);
    const schools = (me.schools || []).filter((x) => !cur || x.id === cur.school_id);
    if (!schools.length) { M.gate('لا مدرسة مسندة لحسابك.'); return; }
    ui.school = schools[0].id;
    // أسماء اللجان من القاعدة
    const res = await Promise.all(KEYS.map((k) => M.rpc('v2_committee_board', { p_school: ui.school, p_committee: k }, 'أسماء اللجان')));
    const sel = $('committee');
    sel.textContent = '';
    res.forEach((r, i) => {
      const o = document.createElement('option');
      o.value = KEYS[i];
      o.textContent = (r.data && r.data.committee && r.data.committee.label) || KEYS[i];
      ui.labels[KEYS[i]] = o.textContent;
      sel.appendChild(o);
    });
    sel.value = ui.key;
    $('cView').hidden = false;
    await loadBoard();
  }

  (async () => {
    const { data } = await M.sb.auth.getSession();
    if (!data.session) { location.replace('./'); return; }
    await enter();
  })();
})();
