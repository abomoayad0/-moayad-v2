-- v2.trg_tt_clash()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5e5773f9bcc5a4b2d92ad17cb62ff988
CREATE OR REPLACE FUNCTION v2.trg_tt_clash()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare other text; forced boolean;
begin
  if new.person_id is null then return new; end if;

  -- 🔑 إقرارُ التضارب يُمرَّر من الجسر في هذي الجلسة
  begin forced := coalesce(current_setting('v2.force_clash', true) = 'on', false);
  exception when others then forced := false; end;
  if forced then return new; end if;

  select coalesce(cs.label_ar, cs.grade||'/'||cs.section) into other
    from v2.timetable t left join v2.class_sections cs on cs.id=t.section_id
   where t.school_id=new.school_id and t.year_id=new.year_id
     and t.term_no is not distinct from new.term_no
     and t.weekday=new.weekday and t.period_no=new.period_no
     and t.person_id=new.person_id and t.id is distinct from new.id limit 1;

  if other is not null then
    raise exception 'تعارض: المعلّمُ مُسنَدٌ في الحصة % يوم % إلى %',
      v2.ar_num(new.period_no),
      (array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'])[new.weekday+1],
      other;
  end if;
  return new;
end $function$
;
