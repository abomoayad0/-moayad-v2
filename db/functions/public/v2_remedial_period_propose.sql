-- public.v2_remedial_period_propose(p_plan uuid, p_weekday smallint, p_period smallint, p_section uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4489384bacb4f830196f69733ffc4f1c
CREATE OR REPLACE FUNCTION public.v2_remedial_period_propose(p_plan uuid, p_weekday smallint, p_period smallint, p_section uuid DEFAULT NULL::uuid, p_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare p record; me uuid := v2.current_person(); v_id uuid;
        v_t int; v_s int; v_last int; v_from_sb boolean; v_allow_last int; n int; v_sb uuid;
begin
  select * into p from v2.remedial_plans where id=p_plan and voided_at is null;
  if p.id is null then raise exception 'لا خطّةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(p.school_id,'اقتراحَ حصّةٍ علاجيّة');
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
    'deputy_academic','deputy','principal'],'اقتراحَ حصّةٍ علاجيّة');
  if p.state in ('approved','running','evaluated') then
    raise exception 'الخطّةُ اعتُمدت — ولا تُقترح لها حصّةٌ جديدةٌ بعد الاعتماد'; end if;

  if not exists (select 1 from v2.period_slots ps where ps.school_id=p.school_id and ps.period_no=p_period) then
    raise exception 'الحصّةُ % غير معرَّفةٍ في يوم مدرستك', v2.ar_num(p_period); end if;
  if p_weekday not between 0 and 4 then raise exception 'اليومُ من الأحد إلى الخميس'; end if;

  v_allow_last := v2.rule_n(p.school_id,'remedial_allow_last_period');
  select max(ps.period_no) into v_last from v2.period_slots ps where ps.school_id=p.school_id;
  if v_allow_last = 0 and p_period = v_last then
    raise exception 'لا تُسمح الحصّةُ العلاجيّةُ في آخر حصّةٍ (%) — وهو رقمٌ في لوحة التحكّم', v2.ar_num(v_last); end if;

  v_t := v2.rule_n(p.school_id,'remedial_max_per_teacher_week');
  select count(*) into n from v2.remedial_periods r
    join v2.remedial_plans pl on pl.id=r.plan_id and pl.voided_at is null
   where r.school_id=p.school_id and r.person_id=me and r.state <> 'cancelled'
     and pl.term_no = p.term_no;
  if n >= v_t then
    raise exception 'بلغتَ سقفَك الأسبوعيّ — وأكثرُه % حصصٍ علاجيّةٍ للمعلّم (رقمٌ في لوحة التحكّم)', v2.ar_num(v_t); end if;

  if p_section is not null then
    v_s := v2.rule_n(p.school_id,'remedial_max_per_section_week');
    select count(*) into n from v2.remedial_periods r
      join v2.remedial_plans pl on pl.id=r.plan_id and pl.voided_at is null
     where r.school_id=p.school_id and r.section_id=p_section and r.state <> 'cancelled'
       and pl.term_no = p.term_no;
    if n >= v_s then
      raise exception 'بلغ الفصلُ سقفَه الأسبوعيّ — وأكثرُه % حصصٍ علاجيّةٍ (رقمٌ في لوحة التحكّم)', v2.ar_num(v_s); end if;
  end if;

  -- الخانةُ مشغولةٌ بتدريس؟
  if exists (select 1 from v2.timetable t where t.school_id=p.school_id and t.weekday=p_weekday
              and t.period_no=p_period and t.person_id=me and t.slot_kind in ('teaching','activity')) then
    raise exception 'عندك حصّةُ تدريسٍ في هذا الموضع — فاختر موضعًا آخر'; end if;

  -- تُؤخذ من الانتظار؟
  v_from_sb := v2.rule_n(p.school_id,'remedial_from_standby') = 1;
  if v_from_sb then
    select t.id into v_sb from v2.timetable t where t.school_id=p.school_id and t.weekday=p_weekday
      and t.period_no=p_period and t.person_id=me and t.slot_kind='standby' limit 1;
    if v_sb is null then
      raise exception 'لا خانةَ انتظارٍ لك في هذا الموضع — والمدرسةُ تأخذ الحصّةَ العلاجيّةَ من الانتظار (رقمٌ في لوحة التحكّم)'; end if;
  end if;

  insert into v2.remedial_periods(plan_id,school_id,weekday,period_no,section_id,person_id,
      from_standby,why_ar,proposed_by,is_test)
  values (p_plan,p.school_id,p_weekday,p_period,p_section,me,v_from_sb,
      nullif(btrim(coalesce(p_why,'')),''), me, coalesce(p.is_test,false))
  returning id into v_id;

  return jsonb_build_object('ok',true,'period',v_id,'from_standby',v_from_sb,
    'summary_ar','اقتُرحت حصّةٌ علاجيّةٌ يومَ '||
      (array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'])[p_weekday+1]
      ||' الحصّةَ '||v2.ar_num(p_period),
    'note_ar','ولا تدخل الجدولَ حتى يعتمدها الوكيلُ للشؤون التعليميّة — '||v2.cite_of('remedial.approve')
      ||case when v_from_sb then ' · وتُؤخذ من خانة انتظارك فلا يزيد نصابُك'
             else ' · وتُزاد خانةً جديدةً فوق نصابك' end);
end $function$
;
