-- public.v2_quota_save(p_school uuid, p_post text, p_min smallint, p_max smallint, p_standby_max smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 86502cde43d54ed4679aacb7163f4a11
CREATE OR REPLACE FUNCTION public.v2_quota_save(p_school uuid, p_post text, p_min smallint, p_max smallint, p_standby_max smallint, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'ضبطَ نصاب الحصص');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.posts where key=p_post) then
    raise exception 'وظيفةٌ غيرُ معروفة'; end if;
  if p_max is null or p_max < 1 then raise exception 'اكتب الحدَّ الأعلى للنصاب'; end if;
  if p_min is not null and p_min > p_max then
    raise exception 'الحدُّ الأدنى أكبرُ من الأعلى'; end if;
  insert into v2.teaching_quota(school_id,post_key,min_slots,max_slots,standby_max,note_ar,set_by)
  values (p_school,p_post,p_min,p_max,p_standby_max,
      nullif(btrim(coalesce(p_note,'')),''),v2.current_person())
  on conflict (school_id,post_key) do update set
    min_slots=excluded.min_slots, max_slots=excluded.max_slots,
    standby_max=excluded.standby_max, note_ar=excluded.note_ar,
    set_by=excluded.set_by, set_at=now();
  return jsonb_build_object('ok',true);
end $function$
;
