// مؤيّد — الرابط الواحد: الدخول، ثم v2_me، ثم الشاشات من can وحدها.
// من له شاشة واحدة تُفتح له مباشرة، ومن له أكثر يختار من قائمة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { sb, $, el, errText } = M;

  function showLogin() {
    $('loginView').hidden = false;
    $('menuView').hidden = true;
    $('logout').hidden = true;
    M.renderHeader(null);
    $('testMode').hidden = true;
  }

  async function route() {
    $('loginView').hidden = true;
    $('menuView').hidden = false;
    $('logout').hidden = false;

    let me;
    try { me = await M.loadMe(); } catch (e) { M.gate('تعذّر جلب حسابك: ' + errText(e)); return; }
    M.renderHeader(me);
    if (!me) { M.gate('حسابك غير مسند إلى منسوب في مؤيّد. اطلب من مالك النظام إسنادك.'); return; }

    const screens = M.screensFor(me);
    if (screens.length === 1) { location.replace(screens[0].href); return; }

    renderAssignments(me);
    if (screens.length === 0) {
      M.gate('صفتك (' + (me.role_ar || 'بلا صفة') + ') لا تملك شاشة مبنية بعد.');
      return;
    }
    const box = $('menu');
    box.textContent = '';
    for (const x of screens) {
      const a = el('a', 'menu-item');
      a.href = x.href;
      a.append(el('b', null, x.title), el('span', null, x.desc));
      box.appendChild(a);
    }
    $('menuBox').hidden = false;
  }

  function renderAssignments(me) {
    const list = me.assignments || [];
    $('meBox').hidden = false;
    const box = $('assignments');
    box.textContent = '';
    box.appendChild(el('div', 'detail', 'الوظيفة في الملاك: ' + (me.post_ar || '—') + (me.major ? ' · ' + me.major : '')));
    box.appendChild(el('div', 'detail', 'الصلاحية الممنوحة: ' + (me.grant_ar || me.grant || '—')));
    if (list.length === 0) {
      box.appendChild(el('div', 'detail', 'لا تكليف نافذ — الصفة من الوظيفة في الملاك.'));
      return;
    }
    for (const a of list) {
      const d = el('div', 'detail');
      d.append(a.label + ' — ' + a.school + ' · منذ ', M.ltr(a.started_on), ' · خطاب ' + a.letter_no);
      box.appendChild(d);
    }
  }

  $('toast').addEventListener('click', () => { $('toast').hidden = true; });
  $('logout').addEventListener('click', M.signOut);

  $('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    $('loginErr').hidden = true;
    $('loginBtn').disabled = true;
    const { error } = await sb.auth.signInWithPassword({
      email: $('email').value.trim(), password: $('password').value,
    });
    $('loginBtn').disabled = false;
    if (error) {
      $('loginErr').textContent = 'تعذّر الدخول: ' + errText(error);
      $('loginErr').hidden = false;
      return;
    }
    await route();
  });

  (async () => {
    const { data } = await sb.auth.getSession();
    if (data.session) await route();
    else showLogin();
  })();
})();
