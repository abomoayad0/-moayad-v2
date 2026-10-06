// مؤيّد · ثوابتُ شاشات الأدوار السبع (المحاكي) — مشتركةٌ بينها كي لا تختلف شاشةٌ عن أختها.
// رأسُ الصفة · شريطُ النتيجة · الشرائط · الزرُّ المعطَّل بسببه · اللوحُ المنزلق · الأرقامُ العربيّة.
// لا حسابَ هنا ولا نصَّ حكمٍ: كلُّ ذلك من القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el } = M;

  // الأرقامُ عربيّةٌ في العرض — لما ترجعه القاعدةُ بأرقامٍ غربيّة (الرقم · التاريخ): تحويلُ أرقامٍ لا حساب
  const ar = (v) => String(v == null ? '' : v).replace(/[0-9]/g, (d) => '٠١٢٣٤٥٦٧٨٩'[d]);
  function arabize(node) {
    const w = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);
    for (let t = w.nextNode(); t; t = w.nextNode()) t.nodeValue = ar(t.nodeValue);
  }
  const btn = (text, cls, fn) => {
    const b = el('button', cls, text);
    b.type = 'button';
    if (fn) b.addEventListener('click', fn);
    return b;
  };
  // فعلٌ لم يُبنَ في المحرّك: زرٌّ معطَّلٌ ومعه سببُه
  const notBuilt = (text) => {
    const w = el('span', 'rs-off-act');
    const b = btn(text, 'rs-btn soft');
    b.disabled = true;
    w.append(b, el('small', null, 'لم يُبنَ بعد'));
    return w;
  };
  // بطاقةٌ لبندٍ لم يُبنَ: عنوانُه ثمّ «لم يُبنَ بعد»
  const offCard = (title, meta) => {
    const c = el('section', 'rs-card rs-off');
    c.appendChild(el('h3', null, title));
    if (meta) c.appendChild(el('p', 'rs-meta', meta));
    c.appendChild(el('div', 'rs-note', 'لم يُبنَ بعد — لا جسرَ له في القاعدة.'));
    return c;
  };

  // رأسُ الشاشة: الصفةُ من v2_me
  function renderRole() {
    const me = M.state.me || {};
    $('roleLine').hidden = !me.role_ar;
    $('roleText').textContent = '';
    $('roleText').append('تعمل بصفة ', el('b', null, me.role_ar || ''));
  }

  // شريطُ النتيجة: نصُّه من القاعدة، ويبقى حتى الفعل التالي
  function flash(kind, text, acts) {
    const f = $('flash');
    f.className = 'flash ' + kind;
    f.textContent = '';
    f.appendChild(el('span', null, text));
    if (acts && acts.length) {
      const row = el('span', 'rs-row');
      for (const a of acts) row.appendChild(a);
      f.appendChild(row);
    }
    f.hidden = false;
    arabize(f);
  }

  // شرائطُ الاختيار القصير (٢–٩): [[value, text]] ⇒ onPick(value)
  function pick(box, items, cur, onPick) {
    box.textContent = '';
    for (const [v, t] of items) {
      const s = el('span', v === cur ? 'on' : null, t);
      s.setAttribute('role', 'button');
      s.tabIndex = 0;
      s.setAttribute('aria-pressed', String(v === cur));
      const go = () => onPick(v);
      s.addEventListener('click', go);
      s.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); } });
      box.appendChild(s);
    }
  }

  // اللوحُ المنزلق من الأسفل — لما يحتاج حقولًا وحدَه
  function sheet(id) {
    const m = $(id);
    const close = () => { m.hidden = true; };
    m.addEventListener('click', (e) => { if (e.target === m) close(); });
    return { open: () => { m.hidden = false; }, close };
  }

  // سجلُّ أحداثٍ مطويّ — يُبنى في .rs-dtb
  function events(box, evs) {
    box.textContent = '';
    for (const e of evs) {
      const d = el('div');
      d.append(el('b', null, e.title || ''), document.createTextNode(' · ' + (e.on || '') + (e.body ? ' — ' + e.body : '')));
      box.appendChild(d);
    }
    if (!evs.length) box.appendChild(el('div', null, 'لا أحداثَ بعد.'));
    arabize(box);
  }

  window.MoayadView = { ar, arabize, btn, notBuilt, offCard, renderRole, flash, pick, sheet, events };
})();
