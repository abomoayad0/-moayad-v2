// مؤيّد · التحصيلُ الدراسيّ — تكليفا ٣٤ و٣٥: شاشةٌ واحدةٌ بثلاثة أقسام، وكلٌّ يظهر لمن يفتحه بابُه
// ① ما يُنتظر منّي (للوكيل التعليميّ): v2_card_my_steps ⇒ v2_card_step_do — كصندوق المعلّم في الحصّة
// ② لوحةُ المتدنّين: v2_low_board(p_school, p_grade) — مرتّبةٌ كما جاءت (خطوات_بلا_تحسّن نازلًا) · «أُحيل» وسمٌ لا إخفاء · المعيار_ar أسفلَها
//    والإحالة: ihala.js · والإشعار: v2_low_notify_window ثمّ v2_low_notify_run — رماديٌّ خارجَ نافذته ومعه البيان، ولا يُخفى
// ③ تحليلُ نتائج الفترة: v2_term_analysis(p_school, p_term, p_period, p_grade) — نطاقي في الرأس · المواد جدولًا · المتعثّرون قائمةً وتشخيصُهم تحت الدرجة
// ولا عدّادَ يُركّب في الشاشة: الجملُ من الباب كما جاءت
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { $, el, errText, showLoadErr } = M;
  const { arabize, btn, flash } = V;

  const role = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };
  // من يفتح بابَ المتدنّين — كما في الباب نفسِه
  const LOW = ['principal', 'deputy', 'deputy_academic', 'deputy_students', 'deputy_school', 'deputy_school_students', 'deputy_academic_school', 'counselor'];
  // ومن يُرسل الإشعار — المديرُ والوكيل
  const NOTIFY = ['principal', 'deputy', 'deputy_academic', 'deputy_school', 'deputy_academic_school'];
  const STEPS = ['deputy_academic', 'deputy_academic_school'];
  const err = (box, e) => { box.textContent = ''; box.appendChild(el('div', 'notice err', errText(e))); };

  async function refresh() {
    if (!M.state.school) return;
    V.renderRole();
    showLoadErr('');
    const r = role();
    $('stepsCard').hidden = !STEPS.includes(r);
    $('lowCard').hidden = !LOW.includes(r);
    const jobs = [loadAnalysis()];
    if (STEPS.includes(r)) jobs.push(loadSteps());
    if (LOW.includes(r)) jobs.push(loadLow());
    await Promise.all(jobs);
  }

  // ---------- ① ما يُنتظر منّي ----------
  async function loadSteps() {
    const box = $('steps');
    const { data, error } = await M.rpc('v2_card_my_steps', { p_school: M.state.school }, 'ما يُنتظر منّي');
    if (error) { $('stepsSum').textContent = ''; err(box, error); return; }
    const d = data || {};
    $('stepsSum').textContent = d.summary_ar || '';
    box.textContent = '';
    for (const x of d.rows || []) {
      const f = el('div', 'rs-file' + (x.days_left < 0 ? ' rs-late' : ''));
      f.append(el('h5', null, (x.student_ar || '') + ' — ' + (x.title_ar || '')), el('p', 'rs-meta', x.state_ar || ''));
      const r = el('div', 'rs-row'); r.appendChild(btn('أنجزتُها', 'rs-btn', () => stepForm(x))); f.appendChild(r);
      box.appendChild(f);
    }
    if (d.note_ar) box.appendChild(el('p', 'rs-meta', d.note_ar));
    arabize($('stepsCard'));
  }
  function stepForm(x) {
    V.form({
      title: 'إنجازُ خطوة', what: (x.student_ar ? x.student_ar + ' — ' : '') + (x.title_ar || ''),
      fields: [{ key: 'n', type: 'textarea', label: 'ما فعلتَ', rows: 3 }],
      ok: 'أنجزتُها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_card_step_do', { p_step: x.step, p_note: v.n }, 'إنجاز خطوة');
        if (error) return error;
        flash('ok', (data && (data.note_ar || data.msg)) || ''); loadSteps(); return null;
      },
    });
  }

  // ---------- ② لوحةُ المتدنّين ----------
  async function loadLow() {
    const box = $('low');
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const notify = NOTIFY.includes(role());
    const [lb, win] = await Promise.all([
      M.rpc('v2_low_board', { p_school: M.state.school, p_grade: null }, 'لوحة المتدنّين'),
      notify ? M.rpc('v2_low_notify_window', { p_school: M.state.school }, 'نافذة إشعار وليّ الأمر') : Promise.resolve(null),
    ]);
    box.textContent = '';
    if (win) box.appendChild(notifyBox(win));
    if (lb.error) { box.appendChild(el('div', 'notice err', errText(lb.error))); arabize(box); return; }
    const d = lb.data || {};
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    const refer = window.MoayadIhala.can();
    // بالترتيب الذي جاء به الباب — خطوات_بلا_تحسّن نازلًا
    for (const s of d['الطلاب'] || []) {
      const f = el('div', 'rs-file' + (s['بلغ_المعيار'] ? ' rs-late' : ''));
      const h = el('h5', null, [s['الطالب'], s['الصفّ']].filter(Boolean).join(' · '));
      // من أُحيل يبقى في اللوحة بوسمه — فإحالتُه لا تُنهي المتابعة
      if (s['أُحيل']) h.appendChild(el('span', 'rs-tag own', 'أُحيل'));
      if (s['له_حالةٌ_مفتوحة']) h.appendChild(el('span', 'rs-tag', 'له حالةٌ مفتوحة'));
      f.appendChild(h);
      if (s['البيان']) f.appendChild(el('p', null, s['البيان']));
      if (s['أسماء_الموادّ']) f.appendChild(el('p', 'rs-meta', s['أسماء_الموادّ']));
      if (refer) {
        const r = el('div', 'rs-row');
        r.appendChild(window.MoayadIhala.button({ id: s['الطالب_id'], name: s['الطالب'] }, () => loadLow()));
        f.appendChild(r);
      }
      box.appendChild(f);
    }
    // المعيارُ واحدٌ للجميع — نصُّه كما جاء أسفلَ اللوحة
    if (d['المعيار_ar']) box.appendChild(el('p', 'rs-note', d['المعيار_ar']));
    arabize(box);
  }

  // زرُّ الإشعار: يُقرأ موعدُه أوّلًا — ومغلقُه رماديٌّ ومعه البيان، ولا يُخفى
  function notifyBox(win) {
    const f = el('div', 'rs-file');
    f.appendChild(el('h5', null, 'إشعارُ وليِّ الأمر بالتحصيل'));
    if (win.error) { f.appendChild(el('div', 'notice err', errText(win.error))); return f; }
    const w = win.data || {};
    const open = w['مفتوح'] === true;
    const b = btn('أرسِلِ الإشعار', 'rs-btn' + (open ? ' pri' : ''), () => notifyRun(w));
    b.disabled = !open;
    const r = el('div', 'rs-row'); r.appendChild(b);
    f.appendChild(r);
    if (w['البيان']) f.appendChild(el('p', open ? 'rs-meta' : 'rs-meta rs-grey', w['البيان']));
    return f;
  }
  function notifyRun(w) {
    V.form({
      title: 'إشعارُ وليِّ الأمر بالتحصيل', what: w['البيان'] || '',
      fields: [{ key: 'n', type: 'node', node: el('p', null, 'يُرسَلُ لوليِّ أمرِ كلِّ طالبٍ له مادّةٌ متدنّيةٌ فأكثر — ومن أُشعر في هذي النافذة لا يُشعَرُ ثانيةً.') }],
      ok: 'أرسِلْه',
      onOk: async () => {
        const { data, error } = await M.rpc('v2_low_notify_run', { p_school: M.state.school }, 'إشعار أولياء الأمور بالتحصيل');
        if (error) return error;
        const d = data || {};
        // البيانُ كما جاء — ثمّ سندُه
        flash('ok', [d['البيان'], d['سنده']].filter(Boolean).join(' — '));
        loadLow();
        return null;
      },
    });
  }

  // ---------- ③ تحليلُ نتائج الفترة ----------
  const COLS = [['المادّة', 'المادّة'], ['الصفّ', 'الصفّ'], ['عددهم', 'عددهم'], ['المتوسّط', 'المتوسّط'], ['أعلى', 'أعلى'], ['أدنى', 'أدنى'], ['ناجحون', 'ناجحون'], ['متعثّرون', 'متعثّرون'], ['نسبة_النجاح', 'نسبة النجاح']];
  async function loadAnalysis() {
    const box = $('ta');
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ الجلب…'));
    const { data, error } = await M.rpc('v2_term_analysis', { p_school: M.state.school, p_term: null, p_period: null, p_grade: null }, 'تحليل نتائج الفترة');
    box.textContent = '';
    if (error) { err(box, error); arabize(box); return; }
    const d = data || {};
    // نطاقي في الرأس: «موادّي أنا» أو «المدرسة كلّها»
    if (d['نطاقي']) box.appendChild(el('p', 'rs-big', d['نطاقي']));
    if (d['الفترة_ar']) box.appendChild(el('p', 'rs-meta', d['الفترة_ar']));
    // درجاتٌ لم تُرصد ⇒ التحليلُ ناقص — بلا_درجات_ar تحذيرًا في الرأس كما جاءت (null ⇒ لا سطر)
    if (d['بلا_درجات_ar']) box.appendChild(el('div', 'rs-need', d['بلا_درجات_ar']));
    if (d['البيان']) box.appendChild(el('p', 'rs-said', d['البيان']));
    const subs = d['المواد'] || [];
    if (subs.length) {
      const wrap = el('div', 'rs-tablewrap');
      const t = el('table', 'rs-table');
      const hr = el('tr');
      for (const [, label] of COLS) hr.appendChild(el('th', null, label));
      t.appendChild(hr);
      for (const s of subs) {
        const tr = el('tr');
        // الكسرُ بفاصلته العربيّة «٧١٫٥» — تحويلُ رقمٍ لا حساب
        for (const [k] of COLS) tr.appendChild(el('td', null, s[k] == null ? '—' : (typeof s[k] === 'number' ? String(s[k]).replace('.', '٫') : String(s[k]))));
        t.appendChild(tr);
        if (s['البيان']) { const tb = el('tr', 'rs-tblnote'); const td = el('td', null, s['البيان']); td.colSpan = COLS.length; tb.appendChild(td); t.appendChild(tb); }
      }
      wrap.appendChild(t);
      box.appendChild(wrap);
    }
    const low = d['المتعثّرون'] || [];
    if (low.length) {
      box.appendChild(el('div', 'rs-label', 'المتعثّرون'));
      for (const s of low) {
        const f = el('div', 'rs-file');
        const h = el('h5', null, [s['الطالب'], s['الصفّ'], s['المادّة']].filter(Boolean).join(' · '));
        // قصورُه ظاهرٌ قبل الاختبار ولم يُعالَج — وهو أولى من يُحال
        if (s['له_رصدات_تحصيليّة']) h.appendChild(el('span', 'rs-tag own', 'له رصداتٌ تحصيليّة'));
        f.appendChild(h);
        f.appendChild(el('p', null, [s['درجته'], 'من', s['من']].filter((x) => x != null).join(' ') + (s['نسبته'] != null ? ' (' + s['نسبته'] + '٪)' : '')));
        if (s['تشخيص']) f.appendChild(el('p', 'rs-meta', s['تشخيص']));
        box.appendChild(f);
      }
    }
    if (d['سنده']) box.appendChild(el('p', 'rs-note', d['سنده']));
    arabize(box);
  }

  M.start({ screen: 'tahsil', onChange: () => refresh() });
})();
