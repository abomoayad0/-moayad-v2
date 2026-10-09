-- v2.g_grade_rules()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aac652d88d703d986ea4c2da730d9a1f
CREATE OR REPLACE FUNCTION v2.g_grade_rules()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare m record; o record;
begin
  if new.points is null then return new; end if;
  if new.verdict is null then
    raise exception 'لا تُقدَّر درجةٌ قبل إقرار المشاركة'; end if;
  if new.verdict in ('لم ينفّذ','لم يحضر') and new.points > 0 then
    raise exception 'لا درجةَ لمن %', new.verdict; end if;
  select * into o from v2.merit_opportunities where id=new.opp_id;
  select * into m from v2.conduct_merits where id=o.merit_id;
  if m.points is not null and new.points > m.points then
    raise exception '%', 'الدرجةُ المقرّرةُ لهذي الممارسة '||v2.ar_num(m.points)||
                         ' — '||v2.cite_page('committee.practice_points'); end if;
  if m.points is null and new.points > 6 then
    raise exception '%', 'ما لم يُذكر في الجدول: بتوصية اللجنة وبما لا يتجاوز ستّ درجات — '||
                         v2.cite_page('committee.grade_cap'); end if;
  return new;
end $function$
;
