// مؤيّد · الوصول والانصراف — المناوب.
// الوصول المتأخر بوقته وقراره (ض٠٥)، وتأخر الانصراف (ض٠٣ وض٠٦).
// الدقائق والعتبات والإجراء كلها من القاعدة:
// v2_day_summary · v2_day_classes · v2_day_list · v2_record_arrival · v2_record_dismissal
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, el, toast, errText, showLoadErr } = M;

  const ui = { summary: null, classes: [], rows: [], tab: 'arr', disDone: [] };

  const DECISION_AR = { enter_class: 'دخل الفصل بإذن الموافقة', to_counselor: 'حُوّل إلى الموجّه الطلابي' };

  function nowHM() {
    // وقت الجهاز الآن — قيمة ابتدائية يعدّلها المناوب
    return new Date().toTimeString().slice(0, 5);
  }

  function ask(dlg) {
    return new Promise((resolve) => {
      dlg.addEventListener('close', () => resolve(dlg.returnValue), { once: true });
      dlg.returnValue = '';
      dlg.showModal();
    });
  }

  function classLabel(r) {
    const c = ui.classes.find((k) => k.grade === r.grade && k.section === r.section);
    return c ? c.label_ar : r.grade + ' — ' + r.section;
  }

  function matches(r, q) {
    q = q.trim();
    return !q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q);
  }

  // ---------- الجلب ----------
  async function refresh() {
    if (!M.state.school || !M.state.date) return;
    showLoadErr('');
    const args = { p_school: M.state.school, p_date: M.state.date };
    const [sum, cls, list] = await Promise.all([
      sb.rpc('v2_day_summary', args),
      sb.rpc('v2_day_classes', args),
      sb.rpc('v2_day_list', args),
    ]);
    const err = sum.error || cls.error || list.error;
    if (err) { showLoadErr('تعذّر جلب اليوم: ' + errText(err)); return; }
    ui.summary = (sum.data && sum.data[0]) || null;
    ui.classes = cls.data || [];
    ui.rows = list.data || [];
    render();
  }

  // ---------- العرض ----------
  function isStudy() {
    const s = ui.summary;
    return !!s && (s.day_kind === 'study' || s.day_kind === 'exam');
  }

  function render() {
    const s = ui.summary;
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, s.day_kind);
    else $('dates').textContent = '';
    $('noStudy').hidden = !s || isStudy();
    if (s && !isStudy()) {
      $('noStudy').textContent = 'هذا اليوم ليس يوم دراسة (' + (M.DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا يُسجَّل فيه وصول ولا انصراف.';
    }
    $('closedNote').hidden = !s || !s.closed;
    $('arrView').hidden = ui.tab !== 'arr';
    $('disView').hidden = ui.tab !== 'dis';
    renderArrivals();
    renderDismissals();
  }

  function studentCard(r, badgeCls, badgeText, lines, btnText, onClick, disabled) {
    const c = el('div', 'st s-' + r.state);
    const top = el('div', 'row1');
    const who = el('div');
    who.append(el('div', 'name', r.display_name || r.full_name), el('div', 'meta', r.student_no + ' · ' + classLabel(r)));
    top.append(who, el('span', 'badge ' + badgeCls, badgeText));
    c.appendChild(top);
    for (const t of lines) if (t) c.appendChild(el('div', 'detail', t));
    if (btnText) {
      const acts = el('div', 'acts one');
      const b = el('button', 'a-go', btnText);
      b.type = 'button';
      b.disabled = disabled;
      b.addEventListener('click', onClick);
      acts.appendChild(b);
      c.appendChild(acts);
    }
    return c;
  }

  function renderArrivals() {
    const q = $('qArr').value;
    const canArr = isStudy() && !ui.summary.closed && !!M.state.me.can.record_arrival;

    // من لم يصل بعد: غائب أو لم يُرصد — والحالة من القاعدة
    const wait = ui.rows.filter((r) => (r.state === 'absent' || r.state === 'unrecorded') && matches(r, q));
    $('waitTitle').textContent = 'لم يصل بعد (' + wait.length + ')';
    const wb = $('waitList');
    wb.textContent = '';
    if (wait.length === 0) wb.appendChild(el('div', 'empty', q ? 'لا أحد بهذا البحث.' : 'لا أحد ينتظر وصوله.'));
    for (const r of wait) {
      wb.appendChild(studentCard(r, 'b-' + r.state, r.state_ar, [r.assembly_ar],
        'وصل الآن', () => recordArrival(r), !canArr));
    }

    // من سُجّل وصوله متأخراً — بوقته ودقائقه وقراره كما في القاعدة
    const late = ui.rows.filter((r) => (r.has_permit || r.state === 'late') && matches(r, q));
    $('lateTitle').textContent = 'سُجّل وصولهم متأخرين (' + late.length + ')';
    const lb = $('lateList');
    lb.textContent = '';
    if (late.length === 0) lb.appendChild(el('div', 'empty', 'لم يُسجَّل وصول متأخر.'));
    for (const r of late) {
      const t = r.arrived_at ? 'وصل ' + r.arrived_at.slice(0, 5) +
        (r.minutes_late != null ? ' — متأخراً ' + r.minutes_late + ' دقيقة' : '') : '';
      lb.appendChild(studentCard(r, 'b-' + r.state, r.state_ar,
        [t, r.permit_decision ? (DECISION_AR[r.permit_decision] || r.permit_decision) : ''],
        'تعديل', () => recordArrival(r), !canArr));
    }
  }

  async function recordArrival(r) {
    $('arrWho').textContent = (r.display_name || r.full_name) + ' — ' + classLabel(r);
    $('arrTime').value = r.arrived_at ? r.arrived_at.slice(0, 5) : nowHM();
    const dec = r.permit_decision || 'enter_class';
    for (const x of document.querySelectorAll('input[name=arrDec]')) x.checked = x.value === dec;
    $('arrNote').value = '';
    if (await ask($('arrDlg')) !== 'ok') return;
    if (!$('arrTime').value) { toast('لم يُسجَّل: وقت الوصول مطلوب.'); return; }
    const decision = document.querySelector('input[name=arrDec]:checked').value;
    const { error } = await sb.rpc('v2_record_arrival', {
      p_student: r.student_id, p_date: M.state.date, p_arrived: $('arrTime').value,
      p_decision: decision, p_note: $('arrNote').value.trim() || null,
    });
    if (error) { toast('لم يُسجَّل وصول ' + (r.display_name || r.full_name) + ':\n' + errText(error)); return; }
    toast('سُجّل وصول ' + (r.display_name || r.full_name) + ' — ' + DECISION_AR[decision] + '.', true);
    await refresh();
  }

  function renderDismissals() {
    const q = $('qDis').value;
    const canDis = isStudy();
    const box = $('disList');
    box.textContent = '';
    if (!q.trim()) {
      box.appendChild(el('div', 'empty', 'ابحث عن الطالب الذي بقي بعد نهاية الدوام.'));
    } else {
      const found = ui.rows.filter((r) => matches(r, q));
      if (found.length === 0) box.appendChild(el('div', 'empty', 'لا أحد بهذا البحث.'));
      for (const r of found.slice(0, 20)) {
        box.appendChild(studentCard(r, 'b-' + r.state, r.state_ar, [], 'سجّل تأخر انصرافه', () => recordDismissal(r), !canDis));
      }
    }
    $('disDoneTitle').hidden = ui.disDone.length === 0;
    const done = $('disDone');
    done.textContent = '';
    for (const d of ui.disDone) {
      const c = el('div', 'ev' + (d.threshold.includes('30') ? ' act' : ''));
      c.append(el('div', 'name', d.name),
        el('div', 'detail', 'خرج ' + d.left + ' — بعد نهاية الدوام بـ' + d.minutes + ' دقيقة · ' + d.threshold),
        el('div', d.threshold.includes('30') ? 'need' : 'detail', d.action));
      done.appendChild(c);
    }
  }

  async function recordDismissal(r) {
    $('disWho').textContent = (r.display_name || r.full_name) + ' — ' + classLabel(r);
    $('disTime').value = nowHM();
    $('disReason').value = '';
    if (await ask($('disDlg')) !== 'ok') return;
    if (!$('disTime').value) { toast('لم يُرصد: وقت الخروج مطلوب.'); return; }
    const { data, error } = await sb.rpc('v2_record_dismissal', {
      p_student: r.student_id, p_date: M.state.date, p_left: $('disTime').value,
      p_reason: $('disReason').value.trim() || null,
    });
    if (error) { toast('لم يُرصد تأخر انصراف ' + (r.display_name || r.full_name) + ':\n' + errText(error)); return; }
    const x = (data && data[0]) || {};
    ui.disDone.unshift({
      name: r.display_name || r.full_name, left: $('disTime').value,
      minutes: x.minutes_after, threshold: x.threshold || '', action: x.action_taken || '',
    });
    toast('رُصد تأخر انصراف ' + (r.display_name || r.full_name) + ' — ' + (x.threshold || ''), true);
    $('qDis').value = '';
    renderDismissals();
  }

  // ---------- التبويبان والبحث ----------
  function setTab(t) {
    ui.tab = t;
    $('tabArr').setAttribute('aria-pressed', t === 'arr' ? 'true' : 'false');
    $('tabDis').setAttribute('aria-pressed', t === 'dis' ? 'true' : 'false');
    render();
  }
  $('tabArr').addEventListener('click', () => setTab('arr'));
  $('tabDis').addEventListener('click', () => setTab('dis'));
  $('qArr').addEventListener('input', renderArrivals);
  $('qDis').addEventListener('input', renderDismissals);

  M.start({
    screen: 'wusul',
    onChange: (why) => {
      ui.disDone = [];
      return refresh();
    },
  });
})();
