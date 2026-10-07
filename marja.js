// مؤيّد · جداولُ مرجع الدرجة الأولى في لوحة التحكّم — أبوابُها بجسورها الخاصّة:
// ① «قوائم حصر السلوكيات»: v2_census_list · v2_census_item_save (المشتركُ يُعدَّل بنسخةٍ لمدرستك تحجبه)
// ② «بنك العبارات التربوية»: v2_bank · v2_bank_save (المشتركُ لا يُعدَّل — تُضاف عبارتُك)
// ③ «النصائح التربوية»: v2_advice_for · v2_advice_save — ثلاثٌ لكلّ سلوكٍ تتدرّج بالرصدة
// ④ «قوالب رسائل ولي الأمر»: v2_message_template_save
// ⑤ «حصر السلوكيات»: v2_census_sweep — يعيد ما انقضت مدّتُه
// لا حسابَ هنا: النصوصُ والأيقوناتُ والترتيبُ من القاعدة، والقاعدةُ تحرس من يضبط.
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;
  const { el, errText } = M;
  const { arabize, btn, flash, pick } = V;
  const school = () => M.state.school;
  const errBox = (box, e) => box.appendChild(el('div', 'notice err', errText(e)));
  const ACTIVE = [['yes', 'مفعّل'], ['no', 'موقوف']];

  // ================= ① قوائمُ الحصر =================
  async function censusItemsTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'جارٍ جلب القوائم…'));
    const { data, error } = await M.rpc('v2_census_list', { p_school: school() }, 'قوائم الحصر');
    box.textContent = '';
    if (error) { errBox(box, error); return; }
    for (const [pol, title] of [['negative', 'السلوكيّاتُ السلبيّة'], ['positive', 'السلوكيّاتُ الإيجابيّة']]) {
      const list = (data && data[pol]) || [];
      box.appendChild(el('h4', 'rs-sub', title + ' (' + list.length + ')'));
      for (const x of list) {
        const f = el('div', 'rs-file');
        const hd = el('div', 'rs-hd');
        hd.append(el('h5', null, (x.icon || '•') + ' ' + x.text), el('span', 'rs-who', x.mine ? 'لمدرستك' : 'مشترك'));
        f.appendChild(hd);
        if (x.hint) f.appendChild(el('p', null, x.hint));
        f.appendChild(btn('عدّل', 'rs-btn soft', () => itemForm(box, pol, x)));
        box.appendChild(f);
      }
      box.appendChild(btn(pol === 'negative' ? 'أضف سلوكًا سلبيًّا' : 'أضف سلوكًا إيجابيًّا', 'rs-btn', () => itemForm(box, pol, null)));
    }
    arabize(box);
  }

  function itemForm(box, pol, x) {
    V.form({
      title: x ? 'سلوكُ «' + x.text + '»' : 'سلوكٌ جديد', what: x && !x.mine ? 'مشتركٌ للمجمّع — تعديلُه نسخةٌ لمدرستك تحجبه' : '',
      fields: [
        { key: 'icon', label: 'الأيقونة', value: x ? x.icon : null },
        { key: 'text', label: 'النصّ', value: x ? x.text : null },
        { key: 'hint', type: 'textarea', label: 'شرحُه (يظهر باللمسة الأولى)', rows: 2, value: x ? x.hint : null },
        { key: 'ord', type: 'number', label: 'الترتيب (اختياريّ)', value: x ? x.ord : null },
        ...(x ? [{ key: 'active', type: 'pick', label: 'الحال', items: ACTIVE, value: 'yes' }] : []),
      ],
      ok: 'احفظ',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_census_item_save', {
          p_school: school(), p_item: x ? x.id : null, p_polarity: pol, p_icon: v.icon, p_text: v.text, p_hint: v.hint,
          p_ord: v.ord, p_active: x ? v.active === 'yes' : null,
        }, 'حفظ سلوك الحصر');
        if (error) return error;
        flash('ok', (data && data.mode) || 'حُفظ');
        censusItemsTool(box);
        return null;
      },
    });
  }

  // ================= ② بنكُ العبارات =================
  // المفاتيحُ كما في القاعدة (phrase_bank.bank_key)
  const KEYS = ['cause', 'limit', 'taskWhat', 'callWhat', 'referWhy', 'referAsk', 'sessionT', 'sessionR', 'csSay', 'csSeen', 'csFactors', 'csPlan',
    'fwT', 'fwN', 'rpV', 'rpR', 'cmT', 'cmR', 'gN', 'ctT', 'plDesc', 'plAnte', 'plPost', 'plGain'];
  let bankKey = 'cause';
  async function bankTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'العباراتُ العامّةُ لكلّ مفتاح — وعباراتُ كلّ سلوكٍ تظهر تحت حقولها في الشاشات.'));
    const keys = el('div', 'rs-pick');
    box.appendChild(keys);
    const list = el('div');
    box.appendChild(list);
    const draw = async () => {
      pick(keys, KEYS.map((k) => [k, k]), bankKey, (k) => { bankKey = k; draw(); });
      list.textContent = '';
      const { data, error } = await M.rpc('v2_bank', { p_key: bankKey, p_problem: null, p_school: school() }, 'بنك العبارات');
      if (error) { errBox(list, error); return; }
      const rows = data || [];
      list.appendChild(el('p', 'rs-meta', bankKey + ' · ' + rows.length + ' عبارة'));
      for (const x of rows) {
        const f = el('div', 'rs-file');
        const hd = el('div', 'rs-hd');
        hd.append(el('p', null, x.text), el('span', 'rs-who', x.mine ? 'لمدرستك' : 'مشتركة'));
        f.appendChild(hd);
        if (x.mine) f.appendChild(btn('عدّل', 'rs-btn soft', () => phraseForm(x, draw)));
        list.appendChild(f);
      }
      list.appendChild(btn('أضف عبارة', 'rs-btn', () => phraseForm(null, draw)));
      arabize(list);
    };
    draw();
  }

  function phraseForm(x, done) {
    V.form({
      title: x ? 'عبارةٌ لمدرستك' : 'عبارةٌ جديدةٌ في ' + bankKey, what: 'المشتركةُ للمجمّع لا تُعدَّل — تُضاف عبارتُك',
      fields: [
        { key: 'text', type: 'textarea', label: 'العبارة', rows: 2, value: x ? x.text : null },
        { key: 'ord', type: 'number', label: 'الترتيب (اختياريّ)', value: x ? x.ord : null },
        ...(x ? [{ key: 'active', type: 'pick', label: 'الحال', items: ACTIVE, value: 'yes' }] : []),
      ],
      ok: 'احفظ',
      onOk: async (v) => {
        const { data, error } = await M.rpc('v2_bank_save', {
          p_school: school(), p_id: x ? x.id : null, p_key: bankKey, p_problem: null, p_text: v.text, p_ord: v.ord,
          p_active: x ? v.active === 'yes' : null,
        }, 'حفظ عبارة');
        if (error) return error;
        flash('ok', (data && data.mode) || 'حُفظت');
        done();
        return null;
      },
    });
  }

  // ================= ③ النصائحُ التربويّة =================
  // لا جسرَ يسرد السلوكيّاتِ بلا طالب: تُؤخذ قائمتُها من v2_conduct_list لأوّل طالبٍ مقيَّدٍ في المدرسة (مرحلتُها واحدة)
  let problems = null;
  async function adviceTool(box) {
    box.textContent = '';
    if (!problems || problems.school !== school()) {
      box.appendChild(el('p', 'rs-meta', 'جارٍ جلب السلوكيّات…'));
      const st = await M.rpc('v2_students_board', { p_school: school(), p_grade: null, p_section: null, p_q: null }, 'كشف الطلّاب');
      const first = st.data && st.data[0];
      if (st.error || !first) { box.textContent = ''; if (st.error) errBox(box, st.error); else box.appendChild(el('p', 'rs-meta', 'لا طالبَ مقيَّدٌ تُعرف به قائمةُ السلوكيّات.')); return; }
      const { data, error } = await M.rpc('v2_conduct_list', { p_student: first.student, p_mode: 'onsite', p_target: null }, 'قائمة السلوكيّات');
      box.textContent = '';
      if (error) { errBox(box, error); return; }
      problems = { school: school(), list: data || [] };
    }
    const sec = el('div');
    V.chooser(box, problems.list.map((p) => [p.id, p.text, p.degree_ar]), null, (id) => showAdvice(sec, problems.list.find((p) => p.id === id)));
    box.appendChild(sec);
  }

  async function showAdvice(sec, p) {
    sec.textContent = '';
    if (!p) return;
    sec.appendChild(el('h4', 'rs-sub', p.text));
    // النصائحُ الثلاث بالرصدة: ١ · ٢ · ٣ — وما بعدها يأخذ الأخيرة
    const rows = await Promise.all([1, 2, 3].map((n) => M.rpc('v2_advice_for', { p_problem: p.id, p_occurrence: n }, 'النصيحة التربويّة')));
    rows.forEach((r, i) => {
      const n = i + 1;
      const f = el('div', 'rs-file');
      f.appendChild(el('h5', null, 'الرصدة ' + n));
      if (r.error) errBox(f, r.error);
      else {
        const d = r.data || {};
        f.appendChild(el('p', null, d.text && d.occurrence === n ? d.text : 'لا نصيحةَ لهذي الرصدة' + (d.text ? ' — يُعطى ما للرصدة ' + d.occurrence : '')));
      }
      f.appendChild(btn('اكتبها لمدرستك', 'rs-btn soft', () => adviceForm(sec, p, n, r.data && r.data.occurrence === n ? r.data.text : null)));
      sec.appendChild(f);
    });
    arabize(sec);
  }

  function adviceForm(sec, p, n, text) {
    V.form({
      title: 'النصيحةُ للرصدة ' + n, what: p.text,
      fields: [{ key: 'text', type: 'textarea', label: 'النصيحة', rows: 2, value: text }],
      ok: 'احفظ',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_advice_save', { p_school: school(), p_problem: p.id, p_occurrence: n, p_text: v.text }, 'حفظ النصيحة');
        if (error) return error;
        flash('ok', 'حُفظت النصيحة');
        showAdvice(sec, p);
        return null;
      },
    });
  }

  // ================= ④ قالبُ رسالة وليّ الأمر =================
  const VARS = '{المدرسة} {الطالب} {الفصل} {السلوك} {الرصدة} {الأثر} {الموقّع}';
  function templateTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'المتغيّرات: ' + VARS + ' — و{الطالب} لا بدّ منه.'));
    box.appendChild(el('div', 'rs-note', 'لا جسرَ يقرأ القالبَ القائم — فما يُكتب هنا يحلّ محلّه لمدرستك. وتراه كاملًا في «رسالة» من إثبات الاتّصال.'));
    box.appendChild(btn('اكتب قالبَ مدرستك', 'rs-btn', () => V.form({
      title: 'قالبُ رسالة وليّ الأمر', what: VARS,
      fields: [{ key: 'body', type: 'textarea', label: 'نصُّ الرسالة', rows: 12 }],
      ok: 'احفظ القالب',
      onOk: async (v) => {
        const { error } = await M.rpc('v2_message_template_save', { p_school: school(), p_key: 'guardian_notice', p_body: v.body }, 'حفظ القالب');
        if (error) return error;
        flash('ok', 'حُفظ قالبُ مدرستك');
        return null;
      },
    })));
    arabize(box);
  }

  // ================= ⑤ حصرُ السلوكيّات: ما انقضت مدّتُه =================
  function censusSweepTool(box) {
    box.textContent = '';
    box.appendChild(el('p', 'rs-meta', 'التكليفُ الذي انقضت مدّتُه ولم يُسلَّم يعود إلى الوكيل بسببه.'));
    box.appendChild(btn('أعِد ما انقضت مدّتُه', 'rs-btn', async () => {
      const { data, error } = await M.rpc('v2_census_sweep', { p_school: school() }, 'إعادة ما انقضت مدّته');
      if (error) { flash('bad', errText(error)); return; }
      flash('ok', (data && data.note) || 'تمّ');
    }));
  }

  window.MoayadMarja = { censusItemsTool, bankTool, adviceTool, templateTool, censusSweepTool };
})();
