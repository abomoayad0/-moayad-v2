-- public.v2_practices(p_school uuid, p_scope text, p_polarity text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e79faab7d4d01a992c921f6a3f3c5857
CREATE OR REPLACE FUNCTION public.v2_practices(p_school uuid, p_scope text, p_polarity text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'code',p.code,'title',p.title_ar,'points',p.points,
      'polarity',p.polarity,'kind',p.kind,
      'scope',p.scope,
      'scope_ar',(select label_ar from v2.practice_scopes s where s.key=p.scope),
      'zone',p.zone,'once_per_day',p.once_per_day,
      'threshold_count',p.threshold_count,'threshold_days',p.threshold_days,
      'escalate_to',p.escalate_to,'escalate_note',p.escalate_note,
      'note',p.note_ar,'ord',p.ord,
      'owned', (p.school_id is not null),
      'based_on', p.based_on,
      'origin', p.origin)
      order by p.scope, p.ord, p.code),'[]'::jsonb)
  into r from v2.class_practices p
  where p.active
    and (p.school_id = p_school
         or (p.school_id is null
             and not exists (select 1 from v2.class_practices x
                  where x.school_id = p_school and x.based_on = p.code and x.active)))
    and (p_scope is null or p.scope = p_scope)
    and (p_polarity is null or p.polarity = p_polarity);
  return r;
end $function$
;
