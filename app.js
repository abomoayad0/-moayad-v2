// مؤيّد · رصد اليوم — شاشة المساعد الإداري.
// الواجهة لا تحسب شيئاً: الأعداد والحالات والتاريخ الهجري كلها من دوالّ القاعدة
// (v2_my_schools · v2_day_summary · v2_day_classes · v2_day_list · v2_record_assembly).
// والرصد بالفصل: يُختار الصف والفصل أولاً، و«الفصل مرصود» حكمه is_done من القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, toast, errText, showLoadErr } = M;

  // أزرار المساعد الإداري — حالات الاصطفاف من قيد attendance.assembly_state
  const ACTIONS = [
    { state: 'attended', label: 'حاضر' },
    { state: 'not_arrived', label: 'غائب' },
    { state: 'missed_inside', label: 'تخلّف عن الاصطفاف', sub: 'وهو في المدرسة' },
  ];

  const ui = {
    summary: null, classes: [], rows: [], cls: null,
    filter: 'all', q: '', canRecord: false, busy: new Set(),
  };

  // ---------- جلب اليوم ----------
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
    if (err) {
      showLoadErr('تعذّر جلب اليوم: ' + errText(err));
      return;
    }
    ui.summary = (sum.data && sum.data[0]) || null;
    ui.classes = cls.data || [];
    ui.rows = list.data || [];
    if (ui.cls && !currentClass()) ui.cls = null;
    render();
  }

  // ---------- العرض ----------
  function render() {
    const s = ui.summary;
    if (s) M.renderDates($('dates'), s.hijri, M.state.date, s.day_kind);
    else $('dates').textContent = '';

    const isStudy = !!s && (s.day_kind === 'study' || s.day_kind === 'exam');
    const closed = !!s && s.closed;
    ui.canRecord = isStudy && !closed;

    $('noStudy').hidden = !s || isStudy;
    if (s && !isStudy) {
      $('noStudy').textContent = 'هذا اليوم ليس يوم دراسة (' + (M.DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا يُرصد فيه حضور ولا غياب.';
    }
    $('closedNote').hidden = !closed;

    // الشريط الأعلى: كم فصلاً رُصد من كم — من is_done، بارز، ولا يُطوى
    const un = $('unrec');
    un.hidden = !s || !isStudy || ui.classes.length === 0;
    const done = ui.classes.filter((c) => c.is_done).length;
    const total = ui.classes.length;
    un.classList.toggle('zero', done === total);
    $('unrecText').textContent = done === total
      ? 'رُصدت الفصول كلها (' + total + ')'
      : 'رُصد ' + done + ' فصلاً من ' + total + ' — بقي ' + (total - done);

    renderClasses();
    renderClassView();
    renderList();
  }

  function renderList() {
    const box = $('list');
    box.textContent = '';
    const q = ui.q.trim();
    const c = currentClass();
    if (!c) return;
    const inClass = ui.rows.filter((r) => r.grade === c.grade && r.section === c.section);
    const rows = inClass.filter((r) =>
      (ui.filter === 'all' || r.state === ui.filter) &&
      (!q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q)));

    if (rows.length === 0) {
      const e = document.createElement('div');
      e.className = 'empty';
      e.textContent = inClass.length === 0 ? 'لا طلاب مقيّدون في هذا الفصل.' : 'لا أحد في هذا التصنيف.';
      box.appendChild(e);
      return;
    }

    for (const r of rows) box.appendChild(card(r));
  }

  // ---------- الفصول ----------
  function classKey(c) { return c.grade + '/' + c.section; }
  function currentClass() { return ui.classes.find((c) => classKey(c) === ui.cls) || null; }

  function renderClasses() {
    $('classPick').hidden = !!currentClass();
    const box = $('classes');
    box.textContent = '';
    if (ui.classes.length === 0) {
      const e = document.createElement('div');
      e.className = 'empty';
      e.textContent = 'لا فصول فيها طلاب مقيّدون.';
      box.appendChild(e);
      return;
    }
    for (const c of ui.classes) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'cls' + (c.is_done ? ' done' : '');
      const t = document.createElement('b');
      t.textContent = c.label_ar;
      const st = document.createElement('span');
      st.textContent = c.is_done ? '✓ رُصد كاملاً' : 'لم يُرصد ' + c.unrecorded + ' من ' + c.enrolled;
      const sm = document.createElement('small');
      sm.textContent = 'غائب ' + c.absent + ' · متأخر ' + c.late + ' · مستأذن ' + c.permitted;
      b.append(t, st, sm);
      b.addEventListener('click', () => openClass(classKey(c)));
      box.appendChild(b);
    }
  }

  function renderClassView() {
    const c = currentClass();
    $('classView').hidden = !c;
    if (!c) return;
    $('clsTitle').textContent = c.label_ar;
    const u = $('clsUnrec');
    u.classList.toggle('zero', c.is_done);
    u.textContent = c.is_done
      ? 'رُصد الفصل كاملاً (' + c.enrolled + ')'
      : c.unrecorded + ' طالباً لم يُرصد بعد في هذا الفصل — من ' + c.enrolled;
    $('cPresent').textContent = c.present;
    $('cAbsent').textContent = c.absent;
    $('cLate').textContent = c.late;
    $('cPermitted').textContent = c.permitted;
    $('cMissed').textContent = c.missed_assembly;
  }

  function openClass(key) {
    ui.cls = key;
    ui.q = '';
    $('q').value = '';
    setFilter('all');
    render();
    window.scrollTo(0, 0);
  }

  $('backToClasses').addEventListener('click', () => { ui.cls = null; render(); window.scrollTo(0, 0); });
  $('nextClass').addEventListener('click', () => {
    const c = ui.classes.find((x) => !x.is_done);
    if (c) openClass(classKey(c));
  });

  function card(r) {
    const c = document.createElement('div');
    c.className = 'st s-' + r.state + (ui.busy.has(r.student_id) ? ' busy' : '');

    const row1 = document.createElement('div');
    row1.className = 'row1';
    const who = document.createElement('div');
    const nm = document.createElement('div');
    nm.className = 'name';
    nm.textContent = r.display_name || r.full_name;
    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.textContent = r.student_no;
    who.append(nm, meta);
    const b = document.createElement('span');
    b.className = 'badge b-' + r.state;
    b.textContent = r.state_ar;
    row1.append(who, b);
    c.appendChild(row1);

    const bits = [];
    if (r.assembly_ar) bits.push(r.assembly_ar);
    if (r.arrived_at) bits.push('وصل ' + r.arrived_at.slice(0, 5) + (r.minutes_late != null ? ' — متأخر ' + r.minutes_late + ' دقيقة' : ''));
    if (r.has_permit) bits.push('إذن موافقة' + (r.permit_decision ? ' (' + permitAr(r.permit_decision) + ')' : ''));
    if (r.recorded_role) bits.push('رصده: ' + r.recorded_role);
    if (bits.length) {
      const d = document.createElement('div');
      d.className = 'detail';
      d.textContent = bits.join(' · ');
      c.appendChild(d);
    }

    const acts = document.createElement('div');
    acts.className = 'acts';
    for (const a of ACTIONS) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'a-' + a.state + (r.assembly_state === a.state ? ' on' : '');
      btn.textContent = a.label;
      if (a.sub) {
        const sm = document.createElement('small');
        sm.textContent = a.sub;
        btn.appendChild(sm);
      }
      btn.disabled = !ui.canRecord;
      btn.setAttribute('aria-pressed', r.assembly_state === a.state ? 'true' : 'false');
      btn.addEventListener('click', () => record(r, a.state));
      acts.appendChild(btn);
    }
    c.appendChild(acts);
    return c;
  }

  function permitAr(d) {
    if (d === 'enter_class') return 'دخول الفصل';
    if (d === 'to_counselor') return 'تحويل للموجّه';
    return d;
  }

  // ---------- الرصد ----------
  async function record(r, state) {
    if (ui.busy.has(r.student_id)) return;
    ui.busy.add(r.student_id);
    renderList();
    const { error } = await sb.rpc('v2_record_assembly', {
      p_student: r.student_id, p_date: M.state.date, p_state: state,
    });
    ui.busy.delete(r.student_id);
    if (error) {
      toast('لم يُرصد ' + (r.display_name || r.full_name) + ':\n' + errText(error));
      renderList();
      return;
    }
    await refresh();
  }

  // ---------- التصفية ----------
  $('filters').addEventListener('click', (e) => {
    const b = e.target.closest('button[data-f]');
    if (!b) return;
    setFilter(b.dataset.f);
  });
  function setFilter(f) {
    ui.filter = f;
    for (const x of $('filters').querySelectorAll('button')) {
      x.setAttribute('aria-pressed', x.dataset.f === f ? 'true' : 'false');
    }
    renderList();
  }
  $('q').addEventListener('input', () => { ui.q = $('q').value; renderList(); });

  M.start({
    onChange: (why) => {
      if (why === 'school') ui.cls = null;
      return refresh();
    },
  });
})();
