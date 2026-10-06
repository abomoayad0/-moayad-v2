-- public.v2_calendar_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b0f9b54c5a5f0bc3ac405c78d34b542b
CREATE OR REPLACE FUNCTION public.v2_calendar_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'scope', (select jsonb_build_object('key',cs.key,'label',cs.label_ar,
                'regions',cs.regions_ar,'source',cs.source_doc)
              from v2.schools s left join v2.calendar_scopes cs on cs.key=s.calendar_scope
              where s.id=p_school),
    'scopes', (select coalesce(jsonb_agg(jsonb_build_object(
                'key',k.key,'label',k.label_ar,'default',k.is_default,
                'regions',k.regions_ar)),'[]'::jsonb) from v2.calendar_scopes k),
    'years', (select coalesce(jsonb_agg(jsonb_build_object(
          'year',y.id,'name',y.name,'starts',y.starts_on,'ends',y.ends_on,
          'current',y.is_current,'status',y.status,'closed_on',y.closed_on,
          'terms',(select coalesce(jsonb_agg(jsonb_build_object(
               'term',t.id,'no',t.number,'starts',t.starts_on,'ends',t.ends_on,
               'current',t.is_current) order by t.number),'[]'::jsonb)
             from v2.terms t where t.year_id=y.id),
          'students',(select count(*) from v2.enrolments e
                       where e.year_id=y.id and e.school_id=p_school and e.status='active'))
          order by y.starts_on desc),'[]'::jsonb)
        from v2.academic_years y where y.school_id=p_school)
  ) into r;
  return r;
end $function$
;
