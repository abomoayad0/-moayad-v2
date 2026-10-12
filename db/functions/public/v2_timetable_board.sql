-- public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f8c85fb8779ecdcb78d11a9f6fc9a185
CREATE OR REPLACE FUNCTION public.v2_timetable_board(p_school uuid, p_person uuid DEFAULT NULL::uuid, p_section uuid DEFAULT NULL::uuid, p_weekday smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; me uuid; v_all boolean; v_person uuid; v_ws date;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  me := v2.current_person();

  -- من يرى الجدولَ كلَّه؟ إدارةُ المدرسة بتكليفها · ومن سواهم يرى نفسَه وحدَه
  v_all := v2.leads_school(array['deputy','deputy_students','deputy_academic','deputy_school',
            'deputy_school_students','admin_assistant','admin_assistant_students']);
  if v_all then
    v_person := p_person;                 -- للإدارة: ما طلبته، أو الكلّ
  else
    v_person := coalesce(me, '00000000-0000-0000-0000-000000000000'::uuid);
  end if;

  v_ws := v2.loyalty_week_start(current_date);   -- الأسبوعُ يبدأ الأحد

  select jsonb_build_object(
    'mine_only', not v_all,
    'scope_ar', case when v_all then 'جدولُ المدرسة كلِّها'
                     else 'أسبوعُك أنت — ولا تُعرض حصصُ غيرك' end,
    'week_ar', 'أسبوعُ ' || v2.fn_to_hijri(v_ws) || ' إلى ' || v2.fn_to_hijri(v_ws + 4),
    'truth_note_ar', 'هذي خاناتُ الجدول الأصل · وما وقع عليه تبديلٌ أو تغطيةٌ في هذا الأسبوع مكتوبٌ في صفِّه',
    'periods', (select coalesce(jsonb_agg(jsonb_build_object(
          'no',s.period_no,'no_ar',v2.ar_num(s.period_no),
          'period_ar',v2.period_ar(s.period_no),
          'starts',s.starts_at,'ends',s.ends_at,
          'at_ar',v2.time_ar(s.starts_at)||' — '||v2.time_ar(s.ends_at)) order by s.period_no),'[]'::jsonb)
        from v2.period_slots s where s.school_id=p_school),
    'days', jsonb_build_array(
        jsonb_build_object('no',0,'label','الأحد','on_ar',v2.fn_to_hijri(v_ws)),
        jsonb_build_object('no',1,'label','الاثنين','on_ar',v2.fn_to_hijri(v_ws+1)),
        jsonb_build_object('no',2,'label','الثلاثاء','on_ar',v2.fn_to_hijri(v_ws+2)),
        jsonb_build_object('no',3,'label','الأربعاء','on_ar',v2.fn_to_hijri(v_ws+3)),
        jsonb_build_object('no',4,'label','الخميس','on_ar',v2.fn_to_hijri(v_ws+4))),
    'sections', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',c.id,'grade_ar',v2.grade_ar(c.grade),'section',c.section,
          'label',coalesce(c.label_ar, v2.class_ar(c.grade,c.section)))
          order by c.grade, c.section),'[]'::jsonb)
        from v2.class_sections c where c.school_id=p_school and c.active),
    'slots', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',t.id,'weekday',t.weekday,'weekday_ar',t.weekday_ar,
          'period',t.period_no,'period_ar',v2.period_ar(t.period_no),
          'on_date', v_ws + t.weekday,
          'on_ar', v2.fn_to_hijri(v_ws + t.weekday),
          'kind',t.slot_kind,
          'kind_ar', case t.slot_kind when 'teaching' then 'تدريس'
                       when 'standby' then 'انتظار' when 'activity' then 'نشاط'
                       else t.slot_kind end,
          'section_id',t.section_id,
          'section',(select coalesce(c.label_ar, v2.class_ar(c.grade,c.section))
                      from v2.class_sections c where c.id=t.section_id),
          'person_id',t.person_id,
          'person',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.person_id),
          'subject',t.subject_ar,'room',t.room_ar,'note',t.note,
          -- 🔑 حالُها الحقيقيُّ في هذا الأسبوع
          'swapped', exists (select 1 from v2.period_swaps w
                              where w.school_id=p_school and w.on_date = v_ws + t.weekday
                                and (w.req_slot=t.id or w.partner_slot=t.id)
                                and w.status in ('approved','done')),
          'covered', exists (select 1 from v2.period_covers cv
                              where cv.school_id=p_school and cv.on_date = v_ws + t.weekday
                                and cv.period_no=t.period_no and cv.section_id=t.section_id
                                and cv.voided_at is null),
          'state_ar', case
            when exists (select 1 from v2.period_swaps w
                          where w.school_id=p_school and w.on_date = v_ws + t.weekday
                            and (w.req_slot=t.id or w.partner_slot=t.id)
                            and w.status in ('approved','done'))
              then 'بُدِّلت في هذا الأسبوع — فانظر «فصولي اليوم» في يومها'
            when exists (select 1 from v2.period_covers cv
                          where cv.school_id=p_school and cv.on_date = v_ws + t.weekday
                            and cv.period_no=t.period_no and cv.section_id=t.section_id
                            and cv.voided_at is null and cv.cover_person = t.person_id)
              then 'تغطيةٌ تقع عليك في هذا الأسبوع'
            when exists (select 1 from v2.period_covers cv
                          where cv.school_id=p_school and cv.on_date = v_ws + t.weekday
                            and cv.period_no=t.period_no and cv.section_id=t.section_id
                            and cv.voided_at is null)
              then 'غُطّيت عنك في هذا الأسبوع'
            else null end)
          order by t.weekday, t.period_no),'[]'::jsonb)
        from v2.timetable t
        where t.school_id=p_school
          and (v_person is null or t.person_id=v_person)
          and (p_section is null or t.section_id=p_section)
          and (p_weekday is null or t.weekday=p_weekday)),
    'load', (select coalesce(jsonb_agg(jsonb_build_object(
          'person_id',x.pid,'person',x.nm,
          'teaching',x.te,'standby',x.sb,'activity',x.ac,'total',x.tot,
          'total_ar', v2.ar_count(x.tot,'حصّةٌ واحدة','حصّتان','حصص','حصّة'),
          'said_ar', x.nm||' — '||v2.ar_count(x.tot,'حصّةٌ واحدة','حصّتان','حصص','حصّة')||
                     ' (تدريسٌ '||v2.ar_num(x.te)||' · انتظارٌ '||v2.ar_num(x.sb)||
                     ' · نشاطٌ '||v2.ar_num(x.ac)||')')
          order by x.tot desc),'[]'::jsonb)
        from (select pe.id pid, v2.fn_display_name(pe.full_name) nm,
                count(*) filter (where t.slot_kind='teaching') te,
                count(*) filter (where t.slot_kind='standby')  sb,
                count(*) filter (where t.slot_kind='activity') ac,
                count(*) tot
              from v2.timetable t join v2.people pe on pe.id=t.person_id
              where t.school_id=p_school
                and (v_person is null or t.person_id = v_person)   -- 🔑 لا يرى نصابَ غيره
              group by pe.id, pe.full_name) x)
  ) into r;
  return r;
end $function$
;
