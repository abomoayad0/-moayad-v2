// مؤيّد · النموذج الرسمي للطبع — يُملأ من v2_form ولا يُؤلَّف منه حرف.
// form.html?form=8&student=<uuid>&ref=<record_id>
// وما لا تُرجعه القاعدة يبقى سطراً فارغاً يُكتب باليد، وخانات التوقيع فارغة.
(function () {
  'use strict';

  const M = window.Moayad;
  const { $, el, errText, showLoadErr } = M;
  M.state.screen = 'form';

  const STATUS_AR = { open: 'مفتوحة', done: 'نُفّذت', skipped: 'أُسقطت', auto: 'وقعت آلياً' };

  function blank() { return el('span', 'blank', '.................................'); }

  function kv(rows) {
    const t = el('table');
    for (const [k, v] of rows) {
      const tr = el('tr');
      const th = el('th', null, k);
      const td = el('td');
      if (v == null || v === '') td.appendChild(blank());
      else if (v instanceof Node) td.appendChild(v);
      else td.textContent = v;
      tr.append(th, td);
      t.appendChild(tr);
    }
    return t;
  }

  function render(f) {
    document.title = 'مؤيّد · ' + f.title_ar;
    $('barTitle').textContent = 'نموذج ' + f.form_no + ': ' + f.title_ar;
    const sh = $('sheet');
    sh.textContent = '';
    sh.appendChild(el('div', 'sch', f.school || ''));
    sh.appendChild(el('h1', null, f.title_ar));
    sh.appendChild(el('div', 'src', 'نموذج رقم ' + f.form_no + (f.source ? ' · ' + f.source : '')));

    // حقول النموذج الرسمي أزواجاً {label, value} بترتيبه — كما هي، والفارغ سطر منقّط
    if (Array.isArray(f.fields_kv) && f.fields_kv.length) {
      sh.appendChild(kv(f.fields_kv.map((x) => [x.label, x.value])));
    } else if (Array.isArray(f.fields) && f.fields.length) {
      sh.appendChild(kv(f.fields.map((n) => [n, null])));
    }

    // الطالب وأولياؤه
    const s = f.student || {};
    sh.appendChild(el('h2', null, 'بيانات الطالب'));
    const shown = new Set((f.fields_kv || []).map((x) => x.label).concat(f.fields || []));
    sh.appendChild(kv([['اسم الطالب', s.name], ['الصف', s.class_ar], ['رقم الطالب', s.student_no], ['رقم الهوية', s.national_id]]
      .filter(([k]) => !shown.has(k))));
    for (const g of f.guardians || []) {
      sh.appendChild(kv([[g.relation || 'ولي الأمر', g.name], ['الجوال', g.phone]]));
    }

    // الواقعة — للنماذج المبنية على رصد سلوكي
    const r = f.record;
    if (r) {
      sh.appendChild(el('h2', null, 'الواقعة'));
      sh.appendChild(kv([
        ['المشكلة', r.problem_ar],
        ['الدرجة', r.degree_no != null ? String(r.degree_no) : null],
        ['اليوم والتاريخ', (() => {
          const sp = document.createElement('span');
          sp.append([r.weekday_ar, r.occurred_h ? r.occurred_h + ' هـ' : null].filter(Boolean).join(' '));
          if (r.occurred_on) sp.append(' (', M.ltr(r.occurred_on), ' م)');
          return sp;
        })()],
        ['المكان', r.place],
        ['التكرار والخطوة', (r.occurrence_no != null ? 'التكرار ' + r.occurrence_no : '') + (r.step_no != null ? ' · الخطوة ' + r.step_no : '')],
        ['الدرجات المحسومة', r.deducted != null ? String(r.deducted) : null],
        ['ملاحظة', r.note],
      ]));
      if (Array.isArray(r.actions) && r.actions.length) {
        sh.appendChild(el('h2', null, 'الإجراءات'));
        const t = el('table', 'grid');
        const hr = el('tr');
        for (const h of ['م', 'الإجراء', 'المسؤول', 'الحالة', 'التاريخ']) hr.appendChild(el('th', null, h));
        t.appendChild(hr);
        r.actions.forEach((a, i) => {
          const tr = el('tr');
          tr.append(el('td', null, String(i + 1)), el('td', null, a.text), el('td', null, a.owner || ''),
            el('td', null, STATUS_AR[a.status] || a.status || ''), el('td', null, a.on_h ? a.on_h + ' هـ' : ''));
          t.appendChild(tr);
        });
        sh.appendChild(t);
      }
    }

    // المواظبة — للنماذج ١٥ و١٦ و١٧
    if (f.attendance) {
      sh.appendChild(el('h2', null, 'المواظبة'));
      sh.appendChild(kv(Object.entries(f.attendance).map(([k, v]) => [k.replace(/_/g, ' '), typeof v === 'boolean' ? (v ? 'نعم' : 'لا') : String(v)])));
    }

    // جدول النموذج كما طُبع — بصفوفه من القاعدة، وإلا سطور فارغة تُملأ باليد
    if (Array.isArray(f.columns) && f.columns.length) {
      const t = el('table', 'grid');
      const hr = el('tr');
      for (const h of f.columns) hr.appendChild(el('th', null, h));
      t.appendChild(hr);
      const rows = Array.isArray(f.days) && f.days.length ? f.days : [];
      for (const d of rows) {
        const tr = el('tr');
        for (const h of f.columns) tr.appendChild(el('td', null, d && d[h] != null ? String(d[h]) : ''));
        t.appendChild(tr);
      }
      for (let i = rows.length; i < Math.max(6, rows.length); i++) {
        const tr = el('tr');
        for (let j = 0; j < f.columns.length; j++) tr.appendChild(el('td'));
        t.appendChild(tr);
      }
      sh.appendChild(t);
    }

    // التاريخ والموقّعون — خانات فارغة تُوقَّع يدوياً
    const dt = el('div', 'dt');
    dt.append('حُرّر في ', M.ltr(f.today_h || ''), ' هـ (', M.ltr(f.today_g || ''), ' م)');
    sh.appendChild(dt);
    const signs = el('div', 'signs');
    for (const who of f.signers || []) {
      const d = el('div');
      d.append(el('div', 'line'), el('div', null, who), el('div', 'blank', 'الاسم والتوقيع'));
      signs.appendChild(d);
    }
    sh.appendChild(signs);
    sh.hidden = false;
  }

  $('printBtn').addEventListener('click', () => window.print());
  $('toast').addEventListener('click', () => { $('toast').hidden = true; });

  (async () => {
    const q = new URLSearchParams(location.search);
    const form = Number(q.get('form'));
    const student = q.get('student');
    const ref = q.get('ref') || null;
    if (!form || !student) { showLoadErr('رابط النموذج ناقص: يلزم رقم النموذج والطالب.'); return; }
    const { data: sess } = await M.sb.auth.getSession();
    if (!sess.session) { location.replace('./'); return; }
    const { data, error } = await M.rpc('v2_form', { p_form: form, p_student: student, p_ref: ref }, 'فتح نموذج ' + form);
    if (error) { showLoadErr('تعذّر فتح النموذج: ' + errText(error)); return; }
    if (!data) { showLoadErr('لم يُرجع النموذج شيئاً.'); return; }
    render(data);
  })();
})();
