-- public.v2_delegations_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b1bda93b22049c7b25966c50296a4b4f
CREATE OR REPLACE FUNCTION public.v2_delegations_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'live', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',d.id,'post',d.post_key,'post_ar',v2.role_ar(d.post_key),
          'to',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.to_person),
          'to_id',d.to_person,
          'from',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.from_person),
          'starts',d.starts_on,'ends',d.ends_on,'reason',d.reason,'letter',d.letter_no,
          'by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.issued_by))
          order by d.starts_on desc),'[]'::jsonb)
        from v2.delegations d
        where d.school_id=p_school and d.revoked_at is null
          and d.starts_on <= current_date
          and (d.ends_on is null or d.ends_on >= current_date)),
    'past', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',d.id,'post_ar',v2.role_ar(d.post_key),
          'to',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.to_person),
          'starts',d.starts_on,'ends',d.ends_on,'reason',d.reason,
          'revoked_at',d.revoked_at,'revoked_why',d.revoked_why)
          order by d.starts_on desc),'[]'::jsonb)
        from v2.delegations d
        where d.school_id=p_school
          and (d.revoked_at is not null or (d.ends_on is not null and d.ends_on < current_date))),
    'vacant', (select coalesce(jsonb_agg(jsonb_build_object(
          'post',sp.post_key,'post_ar',v2.role_ar(sp.post_key))),'[]'::jsonb)
        from v2.structure_posts sp
        join v2.schools s on s.id=p_school and s.structure_code=sp.structure_code
        where not exists (select 1 from v2.assignments a
                where a.post_key=sp.post_key and a.school_id=p_school and a.ended_on is null))
  ) into r;
  return r;
end $function$
;
