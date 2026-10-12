-- public.v2_card_health(p_student uuid, p_private_ack boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 459c18b5f05c3d5c01e266eea03091c0
CREATE OR REPLACE FUNCTION public.v2_card_health(p_student uuid, p_private_ack boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid := v2.current_person(); secs int; v_log int; v_per smallint;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc,'الاطّلاعَ على حال الطالب الصحّيّة');

  secs  := v2.rule_n(sc,'card_health_seconds');
  v_log := v2.rule_n(sc,'card_health_log');

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
    'state_ar','صحّتُه جيّدة — لا حالةَ مسجَّلة',
    'cases','[]'::jsonb,
    'note_ar', case when v_log=1
      then 'وسُجّل اطّلاعُك فعلًا — لا وعدًا · ولا تُظهر هذا أمام الطلّاب'
      else '⚠ مفتاحُ تسجيل الاطّلاع مُطفأٌ في لوحة التحكّم — فلا تُقال للمعلّم عبارةُ «يُسجَّل اطّلاعك»' end,
    'gap_ar','⚠ ولا مخزنَ صحّيًّا في «مؤيّد» الجديد بعد — فالبطاقةُ تظهر لكلّ الطلّاب بحالها الافتراضيّة '
      ||'منعًا للتمييز، وتُعرض الحالاتُ حين يُبنى ميدانُ الصحّة المدرسيّة');
end $function$
;
