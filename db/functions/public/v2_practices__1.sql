-- public.v2_practices(p_school uuid, p_scope text, p_polarity text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 489bf7a5e8d7a9b7fedac48e3eb022a5
CREATE OR REPLACE FUNCTION public.v2_practices(p_school uuid, p_scope text, p_polarity text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(x order by x->>'scope', (x->>'ord')::int, x->>'code'),'[]'::jsonb)
  into r from (
    select jsonb_build_object(
      'code', p.code,
      'title',          coalesce(o.title_ar, p.title_ar),
      'points',         coalesce(o.points, p.points),
      'polarity',       coalesce(o.polarity, p.polarity),
      'kind',           coalesce(o.kind, p.kind),
      'scope',          coalesce(o.scope, p.scope),
      'scope_ar', (select s.label_ar from v2.practice_scopes s
                    where s.key = coalesce(o.scope, p.scope) limit 1),
      'zone',           coalesce(o.zone, p.zone),
      'once_per_day',   coalesce(o.once_per_day, p.once_per_day),
      'threshold_count',coalesce(o.threshold_count, p.threshold_count),
      'threshold_days', coalesce(o.threshold_days, p.threshold_days),
      'escalate_to',    coalesce(o.escalate_to, p.escalate_to),
      'escalate_note',  coalesce(o.escalate_note, p.escalate_note),
      'note',           coalesce(o.note_ar, p.note_ar),
      'ord',            coalesce(o.ord, p.ord),
      'mine',           (p.school_id is not null),
      'edited',         (o.code is not null),
      'origin',         p.origin) x
    from v2.class_practices p
    left join v2.practice_overrides o
           on o.code = p.code and o.school_id = p_school
    where p.active
      and (p.school_id is null or p.school_id = p_school)
      and coalesce(o.hidden,false) = false
      and (p_scope    is null or coalesce(o.scope, p.scope) = p_scope)
      and (p_polarity is null or coalesce(o.polarity, p.polarity) = p_polarity)
  ) t;
  return r;
end $function$
;
