-- public.v2_health_case_end(p_case uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a04f215d805bf67470cdb6e1872a4ec9
CREATE OR REPLACE FUNCTION public.v2_health_case_end(p_case uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record;
begin
  select * into c from v2.health_cases where id=p_case;
  if c.id is null then raise exception 'لا حالةَ بهذا المُعرّف'; end if;
  perform v2.health_gate(c.school_id, 'إنهاءَ حالةٍ صحيّة');
  if c.ended_at is not null then raise exception 'أُنهيت من قبل — %', coalesce(c.end_reason,'بلا سبب'); end if;
  if coalesce(btrim(p_reason),'')='' then raise exception 'لا تُنهى حالةٌ بلا سببٍ مكتوب'; end if;
  update v2.health_cases set ended_at=now(), ended_by=v2.current_person(), end_reason=btrim(p_reason)
   where id=p_case;
  return jsonb_build_object('ok',true,'said_ar','أُنهيت الحالةُ — '||btrim(p_reason));
end $function$
;
