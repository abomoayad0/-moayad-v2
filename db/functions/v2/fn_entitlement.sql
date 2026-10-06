-- v2.fn_entitlement(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f7b270f5334ccedb0ae4e15bb00d4dea
CREATE OR REPLACE FUNCTION v2.fn_entitlement(p_school uuid)
 RETURNS TABLE(post_key text, post_label text, entitled_count integer, filled_count integer, status text, by_assigned_teacher boolean, basis text, conflict boolean, rule_ids bigint[], source_pages text[], rule_notes text[], seat_sources text[])
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with sch as (
  select * from v2.schools where id = p_school
),
matched as (
  select r.*
  from v2.staffing_rules r
  cross join sch s
  where r.stage = s.stage
    and (r.category = 'all' or r.category = s.category)
    and (
      (r.basis = 'classes'  and s.classes_count  is not null
        and s.classes_count  >= coalesce(r.min_value, -2147483648)
        and s.classes_count  <= coalesce(r.max_value,  2147483647))
      or
      (r.basis = 'students' and s.students_count is not null
        and s.students_count >= coalesce(r.min_value, -2147483648)
        and s.students_count <= coalesce(r.max_value,  2147483647))
    )
),
ent as (
  select
    m.post_key,
    max(coalesce(m.grants_count,1))::int                       as entitled_count,
    (count(distinct coalesce(m.grants_count,1)) > 1)           as conflict,
    bool_or(coalesce(m.grants_assigned,false))                 as by_assigned_teacher,
    string_agg(distinct m.basis, ' + ')                        as basis,
    array_agg(m.id order by m.id)                              as rule_ids,
    array_agg(distinct m.source_page)                          as source_pages,
    array_remove(array_agg(distinct m.note), null)             as rule_notes
  from matched m
  group by m.post_key
),
occ as (
  select
    s.post_key,
    count(*)::int                                              as filled_count,
    array_remove(array_agg(distinct s.seat_source), null)      as seat_sources
  from v2.school_seats s
  where s.school_id = p_school
    and s.ended_on is null
  group by s.post_key
)
select
  coalesce(e.post_key, o.post_key)                             as post_key,
  p.label_ar                                                   as post_label,
  coalesce(e.entitled_count, 0)                                as entitled_count,
  coalesce(o.filled_count, 0)                                  as filled_count,
  case
    when coalesce(e.entitled_count,0) = 0 and coalesce(o.filled_count,0) > 0
      then 'مشغول غير مستحق'
    when coalesce(o.filled_count,0) = 0
      then 'مستحق وشاغر'
    when coalesce(o.filled_count,0) < e.entitled_count
      then 'مستحق وناقص'
    when coalesce(o.filled_count,0) = e.entitled_count
      then 'مكتمل'
    else 'زائد عن المستحق'
  end                                                          as status,
  coalesce(e.by_assigned_teacher, false)                       as by_assigned_teacher,
  e.basis,
  coalesce(e.conflict, false)                                  as conflict,
  e.rule_ids,
  e.source_pages,
  e.rule_notes,
  o.seat_sources
from ent e
full outer join occ o on o.post_key = e.post_key
left join v2.posts p on p.key = coalesce(e.post_key, o.post_key)
order by
  case when coalesce(e.entitled_count,0) = 0 then 1 else 0 end,
  coalesce(e.post_key, o.post_key);
$function$
;
