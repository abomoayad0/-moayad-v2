-- public.v2_guardian_message(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9f5485205a2fb0e3a059a4d81fe2e596
CREATE OR REPLACE FUNCTION public.v2_guardian_message(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; tpl text; body text; athar text; g record; me text;
begin
  select br.*, cp.text_ar ptext, cp.degree_no dno into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id,'رسالة وليّ الأمر');

  select text_ar into tpl from (select body_ar text_ar, school_id from v2.message_templates
    where key='guardian_notice' and active
      and (school_id is null or school_id=r.school_id)
    order by (school_id is null) limit 1) t;
  if tpl is null then raise exception 'لا قالبَ رسالةٍ لمدرستك'; end if;

  if r.step_no >= 3 then
    athar := E'\n⚖️ وما يترتّب عليه نظامًا\nحسمُ درجةٍ من درجات السلوك الإيجابيّ\nوفُتحت له فرصُ تعويضها — ونأمل أن يغتنمها\n';
  else
    athar := E'\nولم يترتّب عليه حسمٌ — وإنّما هو تنبيهٌ وتوجيه.\n';
  end if;

  select g2.full_name nm, g2.phone ph into g from v2.guardians g2
   where g2.student_id=r.student_id order by g2.is_primary desc limit 1;
  select coalesce(v2.fn_display_name(p.full_name),'إدارة المدرسة') into me
    from v2.people p where p.id = v2.current_person();

  body := tpl;
  body := replace(body,'{المدرسة}',(select name_ar from v2.schools where id=r.school_id));
  body := replace(body,'{الطالب}',(select v2.fn_display_name(s.full_name)
            from v2.students s where s.id=r.student_id));
  body := replace(body,'{الفصل}',(select coalesce(c.label_ar, e.grade||'/'||e.section)
            from v2.enrolments e left join v2.class_sections c
              on c.school_id=e.school_id and c.grade=e.grade and c.section=e.section
            where e.student_id=r.student_id and e.status='active' limit 1));
  body := replace(body,'{السلوك}', rtrim(btrim(r.ptext),'.'));
  body := replace(body,'{الرصدة}','المرّةُ '||v2.ord_ar(r.occurrence_no));
  body := replace(body,'{الأثر}', athar);
  body := replace(body,'{الموقّع}', coalesce(v2.role_ar(v2.my_role()),'إدارة المدرسة')||' — '||me);

  return jsonb_build_object('ok',true,'body',body,
    'guardian', g.nm, 'phone', g.ph,
    'whatsapp', case when g.ph is null then null
      else 'https://wa.me/'||regexp_replace(
        case when g.ph like '0%' then '966'||substr(g.ph,2) else g.ph end,'[^0-9]','','g')
        ||'?text='||v2.url_enc(body) end,
    'step', r.step_no);
end $function$
;
