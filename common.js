// مؤيّد — ما تشترك فيه الشاشات: الهوية (v2_me)، والمدرسة، واليوم، والرسائل.
// الدخول من رابط واحد (index.html)، وكل شاشة تستدعي Moayad.start({ screen, onChange }).
// وما يظهر لكل مستخدم يُقرأ من can في v2_me وحدها — لا يُخمَّن من الصفة.
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

  // الشاشات المبنية، وما يفتح كلّاً منها من مفاتيح can
  const SCREENS = [
    { key: 'rasd', title: 'رصد اليوم', desc: 'حصر الغياب في سجل اليوم — فصلاً فصلاً',
      href: 'rasd.html', allow: (c) => !!c.record_assembly },
    { key: 'deputy', title: 'قرارات الوكيل', desc: 'الإقفال · إعادة الفتح · البتّ في الأعذار',
      href: 'deputy.html', allow: (c) => !!(c.close_day || c.reopen_day || c.decide_excuse) },
  ];

  const state = { school: null, date: null, me: null };

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

  // ---------- الهوية ----------
  async function loadMe() {
    const { data, error } = await sb.rpc('v2_me');
    if (error) throw error;
    return data || null;
  }

  function screensFor(me) {
    return me && me.can ? SCREENS.filter((x) => x.allow(me.can)) : [];
  }

  // الصفة في رأس الشاشة دائماً — من role_ar
  function renderHeader(me) {
    const who = $('who');
    who.textContent = '';
    if (!me) return;
    who.append(el('span', null, me.name || me.full_name || ''), ' · ');
    who.append(el('span', 'role', me.role_ar || 'بلا صفة'));
    const tm = (me.schools || []).filter((x) => x.test_mode);
    const t = $('testMode');
    t.hidden = tm.length === 0;
    t.textContent = 'وضع التجربة — ' + tm.map((x) => x.name).join(' · ') + ': ما يُرصد يُوسم تجريبياً ويُمحى بأمر.';
  }

  function gate(msg) {
    $('gateErr').textContent = msg;
    $('gateErr').hidden = !msg;
  }

  async function signOut() {
    await sb.auth.signOut();
    location.replace('./');
  }

  // ---------- شاشة ----------
  function start(opts) {
    const onChange = opts.onChange;
    const screen = SCREENS.find((x) => x.key === opts.screen);

    $('toast').addEventListener('click', () => { $('toast').hidden = true; });
    $('logout').addEventListener('click', signOut);

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
      if (!data.session) { location.replace('./'); return; }

      let me;
      try { me = await loadMe(); } catch (e) { gate('تعذّر جلب حسابك: ' + errText(e)); return; }
      state.me = me;
      renderHeader(me);
      if (!me) { gate('حسابك غير مسند إلى منسوب في مؤيّد. اطلب من مالك النظام إسنادك.'); return; }
      if (!screen || !screen.allow(me.can || {})) {
        gate('صفتك (' + (me.role_ar || 'بلا صفة') + ') لا تملك هذه الشاشة.');
        $('toMenu').hidden = false;
        return;
      }
      $('toMenu').hidden = screensFor(me).length < 2;

      const schools = me.schools || [];
      if (schools.length === 0) { gate('لا مدرسة مسندة لحسابك.'); return; }
      const sel = $('school');
      sel.innerHTML = '';
      for (const x of schools) {
        const o = document.createElement('option');
        o.value = x.id;
        o.textContent = x.name + ' — ' + x.students + ' طالباً مقيّداً';
        sel.appendChild(o);
      }
      const saved = load('moayad.school');
      if (saved && schools.some((x) => x.id === saved)) sel.value = saved;
      $('schoolBox').hidden = schools.length === 1;
      state.school = sel.value;
      $('date').value = localToday();
      state.date = $('date').value;
      $('dayView').hidden = false;
      await onChange('enter');
    })();
  }

  window.Moayad = {
    sb, $, state, SCREENS, DAY_KIND_AR, toast, errText, ltr, el, showLoadErr, renderDates,
    loadMe, screensFor, renderHeader, gate, signOut, start,
  };
})();
