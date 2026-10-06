-- public.v2_student_timeline(p_student uuid, p_as text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7e6eafde0fbe2d23f0a8cf87234f5382
CREATE OR REPLACE FUNCTION public.v2_student_timeline(p_student uuid, p_as text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare who text; lvl text[]; ask text[]; r jsonb;
begin
  who := v2.caller_kind(p_student);
  if who = 'none' then raise exception 'لا تملك الاطّلاع على سجلّ هذا الطالب'; end if;

  lvl := case who
           when 'counselor' then array['all','staff','counselor_only']
           when 'staff'     then array['all','staff']
           else                  array['all'] end;

  if p_as is not null then
    ask := case p_as
             when 'guardian'  then array['all']
             when 'student'   then array['all']
             when 'staff'     then array['all','staff']
             when 'counselor' then array['all','staff','counselor_only']
             else lvl end;
    lvl := array(select unnest(lvl) intersect select unnest(ask));
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'on',e.on_date,'kind',e.kind,'title',e.title_ar,'body',e.body_ar,
      'needs_action',e.needs_action,'action',e.action_ar)
      order by e.on_date desc, e.created_at desc),'[]'::jsonb)
  into r from v2.events e
  where e.student_id = p_student and e.visible_to = any(lvl);

  return jsonb_build_object(
    'as', who,
    'as_ar', case who when 'counselor' then 'الموجّه الطلابيّ'
                      when 'guardian'  then 'وليّ الأمر'
                      when 'student'   then 'الطالب'
                      when 'staff'     then 'منسوب المدرسة' else '—' end,
    'can_see', lvl, 'events', r);
end $function$
;
