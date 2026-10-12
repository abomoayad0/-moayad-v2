-- public.v2_role_end(p_holder uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3a9e29274a26fea02adefd9756df5e3e
CREATE OR REPLACE FUNCTION public.v2_role_end(p_holder uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare h record; nm text;
begin
  if btrim(coalesce(p_reason,''))='' then raise exception 'العزلُ يلزمه سببٌ مكتوب'; end if;
  select * into h from v2.class_role_holders where id=p_holder;
  if h.id is null then raise exception 'إسنادٌ غيرُ موجود'; end if;
  if not v2.my_school(h.school_id) then raise exception 'ليست مدرستَك'; end if;
  if h.ended_at is not null then raise exception 'عُزل من قبل'; end if;
  if not v2.work_teaches(v2.current_person(), h.section_id, h.subject_ar) then
    raise exception 'الدورُ في مادّة غيرِك — ولا تعزل منها';
  end if;

  update v2.class_role_holders
     set ended_at=now(), ended_by=v2.current_person(), end_reason=btrim(p_reason)
   where id=p_holder;
  select v2.fn_display_name(full_name) into nm from v2.students where id=h.student_id;
  return jsonb_build_object('ok',true,
    'msg','عُزل '||coalesce(nm,'الطالب')||' من «'||h.role_ar||'» — وبقي سببُه في السجلّ');
end $function$
;
