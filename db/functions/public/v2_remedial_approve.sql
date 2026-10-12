-- public.v2_remedial_approve(p_plan uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ab621322307b45ca3a0416673d3a0da5
CREATE OR REPLACE FUNCTION public.v2_remedial_approve(p_plan uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare p record; me uuid := v2.current_person(); r record;
        n_conv int := 0; n_new int := 0; yr uuid; v_sub text; v_slot uuid;
begin
  perform v2.assert_role(array['deputy_academic','deputy','principal'],'اعتمادَ خطّةٍ علاجيّة');
  select * into p from v2.remedial_plans where id=p_plan and voided_at is null;
  if p.id is null then raise exception 'لا خطّةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(p.school_id,'اعتمادَ خطّةٍ علاجيّة');
  if p.approved_at is not null then raise exception 'اعتُمدت سلفًا في %', p.approved_at::date; end if;
  if p.kind='group' and p.reviewed_at is null then
    raise exception 'الخطّةُ جماعيّةٌ ولم تراجعها لجنةُ التوجيه الطلابيّ — ونصُّه: %',
      v2.cite_of('remedial.group_review'); end if;
  if not exists (select 1 from v2.remedial_periods rp where rp.plan_id=p_plan and rp.state='proposed') then
    raise exception 'لا حصّةَ مقترحةً في هذي الخطّة — والمعتمَدُ قائمةُ الحصص (%)', v2.cite_of('remedial.outputs'); end if;
  if p.kind='group' and not exists (select 1 from v2.remedial_members m
        where m.plan_id=p_plan and m.removed_at is null) then
    raise exception 'الخطّةُ جماعيّةٌ ولا طالبَ فيها'; end if;

  select e.year_id into yr from v2.enrolments e where e.school_id=p.school_id and e.status='active' limit 1;
  v_sub := 'علاجيّة — '||p.subject_ar;

  for r in select * from v2.remedial_periods where plan_id=p_plan and state='proposed' loop
    v_slot := null;
    -- إن كانت تُؤخذ من الانتظار فخانةُ الانتظار نفسُها تُحوَّل · ولا تُضاف خانةٌ ثانيةٌ فوقها
    if r.from_standby then
      select t.id into v_slot from v2.timetable t
       where t.school_id=p.school_id and t.weekday=r.weekday and t.period_no=r.period_no
         and t.person_id=r.person_id and t.slot_kind='standby' limit 1;
    end if;

    if v_slot is not null then
      update v2.timetable
         set slot_kind='remedial', subject_ar=v_sub,
             note='حصّةٌ علاجيّةٌ معتمدةٌ — حُوّلت من خانة انتظار · خطّةُ «'||p.title_ar||'» · س-٩-ا-٢ ص٢٢٥'
       where id=v_slot;
      n_conv := n_conv + 1;
    else
      -- خانةٌ جديدةٌ بلا فصل: الحصّةُ العلاجيّةُ لمجموعةٍ من الطلّاب لا لفصلٍ كامل
      insert into v2.timetable(school_id,year_id,term_no,weekday,period_no,section_id,
          person_id,subject_ar,slot_kind,note)
      values (p.school_id,yr,p.term_no,r.weekday,r.period_no,null,
          r.person_id,v_sub,'remedial',
          'حصّةٌ علاجيّةٌ معتمدةٌ — زيادةً على النصاب · خطّةُ «'||p.title_ar||'» · س-٩-ا-٢ ص٢٢٥')
      returning id into v_slot;
      n_new := n_new + 1;
    end if;

    update v2.remedial_periods set state='approved', approved_by=me, approved_at=now(), slot_id=v_slot
     where id=r.id;
  end loop;

  update v2.remedial_plans
     set approved_by=me, approved_at=now(),
         approve_note=nullif(btrim(coalesce(p_note,'')),''), state='approved'
   where id=p_plan;

  return jsonb_build_object('ok',true,'plan',p_plan,
    'periods_in_timetable', n_conv + n_new, 'from_standby', n_conv, 'added_over_quota', n_new,
    'summary_ar','اعتُمدت الخطّةُ ودخلت '||v2.ar_count(n_conv+n_new,'حصّةٌ علاجيّةٌ واحدة','حصّتان علاجيّتان',
      'حصصٍ علاجيّةٍ','حصّةً علاجيّةً')||' في الجدول',
    'note_ar','ويراها المعلّمُ في «يومي» بأساسٍ «علاجيّة» — '
      ||case when n_conv>0 then v2.ar_num(n_conv)||' منها حُوّلت من خانات انتظاره فلا يزيد نصابُه' else '' end
      ||case when n_conv>0 and n_new>0 then ' · ' else '' end
      ||case when n_new>0 then v2.ar_num(n_new)||' زيادةً على نصابه' else '' end
      ||' · وهي بلا فصلٍ فلا تظهر في شاشة رصد الحضور · '||v2.cite_of('remedial.approve'));
end $function$
;
