-- public.v2_form_inbox_read(p_inbox uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1978681d3ec79783e2982da1457bce23
CREATE OR REPLACE FUNCTION public.v2_form_inbox_read(p_inbox uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare me uuid; stu uuid; n int;
begin
  if auth.uid() is null then raise exception 'لا يُفتح الصندوقُ بلا حساب'; end if;
  select s.id into stu from v2.students s
   where s.user_id = auth.uid() and coalesce(s.portal_active,false);
  if stu is null then me := v2.current_person(); end if;

  update v2.form_inbox i set read_at = now()
   where i.id = p_inbox and i.read_at is null
     and ((stu is not null and i.to_kind='student' and i.student_id = stu)
       or (stu is null and i.to_kind in ('counselor','committee') and i.person_id = me));
  get diagnostics n = row_count;

  if n = 0 and not exists (select 1 from v2.form_inbox i where i.id = p_inbox
        and ((stu is not null and i.to_kind='student' and i.student_id = stu)
          or (stu is null and i.to_kind in ('counselor','committee') and i.person_id = me)))
  then
    raise exception 'هذا الصفُّ ليس في صندوقك';
  end if;

  return jsonb_build_object('ok', true, 'marked', n);
end
$function$
;
