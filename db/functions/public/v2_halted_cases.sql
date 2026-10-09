-- public.v2_halted_cases(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d3554221109b8a5307cc1f11b5864a14
CREATE OR REPLACE FUNCTION public.v2_halted_cases(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; r jsonb;
begin
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'الحالاتُ الموقوفُ تصعيدُها');
  perform v2.assert_role(array['principal','deputy','deputy_students','counselor'],
    'الحالاتُ الموقوفُ تصعيدُها');
  select coalesce(jsonb_agg(jsonb_build_object(
           'case', ac.id, 'student', v2.fn_display_name(s.full_name),
           'days', ac.days_count, 'excused', ac.excused,
           'triggered_ar', coalesce(v2.fn_to_hijri(ac.triggered_on)||' هـ',''),
           'why_ar', ac.halt_reason,
           'counsel_case', exists (select 1 from v2.counsel_cases cc where cc.student_id=ac.student_id),
           'open_tasks', (select count(*) from v2.absence_tasks t
                           where t.case_id=ac.id and t.status='open'))
         order by ac.triggered_on desc), '[]'::jsonb) into r
    from v2.absence_cases ac join v2.students s on s.id=ac.student_id
   where ac.school_id=sc and ac.escalation_halted;
  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا حالةَ موقوفٌ تصعيدُها'
      else v2.ar_count(jsonb_array_length(r),'حالةٌ واحدةٌ موقوفٌ تصعيدُها',
             'حالتان موقوفٌ تصعيدُهما','حالاتٍ موقوفٌ تصعيدُها','حالةً موقوفٌ تصعيدُها') end,
    'note_ar','الوقفُ يمنع إخراجَ الخطابات إلى الجهات · ولا يمنع الإخطارَ ولا الرعاية · '||
              'ومن لا حالةَ له عند الموجّه فالوقفُ في حقّه ناقصٌ — فأحِله');
end $function$
;
