// مؤيّد · بطاقةُ خطّة تعديل السلوك (نموذج ٣) — مشتركةٌ بين شاشة الوكيل وبطاقة الحالة في شاشة الموجّه (تكليف ⑯)
// «القائم بتعديل السلوك (معلم/معلمة — موجه طلابي/موجهة طلابية)» — ذيلُ ص٦١: فالموجّهُ أحدُ مالكَي النموذج، والأبوابُ تحرسه
// v2_plan_of · v2_plan_write · v2_plan_opinion · v2_plan_final · v2_plan_count
// لا يُمنع شيءٌ هنا: الحرّاسُ في الأبواب يرفضون بلفظهم · وما كتبه إنسانٌ بيده يُعرض حرفًا بحرف ([data-raw]: لا تُحوَّل أرقامُه)
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { btn, arabize } = V;

  const lines = (v) => (Array.isArray(v) ? v : String(v || '').split('\n')).filter((x) => String(x).trim() !== '');
  const raw = (n) => { n.setAttribute('data-raw', ''); return n; };
  const opinion = (text, at, cls, typed) => { const i = el('i', cls || null); i.appendChild(typed ? raw(el('span', null, text)) : el('span', null, text)); if (at) i.appendChild(el('div', 'rs-meta', at)); return i; };
  // عناوينُ الآراء الثلاثة من «سادسًا: تقييم فاعلية الخطة أو البرنامج» — ص٦١ بكلمتها
  const OPINIONS = { teacher: 'رأي معلم/معلمة الفصل', guardian: 'رأي ولي الأمر', deputy: 'رأي وكيل/وكيلة المدرسة' };

  // ctx: { result: ردُّ v2_plan_of · student: {student_id, name} · task: مهمّةُ الخطّة المفتوحة أو null · record · problem (لبنك العبارات) · reload() }
  function render(box, ctx) {
    box.textContent = '';
    const r = ctx.result || {};
    if (r.error) box.appendChild(el('div', 'notice err', errText(r.error)));
    const list = r.data || [];
    if (!list.length && !r.error) box.appendChild(el('p', 'rs-empty', 'لم تُكتب له خطّة.'));
    for (const p of list) {
      const f = el('div', 'rs-file');
      f.appendChild(raw(el('h5', null, (p.target || '—') + ' — ' + (p.state_ar || p.status || ''))));
      // القياسُ قبلُ وبعد (تكليف ⑭): جملتُه بارزة، وجدولُ القياس القبليّ فوقَ الخطّة، والمتابعةُ تحتَها
      const pm = p.measure ? V.planMeasure(p.measure) : null;
      if (pm) f.append(pm.said, pm.before);
      // التواريخُ بألفاظها من الباب في خاناتٍ لا في جملة — وعناوينُ ما سمّته الصفحةُ ٦٠–٦١ بكلمتها (تكليف ⑮) · و«اعتمدها» و«تاريخُ الاعتماد» من عملنا
      const dt = el('div', 'rs-lgd');
      for (const [k, v] of [['القائم بتعديل السلوك', p.by], ['تاريخ البداية', p.starts_ar], ['تاريخ النهاية', p.ends_ar], ['اعتمدها', p.final_at_ar ? p.final_by : null], ['تاريخُ الاعتماد', p.final_at_ar]]) if (v) dt.append(el('i', 'k', k + ':'), el('i', null, v));
      f.appendChild(dt);
      const lg = el('div', 'rs-lgd');
      for (const [k, v] of [['السلوك', p.desc], ['مظاهرُه', p.manifest], ['ما يسبقه', p.ante], ['ما يليه', p.conseq], ['ما يحقّقه منه', p.gain], ['ما سبق من إجراء', p.prior]]) if (v) lg.append(el('i', 'k', k + ':'), raw(el('i', null, v)));
      f.appendChild(lg);
      const st = lines(p.steps_list || p.steps);
      if (st.length) { f.appendChild(el('div', 'rs-label', 'إجراءاتُ التعديل')); const ul = raw(el('ul', 'rs-acts')); for (const x of st) ul.appendChild(el('li', null, '• ' + x)); f.appendChild(ul); }
      // الرأيُ تحت عنوانه من الصفحة، وتاريخُه تحته بلا عنوان (تكليف ⑮)
      const op = el('div', 'rs-lgd');
      op.append(el('i', 'k', OPINIONS.teacher + ':'), opinion(p.teacher || 'لم يُبدِه بعد', p.teacher_at_ar, p.needs_teacher ? 'rs-state-open' : null, !!p.teacher),
        el('i', 'k', OPINIONS.guardian + ':'), opinion(p.guardian || 'لم يُبدِه بعد', p.guardian_at_ar, null, !!p.guardian),
        el('i', 'k', OPINIONS.deputy + ':'), opinion(p.deputy || '—', null, null, !!p.deputy));
      f.appendChild(op);
      if (pm) {
        f.appendChild(pm.after);
        if (p.measure.measurable !== false) f.appendChild(btn('سجّل ملاحظة', 'rs-btn soft', () => countForm(box, ctx, p)));
      }
      if (p.status === 'draft') {
        const row = el('div', 'rs-row');
        row.append(btn('عدّلها', 'rs-btn soft', () => write(ctx, null, p)),
          btn(OPINIONS.teacher, 'rs-btn soft', () => opinionForm(ctx, p, 'teacher')),
          btn(OPINIONS.deputy, 'rs-btn soft', () => opinionForm(ctx, p, 'deputy')));
        if (p.can_final) row.appendChild(btn('اعتمدها', 'rs-btn', () => finalForm(ctx, p)));
        f.appendChild(row);
        if (!p.can_final && p.needs_teacher) f.appendChild(el('p', 'rs-meta', 'لا تُعتمد حتى يُبدي معلّمُ الفصل رأيَه.'));
      }
      box.appendChild(f);
    }
    if (!list.some((p) => p.status === 'draft')) box.appendChild(btn('اكتب خطّة', 'rs-btn', () => write(ctx, ctx.task || null, null)));
    arabize(box);
  }

  // تسجيلُ ملاحظةٍ في أحد جدولَي القياس: v2_plan_count — ثمّ تُحدَّث البطاقةُ من measure الراجع ولا يُستدعى v2_plan_of ثانية
  function countForm(box, ctx, p) {
    V.form({
      title: 'سجّل ملاحظة', what: p.target || '',
      fields: [
        { key: 'phase', type: 'pick', label: 'في جدول', items: [['baseline', 'قياس شدّة أو تكرار السلوك'], ['followup', 'متابعة السلوك']] },
        { key: 'on', type: 'date', label: 'التاريخ' },
        { key: 'window', label: 'فترة الملاحظة (اختياريّ)' },
        { key: 'tally', type: 'number', label: 'التكرار' },
      ],
      ok: 'سجّلها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_plan_count', { p_plan: p.plan, p_phase: v.phase, p_on_date: v.on, p_window_ar: v.window, p_tally: v.tally }, 'تسجيل ملاحظة');
        if (error) return error;
        if (!data || data.ok !== true) return 'لم يُسجّلها الباب';
        if (data.measure) p.measure = data.measure;
        V.flash('ok', data.said_ar || '');
        render(box, ctx);
        return null;
      },
    });
  }

  // كتابةُ الخطّة أو تعديلُ مسودّتها — وتحت حقولها بنكُ العبارات (plDesc · plAnte · plPost · plGain)
  // t: مهمّةُ الخطّة (من شاشة الوكيل) · وإلّا فالرصدةُ من ctx.record (بطاقةُ الحالة) — فيُقاس على المخالفة المربوطة
  function write(ctx, t, p) {
    const all = (ctx.result && ctx.result.data) || [];
    const draft = p || all.find((x) => x.status === 'draft') || null;
    const pr = ctx.problem == null ? null : ctx.problem;
    // حارسُ تغيير الخطّة: الخطّةُ المعتمدةُ السابقةُ إلى جوار الحقول — ليرى الكاتبُ ما يُغيّره ولا يُجبَر على التذكّر
    const prev = all.filter((x) => x.status === 'final' && x.final_at).sort((a, b) => String(b.final_at).localeCompare(String(a.final_at)))[0] || null;
    const prevBox = el('div');
    if (prev) {
      const f = el('div', 'rs-file rs-prev');
      f.appendChild(el('h5', null, ['الخطّةُ المعتمدةُ السابقة', prev.final_at_ar].filter(Boolean).join(' — ')));
      if (prev.target) f.appendChild(raw(el('p', null, 'السلوكُ المستهدف: ' + prev.target)));
      const st = lines(prev.steps_list || prev.steps);
      if (st.length) { const ul = raw(el('ul', 'rs-acts')); for (const x of st) ul.appendChild(el('li', null, '• ' + x)); f.appendChild(ul); }
      prevBox.appendChild(f);
    }
    V.form({
      title: draft ? 'خطّةُ تعديل السلوك — مسودّة' : 'خطّةُ تعديل السلوك', what: (ctx.student.name || '') + (t && t.problem_ar ? ' — ' + t.problem_ar : ''),
      fields: [
        { key: 'prev', type: 'node', node: prevBox },
        { key: 'desc', type: 'textarea', label: 'وصفُ السلوك المراد تعديلُه', rows: 2, value: draft ? draft.desc : null, bank: { key: 'plDesc', problem: pr } },
        { key: 'manifest', type: 'textarea', label: 'مظاهرُه عند الطالب (اختياريّ)', rows: 2, value: draft ? draft.manifest : null },
        { key: 'ante', type: 'textarea', label: 'ما يسبقه — مثيراتُه (اختياريّ)', rows: 2, value: draft ? draft.ante : null, bank: { key: 'plAnte', problem: pr } },
        { key: 'conseq', type: 'textarea', label: 'ما يليه (اختياريّ)', rows: 2, value: draft ? draft.conseq : null, bank: { key: 'plPost', problem: pr } },
        { key: 'gain', type: 'textarea', label: 'ما يحقّقه الطالبُ منه (اختياريّ)', rows: 2, value: draft ? draft.gain : null, bank: { key: 'plGain', problem: pr } },
        { key: 'prior', type: 'textarea', label: 'ما سبق من إجراء (اختياريّ)', rows: 2, value: draft ? draft.prior : null },
        { key: 'target', type: 'textarea', label: 'السلوكُ البديلُ المستهدف', rows: 2, value: draft ? draft.target : null },
        { key: 'steps', type: 'textarea', label: 'إجراءاتُ التعديل — سطرٌ لكلّ إجراء', rows: 4, value: draft ? lines(draft.steps_list || draft.steps).join('\n') : null },
        { key: 'starts', type: 'date', label: 'تاريخ البداية', value: draft ? draft.starts : null },
        { key: 'ends', type: 'date', label: 'تاريخ النهاية (اختياريّ)', value: draft ? draft.ends : null },
      ],
      ok: draft ? 'احفظ التعديل' : 'احفظها مسودّة',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_plan_write', {
          p_student: ctx.student.student_id, p_record: t ? t.record_id : (ctx.record || null), p_task: t ? t.task_id : null, p_plan: draft ? draft.plan : null,
          p_desc: v.desc, p_manifest: v.manifest, p_ante: v.ante, p_conseq: v.conseq, p_gain: v.gain, p_prior: v.prior,
          p_target: v.target, p_steps: v.steps, p_starts: v.starts, p_ends: v.ends,
        }, 'كتابة الخطّة');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'حُفظت الخطّة');
        ctx.reload();
        return null;
      },
    });
  }

  function opinionForm(ctx, p, who) {
    const label = OPINIONS[who];
    V.form({
      title: label, what: p.target || '',
      fields: [{ key: 'text', type: 'textarea', label, rows: 3, value: p[who] }],
      ok: 'احفظ الرأي',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_plan_opinion', { p_plan: p.plan, p_who: who, p_text: v.text }, 'رأيٌ في الخطّة');
        if (error) return error;
        V.flash('ok', 'حُفظ الرأي');
        ctx.reload();
        return null;
      },
    });
  }

  function finalForm(ctx, p) {
    V.form({
      title: 'اعتمادُ الخطّة', what: 'باعتماد الخطّة يبدأ قياسُ استجابة الطالب، وعليه تُبنى إحالتُه للّجنة',
      fields: [{ key: 'confirm', label: 'اكتب: أعتمد' }],
      ok: 'اعتمدها',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_plan_final', { p_plan: p.plan, p_confirm: v.confirm }, 'اعتماد الخطّة');
        if (error) return error;
        V.flash('ok', (data && data.note) || 'اعتُمدت الخطّة');
        ctx.reload();
        return null;
      },
    });
  }

  window.MoayadPlan = { render, write };
})();
