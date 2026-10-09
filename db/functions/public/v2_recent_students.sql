-- public.v2_recent_students(p_limit integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a7483768dc443c68d548cd5670fd756f
CREATE OR REPLACE FUNCTION public.v2_recent_students(p_limit integer DEFAULT 8)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid; r jsonb;
begin
  sc := coalesce(v2.acting_school(), null);
  me := v2.current_person();
  if me is null then raise exception 'لا يُعرف صاحبُ الطلب'; end if;
  if sc is null then raise exception 'لم تُعرف مدرستُك — فاختر صفتَك أوّلًا'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'student', t.student_id,
           'name', v2.fn_display_name(s.full_name),
           'grade', e.grade, 'section', e.section,
           'last_ar', t.action_ar,
           'when_ar', coalesce(v2.fn_to_hijri(t.at_last::date)||' هـ','')) order by t.at_last desc),
         '[]'::jsonb) into r
    from (select l.student_id, max(l.at) at_last,
                 (array_agg(l.action_ar order by l.at desc))[1] action_ar
            from v2.action_log l
           where l.person_id = me and l.school_id = sc and l.student_id is not null
             and l.at > now() - interval '21 days'
           group by l.student_id
           order by max(l.at) desc
           limit greatest(coalesce(p_limit,8),1)) t
    join v2.students s on s.id = t.student_id
    left join v2.enrolments e on e.student_id = t.student_id and e.school_id = sc and e.status='active';

  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r) = 0
      then 'لم تعمل على طالبٍ بعينه في الأيّام الماضية'
      else 'آخرُ من عملتَ عليهم — '||
           v2.ar_count(jsonb_array_length(r),'طالبٌ واحد','طالبان','طلّاب','طالبًا') end,
    'note_ar','يُبنى من سجلّ أفعالك في ثلاثة أسابيع — ولا يراه غيرُك');
end $function$
;
