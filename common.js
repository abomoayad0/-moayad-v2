// مؤيّد — ما تشترك فيه الشاشات: الدخول، والمدرسة، واليوم، والرسائل.
// كل شاشة تستدعي Moayad.start({ onChange }) وتجلب ما يخصّها من الجسور.
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

  const state = { school: null, date: null };

  function store(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* لا شيء */ } }
  function load(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }

  function localToday() {
    // تاريخ الجهاز بصيغة YYYY-MM-DD — يُرسل كما هو للقاعدة
    return new Date().toLocaleDateString('en-CA');
  }

  let toastTimer = null;
  function toast(msg, ok) {
    const t = $('toast');
    t.textContent = msg;
    t.classList.toggle('ok', !!ok);
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { t.hidden = true; }, 7000);
  }

  function errText(error) {
    if (!error) return '';
    return [error.message, error.details, error.hint].filter(Boolean).join('\n');
  }

  function ltr(text) {
    const b = document.createElement('bdi');
    b.dir = 'ltr';
    b.textContent = text;
    return b;
  }

  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function showLoadErr(msg) {
    $('loadErr').textContent = msg;
    $('loadErr').hidden = !msg;
  }

  // التاريخ: الهجري أولاً (من القاعدة) ثم الميلادي، ونوع اليوم
  function renderDates(box, hijri, date, dayKind) {
    box.textContent = '';
    const h = el('span', 'h');
    if (hijri) h.append(ltr(hijri), ' هـ'); else h.textContent = 'التاريخ الهجري غير متاح';
    const g = el('span', 'g');
    g.append(' · ', ltr(date), ' م');
    box.append(h, g);
    if (dayKind) box.append(el('span', 'kind', DAY_KIND_AR[dayKind] || dayKind));
  }

  function start(opts) {
    const onChange = opts.onChange;

    function showLogin() {
      $('loginView').hidden = false;
      $('dayView').hidden = true;
      $('logout').hidden = true;
      $('who').textContent = '';
    }

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
      state.school = sel.value;
      $('date').value = state.date || localToday();
      state.date = $('date').value;
      await onChange('enter');
    }

    $('toast').addEventListener('click', () => { $('toast').hidden = true; });

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

    $('school').addEventListener('change', () => {
      state.school = $('school').value;
      store('moayad.school', state.school);
      onChange('school');
    });
    $('date').addEventListener('change', () => {
      if (!$('date').value) return;
      state.date = $('date').value;
      onChange('date');
    });

    (async () => {
      const { data } = await sb.auth.getSession();
      if (data.session) await enter(data.session);
      else showLogin();
      sb.auth.onAuthStateChange((evt) => { if (evt === 'SIGNED_OUT') showLogin(); });
    })();
  }

  window.Moayad = {
    sb, $, state, DAY_KIND_AR, toast, errText, ltr, el, showLoadErr, renderDates, start,
  };
})();
