-- public.v2_late_due_board(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a0ad0ccf314c7910179c2fab8da2ac07
CREATE OR REPLACE FUNCTION public.v2_late_due_board(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_term smallint; r jsonb; n_due int; n_done int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','admin_assistant',
    'admin_assistant_students','counselor'],'قراءةَ واجبِ الإحالة للتأخّر');
  perform v2.assert_my_school(p_school,'قراءةَ واجبِ الإحالة للتأخّر');
  v_term := coalesce(p_term, v2.fn_term_of(p_school, current_date));

  select coalesce(jsonb_agg(jsonb_build_object(
      'student', x.student_id,
      'name_ar', x.nm,
      'class_ar', x.cls,
      'daily_n', x.daily_n, 'period_n', x.period_n, 'total_n', x.total_n,
      'excused_n', x.excused_n, 'last_on', x.last_on,
      'threshold', x.threshold,
      'referred', x.cid is not null,
      'case_id', x.cid,
      'state_ar', case when x.cid is not null then 'أُحيل إلى الموجّه الطلابيّ'
                       else '🔴 واجبُ إحالةٍ لم يقع' end,
      'basis_ar', 'سياسةُ الدليل — س-٦-ا-١ سياسة ٠١ ص١٧٩ · لا سلّمُ ممارساتِ المدرسة'
    ) order by x.total_n desc, x.nm), '[]'::jsonb),
    count(*) filter (where x.cid is null), count(*) filter (where x.cid is not null)
    into r, n_due, n_done
    from (
      select e.student_id,
             v2.fn_display_name(s.full_name) nm,
             coalesce(cs.label_ar,'—') cls,
             t.daily_n, t.period_n, t.total_n, t.excused_n, t.last_on, t.threshold,
             v2.late_referral_of(p_school, e.student_id, v_term) cid
        from v2.enrolments e
        join v2.students s on s.id = e.student_id
        left join v2.class_sections cs
               on cs.school_id=e.school_id and cs.grade=e.grade and cs.section=e.section
        cross join lateral v2.late_tally(p_school, e.student_id, v_term) t
       where e.school_id = p_school and e.status = 'active' and t.over) x;

  return jsonb_build_object('ok',true,'term',v_term,'rows',r,
    'due', n_due, 'referred', n_done,
    'summary_ar', case when jsonb_array_length(r)=0
      then 'لا طالبَ تجاوز خمسَ مرّاتِ تأخّرٍ بلا عذرٍ في هذا الفصل'
      else v2.ar_count(jsonb_array_length(r),'طالبٌ واحدٌ تجاوز العتبة','طالبان تجاوزا العتبة',
                       'طلّابٍ تجاوزوا العتبة','طالبًا تجاوزوا العتبة')
           ||' · '||v2.ar_num(n_due)||' لم تقع إحالتُهم بعد' end,
    'note_ar','العتبةُ نصٌّ لا اجتهاد: أكثرُ من خمسِ مرّاتٍ بلا عذرٍ في الفصل الدراسيّ. '
      ||'وهذا غيرُ سلّمِ ممارساتِ المدرسة الذي يصعّد عند ثلاثٍ في أربعةَ عشرَ يومًا — '
      ||'فذاك اجتهادُ مدرسةٍ وهذا واجبُ دليل، ولا يُجزئ أحدُهما عن الآخر.');
end $function$
;
