// مؤيّد · النماذجُ الرسميّة — على نموذج المحاكي.
// v2_forms_catalog(p_school): رقمُ النموذج وعنوانُه ومجموعتُه، وعددُ المفتوح والموقَّع — كلُّه من القاعدة.
// والنموذجُ يُفتح لطالبٍ بعينه (form.html?form=&student=)، والطلّابُ من v2_day_list كما في شاشة الوكيل.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn } = V;

  const ui = { forms: [], students: null, studentsSchool: null };

  async function refresh() {
    V.renderRole();
    showLoadErr('');
    const { data, error } = await M.rpc('v2_forms_catalog', { p_school: M.state.school }, 'النماذج الرسمية');
    if (error) { showLoadErr('تعذّر جلب النماذج: ' + errText(error)); ui.forms = []; } else ui.forms = data || [];
    render();
  }

  function render() {
    const box = $('groups');
    box.textContent = '';
    const groups = [];
    for (const f of ui.forms) { let g = groups.find((x) => x.name === f.group); if (!g) groups.push(g = { name: f.group, items: [] }); g.items.push(f); }
    if (!groups.length) box.appendChild(el('p', 'rs-empty', 'لا نماذج.'));
    for (const g of groups) {
      const c = el('section', 'rs-card');
      c.appendChild(el('h3', null, g.name + ' (' + g.items.length + ')'));
      for (const f of g.items) {
        const r = el('div', 'rs-file');
        const hd = el('div', 'rs-hd');
        hd.append(el('h5', null, (f.no_ar || f.no) + ' · ' + f.title), el('span', 'rs-who', 'مفتوح ' + (f.open || 0) + ' · موقَّع ' + (f.signed || 0)));
        r.appendChild(hd);
        if (M.state.me && M.state.me.can && M.state.me.can.fill_form) r.appendChild(btn('افتحه لطالب', 'rs-btn soft', () => openFor(f)));
        c.appendChild(r);
      }
      box.appendChild(c);
    }
    if (!(M.state.me && M.state.me.can && M.state.me.can.fill_form)) box.appendChild(el('p', 'rs-meta nocan', M.lacks('تعبئة النماذج الرسمية')));
    arabize(box);
  }

  async function openFor(f) {
    if (!ui.students || ui.studentsSchool !== M.state.school) {
      const today = new Date().toLocaleDateString('en-CA');
      const { data, error } = await M.rpc('v2_day_list', { p_school: M.state.school, p_date: today }, 'طلّاب المدرسة');
      if (error) { V.flash('bad', 'تعذّر جلب الطلّاب: ' + errText(error)); return; }
      ui.students = data || [];
      ui.studentsSchool = M.state.school;
    }
    V.form({
      title: 'النموذج ' + (f.no_ar || f.no) + ': ' + f.title,
      fields: [{ key: 'stu', type: 'choose', label: 'الطالب', items: ui.students.map((s) => [s.student_id, s.display_name || s.full_name, s.student_no || '']) }],
      ok: 'افتح النموذج',
      onOk: async (v) => {
        if (!v.stu) return { message: 'اختر الطالب' };
        location.href = 'form.html?form=' + f.no + '&student=' + encodeURIComponent(v.stu);
        return null;
      },
    });
  }

  M.start({ screen: 'namadhij', onChange: () => refresh() });
})();
