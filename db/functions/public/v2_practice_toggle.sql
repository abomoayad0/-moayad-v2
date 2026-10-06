-- public.v2_practice_toggle(p_school uuid, p_code text, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9c93c1eccf8d039a0ebb4b78c90f0c32
CREATE OR REPLACE FUNCTION public.v2_practice_toggle(p_school uuid, p_code text, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; newcode text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبط ممارسات الصفّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into cur from v2.class_practices where code=p_code;
  if cur.code is null then raise exception 'ممارسةٌ غيرُ موجودة'; end if;

  if cur.school_id = p_school then
    update v2.class_practices set active=coalesce(p_active,false) where code=p_code;
    return jsonb_build_object('ok',true,'active',coalesce(p_active,false));
  end if;

  if cur.school_id is null then
    -- إخفاءُ مشتركةٍ في مدرسةٍ = فصلُ نسخةٍ مخفيّة
    newcode := 'sch_'||substr(md5(p_school::text||cur.code),1,10);
    insert into v2.class_practices(code,school_id,based_on,title_ar,points,polarity,scope,kind,
        zone,once_per_day,threshold_count,threshold_days,escalate_to,escalate_note,ord,active,origin)
    values (newcode,p_school,cur.code,cur.title_ar,cur.points,cur.polarity,cur.scope,cur.kind,
        cur.zone,cur.once_per_day,cur.threshold_count,cur.threshold_days,cur.escalate_to,
        cur.escalate_note,cur.ord,coalesce(p_active,false),'المدرسة')
    on conflict (code) do update set active=coalesce(p_active,false);
    return jsonb_build_object('ok',true,'code',newcode,'active',coalesce(p_active,false));
  end if;
  raise exception 'هذي الممارسةُ لمدرسةٍ أخرى';
end $function$
;
