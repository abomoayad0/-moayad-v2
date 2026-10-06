-- public.v2_slot_check(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1b38f67f897cbcdc4739107ef8767ca1
CREATE OR REPLACE FUNCTION public.v2_slot_check(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare busy record; occupied record; w jsonb := '[]'::jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;

  -- المعلّمُ مشغولٌ في هذي الحصّة
  if p_person is not null then
    select t.*, coalesce(c.label_ar, c.grade||'/'||c.section) sec into busy
      from v2.timetable t left join v2.class_sections c on c.id=t.section_id
     where t.school_id=p_school and t.weekday=p_weekday and t.period_no=p_period
       and t.person_id=p_person and t.id is distinct from p_slot limit 1;
    if busy.id is not null then
      w := w || jsonb_build_object('kind','teacher_busy',
        'text','المعلّمُ عنده '||case busy.slot_kind when 'teaching' then 'حصّةٌ' 
               when 'standby' then 'انتظارٌ' else 'نشاطٌ' end||
               coalesce(' في '||busy.sec,'')||' في هذا الوقت');
    end if;
  end if;

  -- الفصلُ مشغولٌ بمعلّمٍ آخر — في التدريس وحدَه
  if p_section is not null and coalesce(p_kind,'teaching')='teaching' then
    select t.*, v2.fn_display_name(pe.full_name) nm into occupied
      from v2.timetable t left join v2.people pe on pe.id=t.person_id
     where t.school_id=p_school and t.weekday=p_weekday and t.period_no=p_period
       and t.section_id=p_section and t.slot_kind='teaching'
       and t.id is distinct from p_slot limit 1;
    if occupied.id is not null then
      w := w || jsonb_build_object('kind','section_busy',
        'text','الفصلُ عنده حصّةٌ مع '||coalesce(occupied.nm,'معلّمٍ آخر')||' في هذا الوقت');
    end if;
  end if;

  return jsonb_build_object('ok',(jsonb_array_length(w)=0),'conflicts',w);
end $function$
;
