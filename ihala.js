// مؤيّد · الإحالةُ في الخطّة العلاجيّة — تكليف ٣٤ (window.MoayadIhala)
// v2_remedial_refer(p_student, p_to counselor|deputy_students|principal, p_reason, p_plan) — بابٌ واحد بثلاثة أسباب
// والسببُ مكتوبٌ والقاعدةُ تردُّ ما قلَّ عن حدّه · وبعدَ الإحالة: summary_ar ثمّ gate_ar كما جاءا — ولا تركيبَ من الشاشة
// ويُقرأ «من يُحيل» من الباب نفسِه: المعلّمُ يُردّ على من لم يبلغ بابًا، ولا يُخفى عنه الزرّ — يُبيَّن له أنّه سيُردّ
(function () {
  'use strict';

  const M = window.Moayad;
  const V = window.MoayadView;

  const TO = [['counselor', 'الموجّه الطلابيّ'], ['deputy_students', 'وكيل شؤون الطلّاب'], ['principal', 'مدير المدرسة']];
  // الصفاتُ التي يقبلها الباب (assert_role) — ووكيلُ شؤون الطلاب ليس منها
  const ROLES = ['subject_teacher', 'sped_teacher', 'gifted_teacher', 'deputy_academic', 'deputy', 'principal', 'counselor', 'deputy_school', 'deputy_academic_school'];
  const TEACHERS = ['subject_teacher', 'sped_teacher', 'gifted_teacher'];
  const role = () => { const r = ((M.state.me && M.state.me.roles) || []).find((x) => x.is_current === true); return r ? r.role_key : null; };
  const can = () => ROLES.includes(role());
  // للمعلّم: الزرُّ ظاهرٌ ومعه أنّ الباب يردّ من لم يبلغ بابًا من أبوابه
  const TEACHER_NOTE = 'تُقبلُ الإحالةُ إن لم يُتقنْ مهارةً من الحدّ الأدنى أو بلغ المعيارَ المتساوي — وإلّا ردّها البابُ بسببها، والردُّ هو المعيارُ يعمل';

  // after(data) بعد القبول — والبيانُ يُعرض في شريط الصفحة
  function form(stu, after) {
    const teacher = TEACHERS.includes(role());
    V.form({
      title: 'أحِلْه في الخطّة العلاجيّة', what: stu.name || '',
      fields: [
        { key: 'to', type: 'pick', label: 'إلى', items: TO, value: 'counselor' },
        { key: 'why', type: 'textarea', label: 'السبب', rows: 3, hint: teacher ? TEACHER_NOTE : null },
      ],
      ok: 'أحِلْه',
      onOk: async (v) => {
        if (!v.to) return 'اخترْ جهةَ الإحالة';
        const { data, error } = await M.rpc('v2_remedial_refer', { p_student: stu.id, p_to: v.to, p_reason: v.why, p_plan: null }, 'الإحالة في الخطّة العلاجيّة');
        if (error) return error;
        const d = data || {};
        // gate_ar يقولُ بأيّ بابٍ أُحيل — كما جاء
        V.flash('ok', [d.summary_ar, d.note_ar].filter(Boolean).join(' — '));
        if (after) after(d);
        return null;
      },
    });
  }

  function button(stu, after, cls) {
    return V.btn('أحِلْه في الخطّة العلاجيّة', cls || 'rs-btn soft', () => form(stu, after));
  }

  window.MoayadIhala = { form, button, can, TEACHER_NOTE };
})();
