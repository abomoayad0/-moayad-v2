-- public.v2_exceptions_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 98311747e10c8ec607859da1836bd669
CREATE OR REPLACE FUNCTION public.v2_exceptions_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'سجلَّ الاستثناءات');
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',x.id,'rule_kind',x.rule_kind,'rule_ref',x.rule_ref,
      'system_says',x.system_says,'school_does',x.school_does,
      'reason',x.reason,'source',x.source_page,
      'decided_by',(select v2.fn_display_name(full_name) from v2.people where id=x.decided_by),
      'decided_at',x.decided_at) order by x.decided_at desc),'[]'::jsonb)
  into r from v2.exceptions x where x.school_id=p_school;
  return r;
end $function$
;
