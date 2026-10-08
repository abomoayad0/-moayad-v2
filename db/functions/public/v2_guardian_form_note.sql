-- public.v2_guardian_form_note(p_inbox uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 de58c38f9f5cebbc43c4f272b0cdd69d
CREATE OR REPLACE FUNCTION public.v2_guardian_form_note(p_inbox uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare fi record; st text; vr text;
begin
  if btrim(coalesce(p_note,''))='' then raise exception 'اكتب رأيك'; end if;
  select * into fi from v2.form_inbox where id=p_inbox
    and guardian_id in (select id from v2.guardians where user_id=auth.uid() and portal_active);
  if fi.id is null then raise exception 'هذا النموذج ليس في صندوقك'; end if;

  -- 🔒 ما سُحب لا تُكتب عليه ملاحظة — فالمسحوبُ خبرٌ لا مطلب
  select e.status, e.void_reason into st, vr from v2.form_entries e where e.id=fi.entry_id;
  if st = 'void' then
    raise exception 'سُحب هذا النموذج فلا تُكتب عليه ملاحظة — والسببُ: %',
      coalesce(vr,'لم يُكتب سبب');
  end if;

  update v2.form_entries set guardian_note=p_note, updated_at=now() where id=fi.entry_id;
  update v2.form_inbox set read_at=coalesce(read_at,now()) where id=p_inbox;
  return jsonb_build_object('ok',true);
end
$function$
;
