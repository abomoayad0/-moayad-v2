-- public.v2_card_health(p_student uuid, p_private_ack boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 48b99493fce09f8746282a2f2640c837
CREATE OR REPLACE FUNCTION public.v2_card_health(p_student uuid, p_private_ack boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid := v2.current_person(); secs int; v_log int; v_per smallint;
        n_cases int; has_counselor boolean; v_sees int;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc,'الاطّلاعَ على حال الطالب الصحّيّة');

  secs   := v2.rule_n(sc,'card_health_seconds');
  v_log  := v2.rule_n(sc,'card_health_log');
  v_sees := v2.rule_n(sc,'health_teacher_sees');

  has_counselor := exists (select 1 from v2.assignments a
      where a.school_id=sc and a.post_key='health_counselor' and a.ended_on is null
        and a.started_on <= current_date);

  select count(*) into n_cases from v2.health_cases c
   where c.student_id=p_student and c.ended_at is null
     and (c.until_on is null or c.until_on >= current_date);

  if not coalesce(p_private_ack,false) then
    return jsonb_build_object('open',false,
      'gate_ar','ما يصلك من الموجّه الصحّيّ — محفوظةٌ، تُقرأ على انفراد',
      'ask_ar','أنا في مكانٍ خاصٍّ — أظهِرها',
      'warn_ar','ولا تؤكّد إن كانت شاشتُك موصولةً بالعارض',
      'seconds',secs,
      'note_ar', case when v_log=1 then 'ويُسجَّل اطّلاعُك — ولا تُعرض على شاشة العرض'
                      else 'ولا تُعرض على شاشة العرض' end);
  end if;

  select ((v2.card_window(sc,me,current_date))->>'period_no')::smallint into v_per;

  if v_log = 1 then
    insert into v2.card_views(school_id,student_id,by_person,by_role_ar,kind,
        on_date,period_no,own_device,note_ar,is_test)
    values (sc,p_student,me,v2.role_ar(v2.my_role()),'health',
        current_date,v_per,true,'اطّلاعٌ من بطاقة الطالب — بإقرار الخصوصيّة',
        coalesce((select test_mode from v2.schools where id=sc),false));
  end if;

  return jsonb_build_object('open',true,'seconds',secs,'logged',(v_log=1),
    'count', n_cases,
    'state_ar', case
      when not has_counselor then 'لا موجّهَ صحيًّا مكلَّفًا في المدرسة — فلا حالةَ مسجَّلةٌ لأحد'
      when n_cases = 0 then 'لا حالةَ مسجَّلةٌ له عند الموجّه الصحّيّ'
      else v2.ar_count(n_cases,'حالةٌ واحدةٌ تحتاج انتباهَك','حالتان تحتاجان انتباهَك',
             'حالاتٍ تحتاج انتباهَك','حالةً تحتاج انتباهَك') end,
    -- 👁 إرشادُ التعامل ودرجةُ الانتباه وحدَهما · ولا اسمَ حالةٍ ولا خاصّ
    'cases', case when v_sees <> 1 then '[]'::jsonb else coalesce((
        select jsonb_agg(jsonb_build_object(
            'severity', c.severity,
            'hint_ar', c.teacher_hint_ar,
            'until_ar', case when c.until_on is null then null else v2.fn_to_hijri(c.until_on) end)
          order by c.severity desc, c.from_on)
        from v2.health_cases c
        where c.student_id=p_student and c.ended_at is null
          and (c.until_on is null or c.until_on >= current_date)),'[]'::jsonb) end,
    'hidden_ar','اسمُ الحالةِ وما كتبه الموجّهُ خاصًّا محفوظان — ويصلك إرشادُ التعامل وحدَه',
    'note_ar', case when v_log=1
      then 'وسُجّل اطّلاعُك فعلًا — لا وعدًا · ولا تُظهر هذا أمام الطلّاب'
      else '⚠ مفتاحُ تسجيل الاطّلاع مُطفأٌ في لوحة التحكّم — فلا تُقال للمعلّم عبارةُ «يُسجَّل اطّلاعك»' end,
    'gap_ar', case
      when not has_counselor
        then '⚠ ولا موجّهَ صحيًّا مكلَّفًا — فالكتابةُ في الميدان معطّلةٌ حتى يُكلَّف، وهو في لوحة «خلل»'
      when v_sees <> 1
        then '⚠ ومفتاحُ «يرى المعلّمُ إرشادَ التعامل» مُطفأٌ في لوحة التحكّم — فلا يُعرض شيء'
      else null end,
    'from', jsonb_build_object(
      'why_ar','الصحّةُ ميدانُ الموجّه الصحّيّ بنصّ مصفوفة المسؤوليّات — والبطاقةُ تقرأ ولا تكتب',
      'read', jsonb_build_array('v2_card_health','v2_health_of_student'),
      'write', jsonb_build_array('v2_health_case_save','v2_health_case_end'),
      'cite', v2.cite_of('health.counselor_owns')));
end $function$
;
