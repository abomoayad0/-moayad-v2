-- public.v2_delegate_revoke(p_delegation uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 752b328d6c908d37c2f72891b4b4135a
CREATE OR REPLACE FUNCTION public.v2_delegate_revoke(p_delegation uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إلغاءَ إنابة');
  select * into d from v2.delegations where id=p_delegation;
  if d.id is null then raise exception 'الإنابةُ غيرُ موجودة'; end if;
  if not v2.my_school(d.school_id) then raise exception 'ليست مدرستك'; end if;
  if d.revoked_at is not null then raise exception 'أُلغيت هذي الإنابةُ سلفًا'; end if;
  if btrim(coalesce(p_why,''))='' then
    raise exception 'لا تُلغى إنابةٌ بلا سببٍ مكتوب'; end if;
  update v2.delegations set revoked_at=now(), revoked_why=btrim(p_why)
   where id=p_delegation;
  return jsonb_build_object('ok',true,'note','أُلغيت الإنابةُ — وما وقع بها يبقى مقيَّدًا');
end $function$
;
