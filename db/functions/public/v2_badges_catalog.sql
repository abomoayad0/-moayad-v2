-- public.v2_badges_catalog(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2c387450bbfeea35fda58de4752e4a1e
CREATE OR REPLACE FUNCTION public.v2_badges_catalog(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; rows_j jsonb; n int;
begin
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc, 'فهرسَ الشارات');

  with res as (
    select distinct on (b.code) b.*
      from v2.loyalty_badges b
     where b.active and (b.school_id = sc or b.school_id is null)
     order by b.code, (b.school_id is null)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'code', r.code,
           'title_ar', r.title_ar,
           'note_ar', r.note_ar,
           'rule_kind', r.rule_kind,
           'rule_ar', v2.badge_rule_ar(sc, r::v2.loyalty_badges),
           'rule_n', r.rule_n,
           'auto', r.rule_kind <> 'manual',
           'auto_ar', case when r.rule_kind <> 'manual'
                           then 'آليّة — لا زرَّ لها' else 'بيدِ مُكلَّف' end,
           'who_may', r.who_may,
           'who_may_ar', case when r.rule_kind <> 'manual' then 'لا تُمنح بيدِ أحد'
             else coalesce((select string_agg(coalesce(v2.role_ar(k), k), ' · ')
                              from unnest(r.who_may) k), 'لا أحدَ مكلَّفٌ بمنحها') end,
           'can_i', case when r.rule_kind <> 'manual' then false
                         else v2.loyalty_can(r.who_may) end,
           'needs_reason', r.rule_kind = 'manual',
           'source_ar', r.source_ar,
           'school_own', r.school_id is not null,
           'ord', r.ord) order by r.ord, r.code), '[]'::jsonb), count(*)
    into rows_j, n
    from res r;

  return jsonb_build_object(
    'rows', rows_j,
    'count', n,
    'count_ar', case when n = 0 then 'لا شارةَ معروضة'
      else 'المعروضُ '||v2.ar_count(n,'شارةٌ واحدة','شارتان','شارات','شارة') end,
    'note_ar', 'الشارةُ تكريمٌ لا تُنزَع · ولا تُمنح للطالب أكثرَ من مرّةٍ في العام · '||
               'والآليّةُ لا زرَّ لها، يمنحها محرّكُها بشرطها',
    'from', jsonb_build_object(
      'doors', jsonb_build_array('v2_badges_catalog','v2_badges_of_student',
                                 'v2_badge_award','v2_badge_run'),
      'why_ar', 'الشاراتُ مستنسخةٌ من «مؤيّد القديم» · ولا سندَ لها في الدليل الإجرائيّ، '||
                'فمصدرُ كلِّ شارةٍ مكتوبٌ في صفِّها'));
end $function$
;
