// مؤيّد · اليومُ الدراسيّ في لوحة التحكّم — بابان على نموذج المحاكي:
// ① «فترات اليوم (الفسحة والصلاة)»: v2_breaks · v2_break_save · v2_break_remove
// ② «لوحة اليوم» مع باب «اليوم الدراسي»: v2_day_plan (اليومُ متّصلًا وخللُه في issues) · v2_day_build (أربعةُ أرقامٍ ⇐ معاينة ⇐ «أقرّ»)
// لا حسابَ هنا: الأوقاتُ والمددُ والخللُ كلُّها من القاعدة، والتداخلُ تحرسه القاعدة.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));
  const KINDS = ['فسحة', 'صلاة', 'اصطفاف', 'انصراف', 'أخرى'].map((k) => [k, k]);
  const hm = (t) => (t ? String(t).slice(0, 5) : null);

  // ================= ① فتراتُ اليوم =================
  async function breaksTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ جلب الفترات…'));
    const { data, error } = await M.rpc('v2_breaks', { p_school: school() }, 'فترات اليوم');
    box.textContent = '';
    if (error) { errBox(box, error); return; }
    const list = data || [];
    if (!list.length) box.appendChild(el('p', 'rs-empty', 'لا فتراتَ مضبوطة.'));
    for (const b of list) {
      const f = el('div', 'rs-file');
      const hd = el('div', 'rs-hd');
      hd.append(el('h5', null, b.label + ' · ' + b.kind), el('span', 'rs-who', b.starts_ar + ' — ' + b.ends_ar));
      f.appendChild(hd);
      f.appendChild(el('p', null, [b.minutes_ar + ' دقيقة', b.after_period_ar, b.needs_duty ? 'تحتاج مناوبة' + (b.min_staff ? ' (' + b.min_staff + ' فأكثر)' : '') : 'بلا مناوبة', 'المناوبون الآن ' + (b.duty_now || 0), b.note].filter(Boolean).join(' · ')));
      const row = el('div', 'rs-row');
      row.append(btn('عدّل', 'rs-btn soft', () => breakForm(box, b)), btn('ألغِها بسبب', 'rs-btn ghost', () => removeForm(box, b)));
      f.appendChild(row);
      box.appendChild(f);
    }
    box.appendChild(btn('أضف فترة', 'rs-btn', () => breakForm(box, null)));
    arabize(box);
  }

  function breakForm(box, b) {
    V.form({
      title: b ? 'فترةُ ' + b.label : 'فترةٌ جديدة',
      what: 'لا تتداخل فترةٌ مع حصّةٍ ولا مع فترة — والقاعدةُ تحرس ذلك.',
      fields: [
        { key: 'kind', type: 'pick', label: 'النوع', items: KINDS, value: b ? b.kind : 'فسحة' },
        { key: 'label', label: 'الاسم', value: b ? b.label : null },
        { key: 'starts', type: 'time', label: 'من', value: b ? hm(b.starts) : null },
        { key: 'ends', type: 'time', label: 'إلى', value: b ? hm(b.ends) : null },
        { key: 'after', type: 'number', label: 'بعد الحصّة (اختياريّ)', value: b ? b.after_period : null },
        { key: 'duty', type: 'pick', label: 'المناوبة', items: [['yes', 'تحتاج مناوبة'], ['no', 'بلا مناوبة']], value: b && b.needs_duty === false ? 'no' : 'yes' },
        { key: 'staff', type: 'number', label: 'أقلُّ عددٍ للمناوبين (اختياريّ)', value: b ? b.min_staff : null },
        { key: 'note', label: 'ملاحظة (اختياريّة)', value: b ? b.note : null },
      ],
      ok: 'احفظ',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_break_save', {
          p_school: school(), p_break: b ? b.id : null, p_kind: v.kind, p_label: v.label, p_starts: v.starts, p_ends: v.ends,
          p_after: v.after, p_needs_duty: v.duty === 'yes', p_min_staff: v.staff, p_note: v.note,
        }, 'حفظ فترة');
        if (error) return error;
        flash('ok', ((data && data.mode) || 'حُفظت') + ' الفترة');
        breaksTool(box);
        return null;
      },
    });
  }

  function removeForm(box, b) {
    V.form({
      title: 'إلغاءُ فترة ' + b.label, what: b.starts_ar + ' — ' + b.ends_ar,
      fields: [{ key: 'why', type: 'textarea', label: 'السبب', rows: 2 }],
      ok: 'ألغِها',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_break_remove', { p_school: school(), p_break: b.id, p_why: v.why }, 'إلغاء فترة');
        if (error) return error;
        flash('ok', 'أُلغيت الفترة — وبقيت محفوظةً بسببها');
        breaksTool(box);
        return null;
      },
    });
  }

  // ================= ② لوحةُ اليوم =================
  function lineList(box, line) {
    const ul = el('ul', 'rs-acts');
    for (const x of line || []) {
      const li = el('li');
      li.append(el('i', 'rs-tick' + (x.kind === 'period' ? '' : ' ok'), x.kind === 'period' ? '○' : '◆'),
        el('span', null, x.label + (x.sub && x.sub !== x.label ? ' · ' + x.sub : '')),
        el('span', 'rs-who', (x.from || '') + ' — ' + (x.to || '') + (x.minutes_ar ? ' · ' + x.minutes_ar + ' د' : '')));
      ul.appendChild(li);
    }
    box.appendChild(ul);
  }

  async function dayPlanTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ جلب لوحة اليوم…'));
    const { data, error } = await M.rpc('v2_day_plan', { p_school: school() }, 'لوحة اليوم');
    box.textContent = '';
    if (error) { errBox(box, error); return; }
    const d = data || {};
    const st = d.settings || {};
    box.appendChild(el('p', 'rs-meta', ['الاصطفاف ' + (st.assembly_ar || '—'), 'الحصّةُ الأولى ' + (st.period1_ar || '—'), (st.periods_count_ar || '—') + ' حصص × ' + (st.period_minutes_ar || '—') + ' دقيقة',
      'الإقفال ' + (st.close_ar || '—'), 'حدُّ التأخّر ' + (st.late_cutoff_ar || '—'), d.day_length_ar ? 'طولُ اليوم ' + d.day_length_ar + ' دقيقة' : null].filter(Boolean).join(' · ')));
    // الخللُ كما رجع — ولا يُصلَح هنا
    if (d.ok) box.appendChild(el('div', 'rs-state-done', 'سلِم اليومُ من الخلل'));
    for (const i of d.issues || []) box.appendChild(el('div', 'rs-state-open', i.text));
    lineList(box, d.line);
    box.appendChild(btn('ابنِ اليوم من جديد', 'rs-btn soft', () => buildForm(box)));
    arabize(box);
  }

  // أربعةُ أرقام: الاصطفاف · مدّةُ الحصّة · عددُ الحصص · وفتراتٌ (فسحةٌ وصلاة) بدقائقها وموضعها
  function buildForm(box, prev) {
    const p = prev || {};
    V.form({
      title: 'ابنِ اليوم',
      what: 'يُعرض المقترحُ أوّلًا ولا يُثبَّت إلا بكتابة «أقرّ». ويضبط حدَّ التأخّر على نهاية الحصّة الثالثة.',
      fields: [
        { key: 'assembly', type: 'time', label: 'بدايةُ الاصطفاف', value: p.assembly || '06:45', hint: 'الاصطفافُ ربعُ ساعة، ثمّ تبدأ الحصّةُ الأولى — كما يبنيه v2_day_build' },
        { key: 'minutes', type: 'number', label: 'مدّةُ الحصّة (دقيقة)', value: p.minutes || 45 },
        { key: 'periods', type: 'number', label: 'عددُ الحصص', value: p.periods || 7 },
        { key: 'f_min', type: 'number', label: 'الفسحة (دقيقة)', value: p.f_min == null ? 20 : p.f_min },
        { key: 'f_after', type: 'number', label: 'الفسحةُ بعد الحصّة', value: p.f_after == null ? 3 : p.f_after },
        { key: 's_min', type: 'number', label: 'الصلاة (دقيقة)', value: p.s_min == null ? 15 : p.s_min },
        { key: 's_after', type: 'number', label: 'الصلاةُ بعد الحصّة', value: p.s_after == null ? 7 : p.s_after },
      ],
      ok: 'اعرض المقترح',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_day_build', buildArgs(v, null), 'معاينة اليوم');
        if (error) return error;
        setTimeout(() => previewForm(box, v, data || {}), 0);
        return null;
      },
    });
  }

  function buildArgs(v, apply) {
    const breaks = [];
    if (v.f_min) breaks.push({ kind: 'فسحة', label: 'الفسحة', minutes: v.f_min, after_period: v.f_after });
    if (v.s_min) breaks.push({ kind: 'صلاة', label: 'الصلاة', minutes: v.s_min, after_period: v.s_after });
    return { p_school: school(), p_assembly: v.assembly, p_period_minutes: v.minutes, p_periods: v.periods, p_breaks: breaks, p_apply: apply };
  }

  function previewForm(box, v, d) {
    V.form({
      title: 'المقترح', what: (d.note || '') + (d.ends_ar ? ' · ينتهي ' + d.ends_ar : '') + (d.cutoff_ar ? ' · حدُّ التأخّر ' + d.cutoff_ar : ''),
      fields: [{ key: 'confirm', label: 'اكتب: أقرّ', hint: 'يستبدل حصصَ اليوم وفتراتِه كلَّها — والجدولُ القائمُ لا يُمسّ فراجع حصصَه' }],
      ok: 'ثبّت اليوم',
      extra: [{ text: 'عدّل الأرقام', cls: 'rs-btn ghost', onClick: () => { setTimeout(() => buildForm(box, v), 0); return null; } }],
      onOk: async (x) => {
        const { data, error } = await M.rpc('v2_day_build', buildArgs(v, x.confirm), 'تثبيت اليوم');
        if (error) return error;
        if (!data || !data.applied) return { message: (data && data.note) || 'لم يُثبَّت — اكتب «أقرّ»' };
        flash('ok', data.note || 'ثُبّت اليوم');
        dayPlanTool(box);
        return null;
      },
    });
    // المعاينةُ خطٌّ متّصلٌ كما رجع
    const sh = document.querySelector('.rs-modal .sheet');
    if (sh) { const holder = el('div'); lineList(holder, d.plan); sh.insertBefore(holder, sh.querySelector('label')); arabize(holder); }
  }

  window.MoayadYawm = { breaksTool, dayPlanTool };
})();
