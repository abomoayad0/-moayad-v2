-- public.v2_guardian_form_read(p_inbox uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8a3349516583330b75687730f941e89c
CREATE OR REPLACE FUNCTION public.v2_guardian_form_read(p_inbox uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_g uuid;
begin
  select id into v_g from v2.guardians
   where user_id = auth.uid() and portal_active limit 1;
  if v_g is null then
    raise exception 'لا بوّابةَ وليِّ أمرٍ فعّالةً لحسابك — فلا يُقرأ بريدٌ عنك';
  end if;
  if not exists (select 1 from v2.form_inbox fi
                  where fi.id = p_inbox and fi.guardian_id = v_g) then
    raise exception 'هذا النموذجُ ليس في بريدك — ولا يَقرأ أحدٌ بريدَ غيره';
  end if;

  update v2.form_inbox set read_at = now()
   where id = p_inbox and guardian_id = v_g and read_at is null;
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_guardian_form_read', sqlstate, sqlerrm);
end $function$
;
