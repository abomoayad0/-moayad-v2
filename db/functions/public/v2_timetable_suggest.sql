-- public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a8eb119ef3dad6039ceb2f0843c4b90c
CREATE OR REPLACE FUNCTION public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  did uuid; pl record; sec record; pr v2.subject_pairing;
  v_d smallint; v_p smallint; v_teacher uuid; v_many int; v_pick uuid;
  placed int := 0; unplaced int := 0; standby int := 0; split_warn int := 0;
  maxp smallint; need int; have int; gaps jsonb := '[]'::jsonb;
  v_need smallint; v_taken int; v_sec_ar text;
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

  -- ①  المثبَّتُ من الجدول القائم
  if coalesce(p_keep_fixed,true) then
    insert into v2.timetable_draft_slots(draft_id,weekday,period_no,section_id,
        person_id,subject_ar,slot_kind,why_ar)
    select did,t.weekday,t.period_no,t.section_id,t.person_id,t.subject_ar,t.slot_kind,
           'مثبَّتةٌ من الجدول القائم'
      from v2.timetable t where t.school_id=p_school and t.slot_kind='teaching';
    select count(*) into placed from v2.timetable_draft_slots where draft_id=did;
  end if;

  -- ②  توزيعُ التدريس
  for pl in
    select s.grade, s.subject_ar, s.slots from v2.subject_plan s
     where s.school_id=p_school and s.active
     order by case when (v2.pairing_of(p_school, s.grade, s.subject_ar)).mode = 'joined'
                   then 0 else 1 end,
              s.slots desc, s.grade, s.ord
  loop
    for sec in
      select c.id, c.grade, coalesce(c.label_ar, c.grade||'/'||c.section) label
        from v2.class_sections c
       where c.school_id=p_school and c.grade=pl.grade and c.active
    loop
      pr := v2.pairing_of(p_school, pl.grade, pl.subject_ar);
      v_sec_ar := sec.label;

      -- 🔑 س-٨-ا-١ سياسة ٠٢: «عدم تجزئة المادة الواحدة للفصل الواحد»
      --    قرأناها: معلّمٌ واحدٌ يُدرّس المادّةَ لهذا الفصل
      select count(distinct x.person_id) into v_many
        from v2.timetable_draft_slots x
       where x.draft_id=did and x.section_id=sec.id and x.subject_ar=pl.subject_ar
         and x.slot_kind='teaching' and x.person_id is not null;
      v_teacher := null;
      if v_many >= 1 then
        select x.person_id into v_teacher
          from v2.timetable_draft_slots x
         where x.draft_id=did and x.section_id=sec.id and x.subject_ar=pl.subject_ar
           and x.slot_kind='teaching' and x.person_id is not null
         group by x.person_id order by count(*) desc limit 1;
      end if;
      if v_many > 1 then
        split_warn := split_warn + 1;
        gaps := gaps || jsonb_build_object('grade',pl.grade,'subject',pl.subject_ar,
          'section',v_sec_ar,
          'why','المادّةُ مجزّأةٌ بين '||v2.ar_count(v_many,'معلّم','معلّمين','معلّمين','معلّمًا')||
                ' في الجدول القائم — وهذا يخالف س-٨-ا-١ سياسة ٠٢، فأُكملت على الأكثرِ حصصًا ولم يُعدَّل المثبَّت');
      end if;

      select count(*) into have from v2.timetable_draft_slots x
       where x.draft_id=did and x.section_id=sec.id and x.subject_ar=pl.subject_ar
         and x.slot_kind='teaching';
      need := pl.slots - have;

      while need > 0 loop
        v_d := null; v_p := null; v_pick := null;

        -- خانةٌ تُراعي: عدلَ البثّ على الأيّام · وقاعدةَ المادّة في اليوم · ووجودَ معلّمٍ متاح
        select x.d, x.p into v_d, v_p from (
          select dd.d::smallint d, pp.p::smallint p,
            (select count(*) from v2.timetable_draft_slots z
              where z.draft_id=did and z.section_id=sec.id and z.weekday=dd.d) day_load,
            (select count(*) from v2.timetable_draft_slots z2
              where z2.draft_id=did and z2.section_id=sec.id and z2.weekday=dd.d
                and z2.subject_ar=pl.subject_ar) same_day,
            exists (select 1 from v2.timetable_draft_slots z3
              where z3.draft_id=did and z3.section_id=sec.id and z3.weekday=dd.d
                and z3.subject_ar=pl.subject_ar and abs(z3.period_no - pp.p)=1) adj
          from generate_series(0,4) dd(d) cross join generate_series(1,maxp) pp(p)
          where not exists (select 1 from v2.timetable_draft_slots y
                             where y.draft_id=did and y.weekday=dd.d and y.period_no=pp.p
                               and y.section_id=sec.id)
        ) x
        where x.same_day < pr.max_per_day
          and (pr.mode <> 'joined' or x.same_day = 0 or x.adj)
          and exists (
            select 1 from v2.teacher_subjects ts
             where ts.school_id=p_school and ts.subject_ar=pl.subject_ar
               and (v_teacher is null or ts.person_id = v_teacher)
               and not exists (select 1 from v2.timetable_draft_slots w
                                where w.draft_id=did and w.weekday=x.d and w.period_no=x.p
                                  and w.person_id=ts.person_id)
               and (select count(*) from v2.timetable_draft_slots q
                     where q.draft_id=did and q.person_id=ts.person_id and q.slot_kind='teaching')
                   < v2.quota_of(p_school, ts.person_id))
        order by case when pr.mode='joined' and x.same_day > 0 and x.adj then 0 else 1 end,
                 x.day_load asc,
                 x.d, x.p
        limit 1;

        if v_d is null then
          unplaced := unplaced + 1;
          gaps := gaps || jsonb_build_object('grade',pl.grade,'subject',pl.subject_ar,
            'section',v_sec_ar,
            'why', case
              when pr.mode = 'split' and pl.slots > 5
                then 'حصصُ المادّة ' || v2.ar_num(pl.slots) ||
                     ' وأيّامُ الدراسة خمسةٌ — فلا تُوزَّع بقاعدة «منفصلة» التي تمنع وقوعَها مرّتين في يوم. اجعلها متّصلةً أو مطلقةً من لوحة التحكّم'
              when v_teacher is not null
                then 'معلّمُ المادّة في هذا الفصل لا يجد خانةً فارغةً تُوافق قاعدةَ المادّة — ولا يُجزَّأ الإسنادُ بمعلّمٍ ثانٍ (س-٨-ا-١ سياسة ٠٢)'
              when pr.mode = 'split'
                then 'لا خانةَ تبقى مع قاعدة «منفصلة» — فالمادّةُ لا تقع مرّتين في يومٍ لهذا الفصل. وللمدرسة أن تجعلها متّصلةً أو مطلقة'
              else 'لا معلّمَ متقنًا فارغًا في أيّ خانةٍ متاحةٍ لهذا الفصل' end);
          exit;
        end if;

        select ts.person_id into v_pick
          from v2.teacher_subjects ts
         where ts.school_id=p_school and ts.subject_ar=pl.subject_ar
           and (v_teacher is null or ts.person_id = v_teacher)
           and not exists (select 1 from v2.timetable_draft_slots w
                            where w.draft_id=did and w.weekday=v_d and w.period_no=v_p
                              and w.person_id=ts.person_id)
           and (select count(*) from v2.timetable_draft_slots q
                 where q.draft_id=did and q.person_id=ts.person_id and q.slot_kind='teaching')
               < v2.quota_of(p_school, ts.person_id)
         order by ts.is_main desc,
           (select count(*) from v2.timetable_draft_slots z
             where z.draft_id=did and z.person_id=ts.person_id and z.slot_kind='teaching')
         limit 1;

        insert into v2.timetable_draft_slots(draft_id,weekday,period_no,section_id,
            person_id,subject_ar,slot_kind,why_ar)
        values (did,v_d,v_p,sec.id,v_pick,pl.subject_ar,'teaching',
          'خطّةُ المواد وتخصّصُ المعلّم · وأخفُّ أيّام الفصل حملًا' ||
          case pr.mode when 'joined' then ' · ومتّصلةٌ بطلب مدرستك'
                       when 'split'  then ' · ومنفصلةٌ مرّةً في اليوم'
                       else '' end);
        if v_teacher is null then v_teacher := v_pick; end if;
        placed := placed + 1;
        need := need - 1;
      end loop;
    end loop;
  end loop;

  -- ③  الاحتياطُ بالعدد الذي تطلبه المدرسة — لا بكلّ فراغ
  for v_d in 0..4 loop
    for v_p in 1..maxp loop
      v_need := v2.standby_need_of(p_school, v_d::smallint, v_p::smallint);
      if v_need > 0 then
        insert into v2.timetable_draft_slots(draft_id,weekday,period_no,person_id,slot_kind,why_ar)
        select did, v_d, v_p, c.pid, 'standby',
               'احتياطٌ بعدد مدرستك · الأقلُّ نصيبًا من الانتظار (س-٨-ا-١ سياسة ٠١)'
        from (
          select pe.id pid,
            (select count(*) from v2.timetable_draft_slots s1
              where s1.draft_id=did and s1.person_id=pe.id and s1.slot_kind='standby')::int sb,
            (select count(*) from v2.timetable_draft_slots s2
              where s2.draft_id=did and s2.person_id=pe.id and s2.slot_kind='teaching')::int tc,
            pe.full_name
          from v2.people pe
          join v2.assignments a on a.person_id=pe.id and a.school_id=p_school and a.ended_on is null
          where pe.status='active'
            and a.post_key in ('subject_teacher','sped_teacher','gifted_teacher')
            and not exists (select 1 from v2.timetable_draft_slots x
                             where x.draft_id=did and x.weekday=v_d and x.period_no=v_p
                               and x.person_id=pe.id)
            and (select count(*) from v2.timetable_draft_slots s3
                  where s3.draft_id=did and s3.person_id=pe.id and s3.slot_kind='standby')
                < v2.standby_cap(p_school, pe.id)
        ) c
        order by c.sb asc, c.tc asc, c.full_name
        limit v_need;

        select count(*) into v_taken from v2.timetable_draft_slots
         where draft_id=did and weekday=v_d and period_no=v_p and slot_kind='standby';
        if v_taken < v_need then
          gaps := gaps || jsonb_build_object('grade',null,'subject','الاحتياط',
            'section','الحصّة '||v2.ar_num(v_p),
            'why','طلبت مدرستك '||v2.ar_count(v_need,'معلّم','معلّمين','معلّمين','معلّمًا')||
                  ' ولم يتهيّأ إلّا '||v2.ar_num(v_taken)||' — فالباقون مشغولون أو بلغوا سقفَهم');
        end if;
      end if;
    end loop;
  end loop;
  select count(*) into standby from v2.timetable_draft_slots
   where draft_id=did and slot_kind='standby';

  update v2.timetable_drafts set stats = jsonb_build_object(
      'placed',placed,'unplaced',unplaced,'standby',standby,'split_warn',split_warn,
      'placed_ar',v2.ar_num(placed),'standby_ar',v2.ar_num(standby),'gaps',gaps)
   where id=did;
  return jsonb_build_object('ok',true,'draft',did,
    'placed',placed,'unplaced',unplaced,'standby',standby,'split_warn',split_warn,'gaps',gaps,
    'note','هذا مقترحٌ يُعرض ولا يُثبَّت — راجعه ثمّ أقرّه أو ألغِه');
end $function$
;
