-- v2.trg_tt_clash()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 872c0c22e2af97a5f1881fa2fb56e161
CREATE OR REPLACE FUNCTION v2.trg_tt_clash()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare other text;
begin
  if new.person_id is null then return new; end if;
  select cs.label_ar into other from v2.timetable t join v2.class_sections cs on cs.id=t.section_id
   where t.school_id=new.school_id and t.year_id=new.year_id
     and t.term_no is not distinct from new.term_no
     and t.weekday=new.weekday and t.period_no=new.period_no
     and t.person_id=new.person_id and t.id is distinct from new.id limit 1;
  if other is not null then
    raise exception 'تعارض: المعلّم مُسنَد في الحصة % يوم % إلى %',
      new.period_no, new.weekday_ar, other; end if;
  return new;
end $function$
;
