-- public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9af6fe69175ee8b4b1ced61523f5d674
CREATE OR REPLACE FUNCTION public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'periods', (select coalesce(jsonb_agg(jsonb_build_object(
          'no',s.period_no,'no_ar',v2.ar_num(s.period_no),
          'starts',s.starts_at,'ends',s.ends_at) order by s.period_no),'[]'::jsonb)
        from v2.period_slots s where s.school_id=p_school),
    'days', jsonb_build_array(
        jsonb_build_object('no',0,'label','الأحد'),
        jsonb_build_object('no',1,'label','الاثنين'),
        jsonb_build_object('no',2,'label','الثلاثاء'),
        jsonb_build_object('no',3,'label','الأربعاء'),
        jsonb_build_object('no',4,'label','الخميس')),
    'sections', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',c.id,'grade',c.grade,'grade_ar',v2.ar_num(c.grade),
          'section',c.section,
          'label',coalesce(c.label_ar, c.grade||'/'||c.section))
          order by c.grade, c.section),'[]'::jsonb)
        from v2.class_sections c where c.school_id=p_school and c.active),
    'slots', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',t.id,'weekday',t.weekday,'weekday_ar',t.weekday_ar,
          'period',t.period_no,'period_ar',v2.ar_num(t.period_no),
          'kind',t.slot_kind,
          'kind_ar', case t.slot_kind when 'teaching' then 'تدريس'
                       when 'standby' then 'انتظار' when 'activity' then 'نشاط'
                       else t.slot_kind end,
          'section_id',t.section_id,
          'section',(select coalesce(c.label_ar, c.grade||'/'||c.section)
                      from v2.class_sections c where c.id=t.section_id),
          'person_id',t.person_id,
          'person',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.person_id),
          'subject',t.subject_ar,'room',t.room_ar,'note',t.note)
          order by t.weekday, t.period_no),'[]'::jsonb)
        from v2.timetable t
        where t.school_id=p_school
          and (p_person  is null or t.person_id=p_person)
          and (p_section is null or t.section_id=p_section)
          and (p_weekday is null or t.weekday=p_weekday)),
    'load', (select coalesce(jsonb_agg(jsonb_build_object(
          'person_id',x.pid,'person',x.nm,
          'teaching',x.te,'standby',x.sb,'activity',x.ac,'total',x.tot)
          order by x.tot desc),'[]'::jsonb)
        from (select pe.id pid, v2.fn_display_name(pe.full_name) nm,
                count(*) filter (where t.slot_kind='teaching') te,
                count(*) filter (where t.slot_kind='standby')  sb,
                count(*) filter (where t.slot_kind='activity') ac,
                count(*) tot
              from v2.timetable t join v2.people pe on pe.id=t.person_id
              where t.school_id=p_school group by pe.id, pe.full_name) x)
  ) into r;
  return r;
end $function$
;
