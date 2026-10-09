-- public.v2_contacts_of(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f121999a499c3fc143433fccdbdeab16
CREATE OR REPLACE FUNCTION public.v2_contacts_of(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'سجلّ الاتصال');
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',c.id,'on',c.on_date,'at',c.at_time,'channel',c.channel,
      'outcome',c.outcome,'attempt',c.attempt_no,'attempt_ar',v2.ar_num(c.attempt_no),
      'summary',c.summary_ar,'guardian_say',c.guardian_say,
      'source',coalesce(c.source,'none'),
      'source_ar', case coalesce(c.source,'none')
                     when 'behavior' then 'عن بندِ سلوك'
                     when 'absence'  then 'عن بندِ مواظبة'
                     else 'بلا بندٍ يحمله' end,
      'task',c.source_id,
      'about', case coalesce(c.source,'none')
                 when 'behavior' then (select t.text_ar from v2.behavior_tasks t where t.id=c.source_id)
                 when 'absence'  then (select x.text_ar from v2.absence_tasks x where x.id=c.source_id)
                 else null end,
      'guardian',(select v2.fn_display_name(g.full_name) from v2.guardians g where g.id=c.guardian_id),
      'by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.by_person))
      order by c.on_date desc, c.created_at desc),'[]'::jsonb)
  into r from v2.guardian_contacts c where c.student_id=p_student;
  return r;
end $function$
;
