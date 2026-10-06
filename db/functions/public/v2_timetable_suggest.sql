-- public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a0093b8f710298970afa8478e3301c79
CREATE OR REPLACE FUNCTION public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare did uuid; pl record; sec record; d smallint; p smallint;
        cand uuid; placed int := 0; unplaced int := 0; standby int := 0;
        maxp smallint; gaps jsonb := '[]'::jsonb; need int; have int;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'اقتراحَ جدول');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.subject_plan where school_id=p_school and active) then
    raise exception 'لا خطّةَ موادَّ لمدرستك — أسّسها أوّلًا من لوحة التحكّم'; end if;
  select max(period_no) into maxp from v2.period_slots where school_id=p_school;
  if maxp is null then raise exception 'لا حصصَ في جدول مدرستك — أسّسها أوّلًا'; end if;

  insert into v2.timetable_drafts(school_id,made_by,note_ar)
  values (p_school,v2.current_person(),nullif(btrim(coalesce(p_note,'')),''))
  returning id into did;

  if coalesce(p_keep_fixed,true) then
    insert into v2.timetable_draft_slots(draft_id,weekday,period_no,section_id,
        person_id,subject_ar,slot_kind,why_ar)
    select did,t.weekday,t.period_no,t.section_id,t.person_id,t.subject_ar,t.slot_kind,
           'مثبَّتةٌ من الجدول القائم'
      from v2.timetable t where t.school_id=p_school and t.slot_kind='teaching';
    select count(*) into placed from v2.timetable_draft_slots where draft_id=did;
  end if;

  for pl in
    select s.grade, s.subject_ar, s.slots from v2.subject_plan s
     where s.school_id=p_school and s.active order by s.slots desc, s.grade, s.ord
  loop
    for sec in
      select c.id, c.grade from v2.class_sections c
       where c.school_id=p_school and c.grade=pl.grade and c.active
    loop
      select count(*) into have from v2.timetable_draft_slots x
       where x.draft_id=did and x.section_id=sec.id and x.subject_ar=pl.subject_ar
         and x.slot_kind='teaching';
      need := pl.slots - have;
      while need > 0 loop
        cand := null;
        -- 🔑 الأيّامُ من صفرٍ إلى أربعة
        for d in 0..4 loop
          for p in 1..maxp loop
            exit when cand is not null;
            if exists (select 1 from v2.timetable_draft_slots x
                        where x.draft_id=did and x.weekday=d and x.period_no=p
                          and x.section_id=sec.id) then continue; end if;
            select ts.person_id into cand
              from v2.teacher_subjects ts
             where ts.school_id=p_school and ts.subject_ar=pl.subject_ar
               and not exists (select 1 from v2.timetable_draft_slots y
                                where y.draft_id=did and y.weekday=d and y.period_no=p
                                  and y.person_id=ts.person_id)
               and (select count(*) from v2.timetable_draft_slots z
                     where z.draft_id=did and z.person_id=ts.person_id
                       and z.slot_kind='teaching')
                   < coalesce((select max(q.max_slots) from v2.teaching_quota q
                        join v2.assignments a on a.post_key=q.post_key
                       where q.school_id=p_school and a.person_id=ts.person_id
                         and a.school_id=p_school and a.ended_on is null), 24)
             order by ts.is_main desc,
               (select count(*) from v2.timetable_draft_slots z
                 where z.draft_id=did and z.person_id=ts.person_id and z.slot_kind='teaching')
             limit 1;
            if cand is not null then
              insert into v2.timetable_draft_slots(draft_id,weekday,period_no,section_id,
                  person_id,subject_ar,slot_kind,why_ar)
              values (did,d,p,sec.id,cand,pl.subject_ar,'teaching',
                  'وُزّعت بحسب خطّة المواد وتخصّص المعلّم');
              placed := placed + 1;
            end if;
          end loop;
          exit when cand is not null;
        end loop;
        if cand is null then
          unplaced := unplaced + 1;
          gaps := gaps || jsonb_build_object(
            'grade',pl.grade,'subject',pl.subject_ar,
            'section',(select coalesce(c.label_ar,c.grade||'/'||c.section)
                        from v2.class_sections c where c.id=sec.id),
            'why','لا معلّمَ متقنًا فارغًا في أيّ خانةٍ متاحةٍ لهذا الفصل');
          exit;
        end if;
        need := need - 1;
      end loop;
    end loop;
  end loop;

  insert into v2.timetable_draft_slots(draft_id,weekday,period_no,person_id,slot_kind,why_ar)
  select did, g.d, g.p, g.person_id, 'standby', 'فراغٌ في جدول المعلّم'
  from (
    select pe.id person_id, dd.d, pp.p
      from v2.people pe
      join v2.assignments a on a.person_id=pe.id and a.school_id=p_school and a.ended_on is null
      cross join generate_series(0,4) dd(d)
      cross join generate_series(1,maxp) pp(p)
     where a.post_key in ('subject_teacher','sped_teacher','gifted_teacher')
       and not exists (select 1 from v2.timetable_draft_slots x
                        where x.draft_id=did and x.weekday=dd.d and x.period_no=pp.p
                          and x.person_id=pe.id)
  ) g;
  select count(*) into standby from v2.timetable_draft_slots
   where draft_id=did and slot_kind='standby';

  update v2.timetable_drafts set stats = jsonb_build_object(
      'placed',placed,'unplaced',unplaced,'standby',standby,
      'placed_ar',v2.ar_num(placed),'standby_ar',v2.ar_num(standby),'gaps',gaps)
   where id=did;
  return jsonb_build_object('ok',true,'draft',did,
    'placed',placed,'unplaced',unplaced,'standby',standby,'gaps',gaps,
    'note','هذا مقترحٌ يُعرض ولا يُثبَّت — راجعه ثمّ أقرّه أو ألغِه');
end $function$
;
