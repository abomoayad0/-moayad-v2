// مؤيّد · صفحةُ المعلّم (تكليف ⑤) — بيتٌ واحدٌ بستّة أقسامٍ وشريطِ «صفتي»
// الأقسام: صفّي · توزيعُ المنهج · يومي في المدرسة · ما كُلِّفتُ به · ما وصلني · ما يُقاس بي
// والظهورُ بالتكليف لا بالصلاحية: قسمُ التوزيع لمن صفتُه النافذةُ معلّمُ موادّ أو تربيةٍ خاصّة أو موهوبين
// ① المبنيُّ في هذا الإيداع: قسمُ «توزيع المنهج» — «أسابيعي» (v2_plan_weeks) وحدَها؛ والبقيّةُ تنتظر بابَ المدخل:
//    فأبوابُ التوزيع كلُّها تطلب رقمَ الصفّ (p_grade) ولا بابَ يُعطي المعلّمَ صفوفَه ومادّاتِه به — ثغرةٌ مرفوعة
// ② «صفّي» و«يومي» و«ما كُلِّفتُ به» و«ما وصلني» قائمةٌ اليومَ في شاشتَي «الحصّة» و«ما عليّ» — وتُنقل إلى هنا بترتيب مفرح
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn } = V;

  const TEACHING = ['subject_teacher', 'sped_teacher', 'gifted_teacher'];
  const ui = { sec: 'plan' };
  const role = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };

  const SECTIONS = [
    ['mine', 'صفّي'], ['plan', 'توزيعُ المنهج'], ['day', 'يومي في المدرسة'],
    ['tasks', 'ما كُلِّفتُ به'], ['inbox', 'ما وصلني'], ['measured', 'ما يُقاس بي'],
  ];

  async function refresh() {
    if (!M.state.school) return;
    showLoadErr('');
    V.renderRole();
    // بالتكليف: قسمُ التوزيع لمن يُدرّس وحدَه
    const list = SECTIONS.filter(([k]) => k !== 'plan' || TEACHING.includes(role()));
    if (!list.some(([k]) => k === ui.sec)) ui.sec = list[0][0];
    V.pick($('sections'), list, ui.sec, (v) => { ui.sec = v; render(); });
    render();
  }

  function render() {
    const box = $('sectionBody'); box.textContent = '';
    ({ mine: secLink('hissa.html', 'افتح «الحصّة»'), plan: secPlan, day: secLink('mukallaf.html', 'افتح «ما عليّ»'),
      tasks: secLink('mukallaf.html', 'افتح «ما عليّ»'), inbox: secLink('mukallaf.html', 'افتح «ما عليّ»'), measured: secMeasured }[ui.sec])(box);
  }
  // الأقسامُ القائمةُ في شاشتَين — تُفتح منهما حتى تُنقل
  const secLink = (href, label) => (box) => {
    const c = el('section', 'rs-card');
    c.appendChild(el('p', 'rs-meta', 'هذا القسمُ قائمٌ اليومَ في شاشةٍ مستقلّة، ويُنقل إلى هذي الصفحة بترتيب العمل.'));
    const r = el('div', 'rs-row'); r.appendChild(btn(label, 'rs-btn', () => { location.href = href; })); c.appendChild(r);
    box.appendChild(c);
  };
  function secMeasured(box) {
    const c = el('section', 'rs-card');
    c.appendChild(el('p', 'rs-meta', 'لم يُبنَ هذا القسم: ملفُّ الأداء وشواهدُه والأداءُ الوظيفيُّ لا أبوابَ لها بعد.'));
    box.appendChild(c);
  }

  // ---------- توزيعُ المنهج ----------
  async function secPlan(box) {
    const c = el('section', 'rs-card');
    c.appendChild(el('h3', null, 'أسابيعي في هذا العام'));
    const sum = el('p', 'rs-sum'); const body = el('div');
    c.append(sum, body);
    box.appendChild(c);
    // مدخلُ التوزيع كلِّه: الأسابيعُ بلا أسابيع الاختبار، وأيّامُ الدراسة بعد خصم الإجازات
    const { data, error } = await M.rpc('v2_plan_weeks', { p_school: M.state.school, p_term: null }, 'أسابيع التوزيع');
    if (error) { body.appendChild(el('div', 'notice err', errText(error))); return; }
    const d = data || {};
    sum.textContent = d.summary_ar || '';
    const ul = el('ul', 'rs-acts');
    for (const w of d.weeks || []) {
      const li = el('li', w.is_current ? 'on' : null);
      const b = el('span'); b.style.flex = '1';
      b.appendChild(el('b', null, (w.from_h || '') + ' — ' + (w.to_h || '')));
      const hol = (w.holidays || []).join(' · ');
      if (hol) b.appendChild(el('div', 'rs-meta', hol));
      li.append(el('i', 'rs-tick' + (w.is_current ? ' ok' : ''), w.is_current ? '●' : '○'), b);
      ul.appendChild(li);
    }
    body.appendChild(ul);
    if (d.note_ar) body.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize(c);
  }

  M.start({ screen: 'muallim', onChange: () => refresh() });
})();
