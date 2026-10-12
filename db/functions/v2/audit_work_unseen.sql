-- v2.audit_work_unseen()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6f43f385978d20dc2926d74f5db25fab
CREATE OR REPLACE FUNCTION v2.audit_work_unseen()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select
    'عملٌ صفّيٌّ · ' || w.subject_ar || ' · ' ||
      (select cs.label_ar from v2.class_sections cs where cs.id = w.section_id),
    'كُلِّف به ' ||
      case when w.scope = 'class' then 'الفصلُ كلُّه' else 'طالبٌ واحد' end ||
      ' وهو ظاهرٌ، ولا يصل ' || v2.ar_num(x.n) ||
      ' من الطلبة — لا حسابَ لهم أو بوّابتُهم مغلقة. فالتكليفُ يقع ولا يُرى.',
    'خلل'
  from v2.class_work w
  join v2.class_sections cs0 on cs0.id = w.section_id
  cross join lateral (
      select count(*) n from v2.enrolments en
       join v2.students st on st.id = en.student_id
       where en.school_id = w.school_id and en.ended_on is null
         and en.grade = cs0.grade and en.section = cs0.section
         and (w.scope = 'class' or en.student_id = w.student_id)
         and (st.user_id is null or not coalesce(st.portal_active,false))) x
  where w.voided_at is null
    and w.shows_to_student
    and w.due_on >= current_date
    and x.n > 0;
$function$
;
