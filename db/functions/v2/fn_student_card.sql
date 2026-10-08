-- v2.fn_student_card(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 75f1d484ccaebe0786b190be86cdab49
CREATE OR REPLACE FUNCTION v2.fn_student_card(p_student uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with e as (select * from v2.enrolments where student_id=p_student and status='active' limit 1),
s as (select * from v2.students where id=p_student)
select jsonb_build_object(
 'student', jsonb_build_object(
   'id', s.id, 'name', v2.fn_display_name(s.full_name), 'full_name', s.full_name,
   'student_no', s.student_no, 'grade', e.grade, 'section', e.section,
   'school', (select name_ar from v2.schools where id=e.school_id)),
 'guardians', coalesce((select jsonb_agg(jsonb_build_object('name',g.full_name,'phone',g.phone,'relation',g.relation))
   from v2.guardians g where g.student_id=p_student),'[]'::jsonb),
 'attendance', (select to_jsonb(z) from v2.fn_attendance_state(p_student, e.year_id) z),
 'behavior_balance', v2.fn_behavior_balance(p_student, e.year_id, 1::smallint),
 'days', coalesce((select jsonb_agg(jsonb_build_object(
     'on_g',a.on_date,'on_h',v2.fn_to_hijri(a.on_date),'state',a.state,
     'assembly',a.assembly_state,'minutes',a.minutes_from_assembly,
     'by',a.recorded_role,'status',a.day_status,'test',a.is_test) order by a.on_date desc)
   from v2.attendance a where a.student_id=p_student and a.state<>'present'),'[]'::jsonb),
 'behavior', coalesce((select jsonb_agg(jsonb_build_object(
     'on', r.occurred_on,'on_h',v2.fn_to_hijri(r.occurred_on),
     'problem', p.text_ar,'degree',p.degree_no,'occurrence',r.occurrence_no,'step',r.step_no,
     'place', r.place,'note',r.note,
     'tasks_open', (select count(*) from v2.behavior_tasks t where t.record_id=r.id and t.status='open'),
     'tasks_all', (select count(*) from v2.behavior_tasks t where t.record_id=r.id),
     'test', r.is_test) order by r.occurred_on desc, r.occurrence_no desc, r.created_at desc)
   from v2.behavior_records r join v2.conduct_problems p on p.id=r.problem_id
   where r.student_id=p_student),'[]'::jsonb),
 'tasks', coalesce((select jsonb_agg(jsonb_build_object(
     'id',t.id,'text',t.text_ar,'owner',t.owner_role,'status',t.status,
     'skip_reason',t.skip_reason,'ord',t.ord) order by t.ord)
   from v2.behavior_tasks t join v2.behavior_records r on r.id=t.record_id
   where r.student_id=p_student and t.status='open'),'[]'::jsonb),
 'excuses', coalesce((select jsonb_agg(jsonb_build_object(
     'id',c.id,'from',c.from_date,'to',c.to_date,'submitted',c.submitted_on,
     'channel',c.channel,'attachment',c.attachment_name,'decision',c.decision,
     'verdict',c.window_verdict) order by c.from_date desc)
   from v2.absence_excuse_claims c where c.student_id=p_student),'[]'::jsonb),
 'ledger', coalesce((select jsonb_agg(jsonb_build_object(
     'kind',l.kind,'points',l.points,'on',l.on_date,'reason',l.reason) order by l.created_at desc)
   from v2.attendance_ledger l where l.student_id=p_student),'[]'::jsonb))
from s, e;
$function$
;
