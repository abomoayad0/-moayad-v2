// مؤيّد · رصد اليوم — شاشة المساعد الإداري.
// الواجهة لا تحسب شيئاً: الأعداد والحالات والتاريخ الهجري كلها من دوالّ القاعدة
// (v2_my_schools · v2_day_summary · v2_day_list · v2_record_assembly).
(function () {
  'use strict';

  const cfg = window.MOAYAD_CONFIG;
  const sb = window.supabase.createClient(cfg.url, cfg.key);
  const $ = (id) => document.getElementById(id);

  // أسماء أنواع اليوم كما تُرجعها fn_day_kind
  const DAY_KIND_AR = {
    study: 'يوم دراسة', exam: 'يوم اختبار', holiday: 'إجازة',
    weekend: 'عطلة نهاية الأسبوع', suspended: 'دراسة معلّقة',
  };
  // أزرار المساعد الإداري — حالات الاصطفاف من قيد attendance.assembly_state
  const ACTIONS = [
    { state: 'attended', label: 'حاضر' },
    { state: 'not_arrived', label: 'غائب' },
    { state: 'missed_inside', label: 'تخلّف عن الاصطفاف', sub: 'وهو في المدرسة' },
  ];

  const ui = {
    school: null, date: null, summary: null, rows: [],
    filter: 'all', q: '', canRecord: false, busy: new Set(),
  };

  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* لا شيء */ } }
  function load(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }

  function localToday() {
    // تاريخ الجهاز بصيغة YYYY-MM-DD — يُرسل كما هو للقاعدة
    return new Date().toLocaleDateString('en-CA');
  }

  let toastTimer = null;
  function toast(msg) {
    const t = $('toast');
    t.textContent = msg;
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { t.hidden = true; }, 7000);
  }
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });

  function errText(error) {
    if (!error) return '';
    return [error.message, error.details, error.hint].filter(Boolean).join('\n');
  }

  // ---------- الدخول ----------
  async function boot() {
    const { data } = await sb.auth.getSession();
    if (data.session) await enter(data.session);
    else showLogin();
    sb.auth.onAuthStateChange((evt, session) => {
      if (evt === 'SIGNED_OUT') showLogin();
    });
  }

  function showLogin() {
    $('loginView').hidden = false;
    $('dayView').hidden = true;
    $('logout').hidden = true;
    $('who').textContent = '';
  }

  $('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    $('loginErr').hidden = true;
    $('loginBtn').disabled = true;
    const { data, error } = await sb.auth.signInWithPassword({
      email: $('email').value.trim(), password: $('password').value,
    });
    $('loginBtn').disabled = false;
    if (error) {
      $('loginErr').textContent = 'تعذّر الدخول: ' + errText(error);
      $('loginErr').hidden = false;
      return;
    }
    await enter(data.session);
  });

  $('logout').addEventListener('click', async () => { await sb.auth.signOut(); });

  async function enter(session) {
    $('loginView').hidden = true;
    $('dayView').hidden = false;
    $('logout').hidden = false;
    $('who').textContent = session.user.email || '';

    const { data, error } = await sb.rpc('v2_my_schools');
    const sel = $('school');
    sel.innerHTML = '';
    if (error) { showLoadErr('تعذّر جلب المدارس: ' + errText(error)); return; }
    if (!data || data.length === 0) {
      showLoadErr('لا مدرسة مسندة لحسابك. اطلب من مالك النظام إسنادك إلى مدرستك وصفتك.');
      return;
    }
    for (const s of data) {
      const o = document.createElement('option');
      o.value = s.id;
      o.textContent = s.name_ar + ' — ' + s.students_n + ' طالباً مقيّداً';
      sel.appendChild(o);
    }
    const saved = load('moayad.school');
    if (saved && data.some((s) => s.id === saved)) sel.value = saved;
    $('schoolBox').hidden = data.length === 1;
    ui.school = sel.value;
    $('date').value = ui.date || localToday();
    ui.date = $('date').value;
    await refresh();
  }

  $('school').addEventListener('change', () => {
    ui.school = $('school').value;
    store('moayad.school', ui.school);
    refresh();
  });
  $('date').addEventListener('change', () => {
    if (!$('date').value) return;
    ui.date = $('date').value;
    refresh();
  });

  // ---------- جلب اليوم ----------
  function showLoadErr(msg) {
    $('loadErr').textContent = msg;
    $('loadErr').hidden = !msg;
  }

  async function refresh() {
    if (!ui.school || !ui.date) return;
    showLoadErr('');
    const args = { p_school: ui.school, p_date: ui.date };
    const [sum, list] = await Promise.all([
      sb.rpc('v2_day_summary', args),
      sb.rpc('v2_day_list', args),
    ]);
    if (sum.error || list.error) {
      showLoadErr('تعذّر جلب اليوم: ' + errText(sum.error || list.error));
      return;
    }
    ui.summary = (sum.data && sum.data[0]) || null;
    ui.rows = list.data || [];
    render();
  }

  // ---------- العرض ----------
  function render() {
    const s = ui.summary;
    const dates = $('dates');
    dates.textContent = '';
    if (s) {
      const h = document.createElement('span');
      h.className = 'h';
      if (s.hijri) { h.append(ltr(s.hijri), ' هـ'); } else { h.textContent = 'التاريخ الهجري غير متاح'; }
      const g = document.createElement('span');
      g.className = 'g';
      g.append(' · ', ltr(ui.date), ' م');
      const k = document.createElement('span');
      k.className = 'kind';
      k.textContent = DAY_KIND_AR[s.day_kind] || s.day_kind;
      dates.append(h, g, k);
    }

    const isStudy = !!s && (s.day_kind === 'study' || s.day_kind === 'exam');
    const closed = !!s && s.closed;
    ui.canRecord = isStudy && !closed;

    $('noStudy').hidden = !s || isStudy;
    if (s && !isStudy) {
      $('noStudy').textContent = 'هذا اليوم ليس يوم دراسة (' + (DAY_KIND_AR[s.day_kind] || s.day_kind) + ') — لا يُرصد فيه حضور ولا غياب.';
    }
    $('closedNote').hidden = !closed;

    // من لم يُرصد — من القاعدة، بارز، ولا يُطوى
    const un = $('unrec');
    un.hidden = !s || !isStudy;
    if (s) {
      un.classList.toggle('zero', s.unrecorded === 0);
      $('unrecText').textContent = s.unrecorded === 0
        ? 'رُصد جميع المقيّدين (' + s.enrolled + ')'
        : s.unrecorded + ' طالباً لم يُرصد بعد — من ' + s.enrolled;
    }

    $('counts').hidden = !s;
    if (s) {
      $('cPresent').textContent = s.present;
      $('cAbsent').textContent = s.absent;
      $('cLate').textContent = s.late;
      $('cPermitted').textContent = s.permitted;
      $('cMissed').textContent = s.missed_assembly;
    }

    renderList();
  }

  function renderList() {
    const box = $('list');
    box.textContent = '';
    const q = ui.q.trim();
    const rows = ui.rows.filter((r) =>
      (ui.filter === 'all' || r.state === ui.filter) &&
      (!q || (r.full_name || '').includes(q) || (r.display_name || '').includes(q) || (r.student_no || '').includes(q)));

    if (rows.length === 0) {
      const e = document.createElement('div');
      e.className = 'empty';
      e.textContent = ui.rows.length === 0 ? 'لا طلاب مقيّدون في هذه المدرسة.' : 'لا أحد في هذا التصنيف.';
      box.appendChild(e);
      return;
    }

    let grp = null;
    for (const r of rows) {
      const g = r.grade + '/' + r.section;
      if (g !== grp) {
        grp = g;
        const h = document.createElement('h3');
        h.className = 'grp';
        h.textContent = 'الصف ' + r.grade + ' — الفصل ' + r.section;
        box.appendChild(h);
      }
      box.appendChild(card(r));
    }
  }

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

  function ltr(text) {
    const b = document.createElement('bdi');
    b.dir = 'ltr';
    b.textContent = text;
    return b;
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
      p_student: r.student_id, p_date: ui.date, p_state: state,
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
  $('showUnrec').addEventListener('click', () => setFilter('unrecorded'));
  $('q').addEventListener('input', () => { ui.q = $('q').value; renderList(); });

  boot();
})();
