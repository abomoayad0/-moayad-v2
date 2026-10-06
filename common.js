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
    { key: 'wusul', title: 'الوصول والانصراف', desc: 'الوصول المتأخر بقراره · تأخر الانصراف',
      href: 'wusul.html', allow: (c) => !!(c.record_arrival || c.record_dismissal) },
    { key: 'deputy', title: 'قرارات الوكيل', desc: 'الإقفال · إعادة الفتح · البتّ في الأعذار',
      href: 'deputy.html', allow: (c) => !!(c.close_day || c.reopen_day || c.decide_excuse) },
    // شاشةُ الوكيل (viewW) — حلّت محلّ «رصد المخالفات» القديمة
    { key: 'wakeel', title: 'شاشة الوكيل', desc: 'الرصد · الشواهد · النموذج ٥ · ملفّات الطالب · سجلّ الملفّ',
      href: 'wakeel.html', allow: (c) => !!c.record_behavior },
    { key: 'errors', title: 'لوحة الأخطاء', desc: 'ما سجّلته الشاشات والجسور — الأعطاب والحرّاس',
      href: 'errors.html', allow: (c) => !!c.view_errors },
    // ولا مفتاحَ للتعويض في can بعد — فتظهر حين يُضاف merit، والقاعدةُ تحرس كلّ فعل
    { key: 'merit', title: 'التعويض والتميّز', desc: 'بنك الفرص · الإقرار · التقدير',
      href: 'merit.html', allow: (c) => !!c.merit },
    // شاشةُ الموجّه (viewM) — حلّت محلّ counsel، والقاعدةُ تحرس السرّ وراءها
    { key: 'muwajjih', title: 'شاشة الموجّه', desc: 'دوري · مؤشّر الحالات · دراسة الحالة والجلسات والتقرير · سجلّ الملفّ',
      href: 'muwajjih.html', allow: (c) => !!c.counsel },
    // والقاعدةُ تحرس كلّ فعلٍ في اللجان
    { key: 'committees', title: 'اللجان', desc: 'المجلس · الاجتماعات · المحاضر',
      href: 'committees.html', allow: (c) => !!c.committees },
    // والقاعدةُ تحرس الدخول إلى اللوحة
    { key: 'panel', title: 'لوحة التحكّم', desc: 'أبواب الإعداد — المقفلُ بسببه وسنده',
      href: 'panel.html', allow: (c) => !!c.manage_settings },
  ];

  const state = { school: null, date: null, me: null, screen: null };

  // ---------- كاشف الأخطاء ----------
  // كل خطأ يُعرض للمستخدم كما هو، ويُسجَّل معه عبر v2_log_error.
  // (وتسجيل الجسور لأخطائها يُنقض مع نقض الطلب، فالتسجيل من الشاشة هو الذي يبقى.)
  function logError(x) {
    try {
      sb.rpc('v2_log_error', { p: Object.assign({
        screen: state.screen, url: location.href, ua: navigator.userAgent, source: 'screen',
      }, x) }).then(() => {}, () => {});
    } catch (e) { /* لا يُكسر شيء بسبب التسجيل */ }
  }

  // استدعاء جسر: يُرجع { data, error } كما هو، ويُسجّل الفشل
  async function rpc(fn, args, action) {
    let res;
    try { res = await sb.rpc(fn, args); } catch (e) { res = { data: null, error: { message: String(e && e.message || e) } }; }
    if (res.error) {
      logError({
        message: res.error.message, fn, action: action || fn, params: args || null,
        sqlstate: res.error.code || null, detail: res.error.details || null, hint: res.error.hint || null,
        kind: res.error.code === 'P0001' ? 'guard' : 'error',
      });
    }
    return res;
  }

  window.addEventListener('error', (e) => {
    logError({ message: e.message || 'خطأ في الشاشة', action: 'js', params: { file: e.filename, line: e.lineno, col: e.colno }, kind: 'error' });
  });
  window.addEventListener('unhandledrejection', (e) => {
    const r = e.reason;
    logError({ message: String(r && r.message || r), action: 'js-promise', kind: 'error' });
  });

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

  // سبب غياب الزرّ: الصفة النافذة كما هي في الرأس — ولا اقتراح بتبديلها
  function lacks(what) {
    const r = state.me && state.me.role_ar;
    return 'بصفتك ' + (r ? '«' + r + '»' : 'الحالية') + ' لا تملك ' + what + '.';
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
    const { data, error } = await rpc('v2_me', undefined, 'جلب الحساب');
    if (error) throw error;
    return data || null;
  }

  // مرّة بعد الدخول وقبل v2_me: تُفرض صفة إن لم تكن مختارة، ولا يتغيّر شيء إن كانت
  async function defaultRole() {
    const { error } = await rpc('v2_default_role', undefined, 'فرض الصفة');
    if (error) throw error;
  }

  function screensFor(me) {
    return me && me.can ? SCREENS.filter((x) => x.allow(me.can)) : [];
  }

  // ---------- الرأس: الاسم والصفة ومبدّلها ----------
  // الصفة تحكم ما يملكه كلّه، والشاشات أدوات. فالمبدّل هنا غير شريط الشاشات.
  function roleLabel(r) {
    return r.role_ar + (r.school ? ' — ' + r.school : '') + ' · ' + r.source;
  }

  function renderHeader(me, onRole) {
    const who = $('who');
    who.textContent = '';
    if (!me) { $('testMode').hidden = true; return; }
    who.append(el('span', 'name', me.name || me.full_name || ''));

    const roles = me.roles || [];
    const box = el('div', 'rolebox');
    // الصفة نصّاً من role_ar دائماً — ولا تعتمد على ما يعرضه مربّع الاختيار في المتصفح
    const cur = roles.find((r) => r.is_current === true);
    box.append(el('span', 'role-l', 'تعمل بصفة:'),
      el('span', 'role', (me.role_ar || 'بلا صفة') + (cur && cur.school ? ' — ' + cur.school : '')));
    if (roles.length > 1 && onRole) {
      const sel = document.createElement('select');
      sel.id = 'roleSel';
      sel.className = 'rolesel';
      sel.setAttribute('aria-label', 'بدّل صفتك');
      const ph = document.createElement('option');
      ph.value = '';
      ph.textContent = 'بدّل الصفة';
      ph.selected = true;
      sel.appendChild(ph);
      roles.forEach((r, i) => {
        const o = document.createElement('option');
        o.value = String(i);
        o.textContent = (r.is_current === true ? '✓ ' : '') + roleLabel(r);
        sel.appendChild(o);
      });
      sel.addEventListener('change', () => {
        const r = roles[Number(sel.value)];
        sel.value = '';
        if (r && r.is_current !== true) onRole(r);
      });
      box.appendChild(sel);
    }
    who.appendChild(box);

    const tm = (me.schools || []).filter((x) => x.test_mode);
    const t = $('testMode');
    t.hidden = tm.length === 0;
    t.textContent = 'وضع التجربة — ' + tm.map((x) => x.name).join(' · ') + ': ما يُرصد يُوسم تجريبياً ويُمحى بأمر.';
  }

  // ---------- شريط الشاشات: من can وحدها ----------
  function renderNav(me, currentKey) {
    const nav = $('screens');
    nav.textContent = '';
    const list = screensFor(me);
    nav.hidden = list.length === 0;
    for (const x of list) {
      const a = el('a', 'nav-i' + (x.key === currentKey ? ' on' : ''), x.title);
      a.href = x.href;
      if (x.key === currentKey) a.setAttribute('aria-current', 'page');
      nav.appendChild(a);
    }
  }

  // تبديل الصفة: v2_act_as ثم v2_me من جديد — فـ can تتغيّر والشريط يُبنى من جديد
  async function actAs(r) {
    const { data, error } = await rpc('v2_act_as', { p_role: r.role_key, p_school: r.school_id || null }, 'تبديل الصفة');
    if (error) { toast('لم تُبدَّل الصفة:\n' + errText(error)); return null; }
    toast(data || 'بُدّلت الصفة.', true);
    return loadMe();
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
    state.screen = opts.screen;

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

    async function onRole(r) {
      let me;
      try { me = await actAs(r); } catch (e) { toast('تعذّر جلب حسابك: ' + errText(e)); return; }
      if (me) await apply(me, 'role');
      else renderHeader(state.me, onRole);
    }

    async function apply(me, why) {
      state.me = me;
      renderHeader(me, onRole);
      renderNav(me, screen && screen.key);
      if (!me) { gate('حسابك غير مسند إلى منسوب في مؤيّد. اطلب من مالك النظام إسنادك.'); return; }
      if (!screen || !screen.allow(me.can || {})) {
        // الصفة الجديدة لا تملك هذه الشاشة: إلى أول شاشة تملكها، وإلا فلا شيء
        const first = screensFor(me)[0];
        if (why === 'role' && first) { location.replace(first.href); return; }
        $('dayView').hidden = true;
        gate('صفتك (' + (me.role_ar || 'بلا صفة') + ') لا تملك هذه الشاشة.' +
          (first ? '' : ' ولا شاشة مبنية لها بعد.'));
        return;
      }
      gate('');

      // الصفة المختارة إن كانت لمدرسة بعينها فلا عمل إلا فيها — والقاعدة تمنع غيرها
      const curRole = (me.roles || []).find((r) => r.is_current === true && r.school_id);
      const schools = (me.schools || []).filter((x) => !curRole || x.id === curRole.school_id);
      if (schools.length === 0) { gate('لا مدرسة مسندة لحسابك.'); return; }
      const sel = $('school');
      const prev = state.school;
      sel.innerHTML = '';
      for (const x of schools) {
        const o = document.createElement('option');
        o.value = x.id;
        o.textContent = x.name + ' — ' + x.students + ' طالباً مقيّداً';
        sel.appendChild(o);
      }
      const saved = prev || load('moayad.school');
      if (saved && schools.some((x) => x.id === saved)) sel.value = saved;
      $('schoolBox').hidden = schools.length === 1;
      state.school = sel.value;
      if (!state.date) { $('date').value = localToday(); state.date = $('date').value; }
      $('dayView').hidden = false;
      await onChange(why);
    }

    (async () => {
      const { data } = await sb.auth.getSession();
      if (!data.session) { location.replace('./'); return; }
      let me;
      try { await defaultRole(); me = await loadMe(); } catch (e) { gate('تعذّر جلب حسابك: ' + errText(e)); return; }
      await apply(me, 'enter');
    })();
  }

  window.Moayad = {
    sb, rpc, logError, $, state, SCREENS, DAY_KIND_AR, toast, errText, ltr, el, showLoadErr, renderDates, lacks,
    loadMe, defaultRole, screensFor, renderHeader, renderNav, actAs, gate, signOut, start,
  };
})();
