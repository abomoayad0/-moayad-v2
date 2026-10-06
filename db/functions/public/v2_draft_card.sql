-- public.v2_draft_card(p_draft uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 334ed7153120d4ff3211653a644c4b7f
CREATE OR REPLACE FUNCTION public.v2_draft_card(p_draft uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; sc uuid;
begin
  select school_id into sc from v2.timetable_drafts where id=p_draft;
  if sc is null then raise exception 'المقترحُ غيرُ موجود'; end if;
  if not v2.my_school(sc) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'draft', jsonb_build_object('id',d.id,'state',d.state,'made_at',d.made_at,
        'made_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.made_by),
        'applied_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.applied_by),
        'note',d.note_ar,'stats',d.stats,'applied_at',d.applied_at),
    'slots', (select coalesce(jsonb_agg(jsonb_build_object(
          'weekday',x.weekday,
          'weekday_ar',(array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'])[x.weekday+1],
          'period',x.period_no,'period_ar',v2.ar_num(x.period_no),
          'kind',x.slot_kind,
          'kind_ar',case x.slot_kind when 'teaching' then 'تدريس'
                      when 'standby' then 'انتظار' else 'نشاط' end,
          'section',(select coalesce(c.label_ar,c.grade||'/'||c.section)
                      from v2.class_sections c where c.id=x.section_id),
          'person',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=x.person_id),
          'subject',x.subject_ar,'why',x.why_ar)
          order by x.weekday, x.period_no),'[]'::jsonb)
        from v2.timetable_draft_slots x where x.draft_id=d.id),
    'load', (select coalesce(jsonb_agg(jsonb_build_object(
          'person',y.nm,'teaching',y.te,'standby',y.sb) order by y.te desc),'[]'::jsonb)
        from (select v2.fn_display_name(pe.full_name) nm,
                count(*) filter (where x.slot_kind='teaching') te,
                count(*) filter (where x.slot_kind='standby')  sb
              from v2.timetable_draft_slots x join v2.people pe on pe.id=x.person_id
              where x.draft_id=p_draft group by pe.id, pe.full_name) y)
  ) into r from v2.timetable_drafts d where d.id=p_draft;
  return r;
end $function$
;
