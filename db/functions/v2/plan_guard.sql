-- v2.plan_guard(p_plan uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ecd54120cca9f8cf14d35534c41d0749
CREATE OR REPLACE FUNCTION v2.plan_guard(p_plan uuid, p_what text)
 RETURNS TABLE(school_id uuid, grade smallint, subject_ar text, term_no smallint, owner_person uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; v_me uuid := v2.current_person(); v_admin boolean := true;
begin
  select p.* into r from v2.lesson_plans p where p.id = p_plan;
  if r.id is null then raise exception 'لا خطّةَ بهذا الرقم'; end if;
  perform v2.assert_my_school(r.school_id, p_what);

  if r.is_locked then
    raise exception 'هذي الخطّةُ مُقفلةٌ — ولا تُعدَّل حتى يُفتح الإقفال. وسببُ الإقفال: %',
      coalesce(r.lock_why,'لم يُكتب'); end if;

  begin
    perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
      'admin_assistant','info_registrar'], p_what);
  exception when others then v_admin := false; end;

  if not v_admin then
    perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher'], p_what);
    if r.owner_person is not null and r.owner_person <> v_me then
      raise exception 'هذي الخطّةُ لمعلّمٍ آخرَ — ولا يُعدّلها غيرُ صاحبها أو الإدارة';
    end if;
  end if;

  return query select r.school_id, r.grade, r.subject_ar, r.term_no, r.owner_person;
end $function$
;
