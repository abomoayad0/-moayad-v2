-- public.v2_skill_mark_tool(p_mark uuid, p_tool text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b097d7f292670e4325a9413702763df7
CREATE OR REPLACE FUNCTION public.v2_skill_mark_tool(p_mark uuid, p_tool text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; v_key text;
begin
  select * into m from v2.skill_marks where id=p_mark and voided_at is null;
  if m.id is null then raise exception 'لا رصدَ بهذا المعرّف'; end if;
  perform v2.assert_my_student(m.student_id,'وسمَ أداةِ التقويم');
  v_key := v2.assess_tool_of(m.school_id, p_tool);
  update v2.skill_marks set tool_key=v_key where id=p_mark;
  return jsonb_build_object('ok',true,'mark',p_mark,'tool',v_key,
    'summary_ar','أداةُ التقويم: '||coalesce((select label_ar from v2.assess_tools where key=v_key limit 1),v_key),
    'note_ar',v2.cite_of('assess.tools'));
end $function$
;
